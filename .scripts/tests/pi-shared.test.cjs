"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  SESSION_PREFIX,
  defaultSessionName,
  loadRemoteConfig,
  parseArguments,
  resolveSession,
  tmuxSessionName,
} = require("../pi-shared");

test("parses open, lifecycle, URL, and token commands", () => {
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
  assert.deepEqual(parseArguments(["token"]), { command: "token", piArgs: [] });
  assert.deepEqual(parseArguments(["url"]), { command: "url", piArgs: [] });
  assert.throws(() => parseArguments(["kill"]), /Usage/);
  assert.throws(() => parseArguments(["list", "unexpected"]), /does not accept/);
});

test("creates stable, tmux-safe names", () => {
  assert.equal(defaultSessionName("/home/martin/repos/example"), "example");
  assert.equal(tmuxSessionName("API review"), `${SESSION_PREFIX}API-review`);
  assert.equal(tmuxSessionName("a:b/c"), `${SESSION_PREFIX}a-b-c`);
  assert.throws(() => tmuxSessionName("!!!"), /letter or number/);
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
