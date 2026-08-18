"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  SESSION_PREFIX,
  activeSessionPids,
  allocatePort,
  configForSession,
  defaultSessionName,
  loadRemoteConfig,
  pairingUrl,
  parseArguments,
  remoteUrl,
  renderQr,
  requestPairingCode,
  resolveMigrationSession,
  resolveSession,
  tmuxSessionName,
} = require("../pi-shared");

test("parses open, lifecycle, QR, URL, and token commands", () => {
  assert.deepEqual(parseArguments([], "/work/api"), {
    command: "open",
    name: "api",
    piArgs: [],
  });
  assert.deepEqual(parseArguments(["review", "--", "--session", "/tmp/session.jsonl"], "/work/api"), {
    command: "open",
    name: "review",
    piArgs: ["--session", "/tmp/session.jsonl"],
  });
  assert.deepEqual(parseArguments(["attach", "review"]), {
    command: "attach",
    reference: "review",
    piArgs: [],
  });
  assert.deepEqual(parseArguments(["migrate"]), { command: "migrate", reference: null, piArgs: [] });
  assert.deepEqual(parseArguments(["migrate", "01abc"]), { command: "migrate", reference: "01abc", piArgs: [] });
  assert.deepEqual(parseArguments(["qr"]), { command: "qr", reference: null, piArgs: [] });
  assert.deepEqual(parseArguments(["qr", "review"]), { command: "qr", reference: "review", piArgs: [] });
  assert.deepEqual(parseArguments(["token"]), { command: "token", piArgs: [] });
  assert.deepEqual(parseArguments(["url"]), { command: "url", reference: null, piArgs: [] });
  assert.throws(() => parseArguments(["kill"]), /Usage/);
  assert.throws(() => parseArguments(["list", "unexpected"]), /does not accept/);
});

test("creates stable, tmux-safe names", () => {
  assert.equal(defaultSessionName("/home/martin/repos/example"), "example");
  assert.equal(tmuxSessionName("API review"), `${SESSION_PREFIX}API-review`);
  assert.equal(tmuxSessionName("a:b/c"), `${SESSION_PREFIX}a-b-c`);
  assert.throws(() => tmuxSessionName("!!!"), /letter or number/);
});

test("allocates distinct ports and targets session URLs", () => {
  const config = { host: "100.64.0.8", port: 6767, token: "a".repeat(64) };
  const sessions = [
    { tmuxName: `${SESSION_PREFIX}api`, name: "api", cwd: "/work/api", port: 6767 },
    { tmuxName: `${SESSION_PREFIX}web`, name: "web", cwd: "/work/web", port: 6769 },
  ];
  assert.equal(allocatePort(sessions, config.port), 6768);
  assert.equal(configForSession(config, sessions, "web").port, 6769);
  assert.equal(configForSession(config, sessions, null).port, 6767);
  assert.throws(() => configForSession(config, sessions, "missing"), /not found/);
});

test("creates a one-time pairing URL without exposing the persistent token", async () => {
  const config = { host: "100.64.0.8", port: 6767, token: "a".repeat(64) };
  const requests = [];
  const pairing = await requestPairingCode(config, async (url, options) => {
    requests.push({ url, options });
    return { ok: true, json: async () => ({ code: "one-time-code", expiresAt: Date.now() + 120_000 }) };
  });
  assert.equal(remoteUrl(config), "http://100.64.0.8:6767");
  assert.equal(pairingUrl(config, pairing.code), "http://100.64.0.8:6767/#pair=one-time-code");
  assert.equal(requests[0].url.includes(config.token), false);
  assert.equal(requests[0].options.headers.Authorization, `Bearer ${config.token}`);
  assert.equal(pairingUrl(config, pairing.code).includes(config.token), false);
});

test("falls back to nix when qrencode is not installed", () => {
  const calls = [];
  renderQr("http://example/#pair=code", {}, (command, args) => {
    calls.push({ command, args });
    if (command === "qrencode") {
      const error = new Error("not found");
      error.code = "ENOENT";
      return { error };
    }
    return { status: 0 };
  });
  assert.equal(calls[0].command, "qrencode");
  assert.deepEqual(calls[1].args.slice(0, 4), ["run", "nixpkgs#qrencode", "--", "-t"]);
});

test("discovers the newest legacy session and refuses active session files", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pi-shared-migrate."));
  const sessions = path.join(root, "sessions", "project");
  const proc = path.join(root, "proc");
  fs.mkdirSync(sessions, { recursive: true });
  fs.mkdirSync(proc, { recursive: true });
  const older = path.join(sessions, "2026-01-01_old-session.jsonl");
  const newest = path.join(sessions, "2026-01-02_new-session.jsonl");
  fs.writeFileSync(older, `${JSON.stringify({ type: "session", id: "old-session", cwd: "/work/old" })}\n`);
  fs.writeFileSync(newest, [
    JSON.stringify({ type: "session", id: "new-session", cwd: "/work/new" }),
    JSON.stringify({ type: "session_info", name: "Legacy review" }),
    "",
  ].join("\n"));
  fs.utimesSync(older, new Date(1000), new Date(1000));
  fs.utimesSync(newest, new Date(2000), new Date(2000));

  const processDirectory = path.join(proc, "4242");
  fs.mkdirSync(processDirectory);
  fs.writeFileSync(path.join(processDirectory, "environ"), `HOME=/tmp\0PI_SESSION_FILE=${newest}\0`);
  fs.writeFileSync(path.join(processDirectory, "cmdline"), `pi\0--session\0${newest}\0`);

  try {
    const env = { PI_SHARED_SESSION_ROOT: path.join(root, "sessions") };
    const selected = resolveMigrationSession(null, env, root);
    assert.equal(selected.file, newest);
    assert.equal(selected.name, "Legacy review");
    assert.equal(resolveMigrationSession("old-session", env, root).file, older);
    assert.deepEqual(activeSessionPids(newest, proc), [4242]);
    assert.deepEqual(activeSessionPids(older, proc), []);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("resolves only unique remote session references", () => {
  const sessions = [
    { tmuxName: `${SESSION_PREFIX}api`, name: "api", cwd: "/work/api" },
    { tmuxName: `${SESSION_PREFIX}web`, name: "web", cwd: "/work/web" },
  ];
  assert.equal(resolveSession("api", sessions)?.cwd, "/work/api");
  assert.equal(resolveSession("remote-web", sessions)?.name, "web");
  assert.equal(resolveSession("missing", sessions), null);
  assert.throws(() => resolveSession("pi-remote", sessions), /ambiguous/);
});

test("loads the private extension config through an override module", () => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), "pi-shared-test."));
  const modulePath = path.join(__dirname, "../../.pi/agent/extensions/pi-remote/server.cjs");
  const env = {
    PI_REMOTE_SERVER_MODULE: modulePath,
    PI_REMOTE_STATE_DIR: path.join(home, "state"),
    PI_REMOTE_HOST: "127.0.0.1",
    PI_REMOTE_PORT: "7777",
  };
  try {
    const first = loadRemoteConfig(env, home);
    const second = loadRemoteConfig(env, home);
    assert.equal(first.host, "127.0.0.1");
    assert.equal(first.port, 7777);
    assert.match(first.token, /^[a-f0-9]{64}$/);
    assert.equal(second.token, first.token);
    assert.equal(fs.statSync(first.file).mode & 0o777, 0o600);
  } finally {
    fs.rmSync(home, { recursive: true, force: true });
  }
});
