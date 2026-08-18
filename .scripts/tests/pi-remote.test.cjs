"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  PiRemoteServer,
  readOrCreateConfig,
  readSessionRegistrations,
  registryDirectory,
  removeSessionRegistration,
  writeSessionRegistration,
} = require("../../.pi/agent/extensions/pi-remote/server.cjs");

test("creates a stable private token and rejects loose permissions", () => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), "pi-remote-config."));
  const env = {
    PI_REMOTE_STATE_DIR: path.join(home, "state"),
    PI_REMOTE_HOST: "127.0.0.1",
    PI_REMOTE_PORT: "0",
  };
  try {
    const first = readOrCreateConfig(env, home);
    const second = readOrCreateConfig(env, home);
    assert.match(first.token, /^[a-f0-9]{64}$/);
    assert.equal(second.token, first.token);
    assert.equal(fs.statSync(first.file).mode & 0o777, 0o600);
    assert.equal(fs.statSync(path.dirname(first.file)).mode & 0o777, 0o700);

    fs.chmodSync(first.file, 0o644);
    assert.throws(() => readOrCreateConfig(env, home), /must not be accessible/);
  } finally {
    fs.rmSync(home, { recursive: true, force: true });
  }
});

test("registers live sessions and removes stale registry entries", () => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), "pi-remote-registry."));
  const env = { PI_REMOTE_STATE_DIR: path.join(home, "state") };
  try {
    writeSessionRegistration({ id: "session-b", name: "Web", cwd: "/work/web", address: "http://127.0.0.1:6768", pid: 200 }, env, home, 10_000);
    writeSessionRegistration({ id: "session-a", name: "API", cwd: "/work/api", address: "http://127.0.0.1:6767", pid: 100 }, env, home, 50_000);
    const sessions = readSessionRegistrations(env, home, 60_000, (pid) => pid === 100);
    assert.deepEqual(sessions.map((session) => session.id), ["session-a"]);
    assert.equal(fs.statSync(registryDirectory(env, home)).mode & 0o777, 0o700);
    removeSessionRegistration("session-a", env, home);
    assert.deepEqual(readSessionRegistrations(env, home, 60_000, () => true), []);
  } finally {
    fs.rmSync(home, { recursive: true, force: true });
  }
});

test("serves authenticated snapshots, actions, static assets, session discovery, and semantic events", async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pi-remote-web."));
  fs.writeFileSync(path.join(root, "index.html"), "<!doctype html><title>Pi Remote</title>");
  const actions = [];
  const server = new PiRemoteServer({
    host: "127.0.0.1",
    port: 0,
    token: "a".repeat(64),
    webRoot: root,
    getSnapshot: () => ({ session: { id: "session-1" }, state: { isIdle: true }, entries: [] }),
    getSessions: () => [{ id: "session-1", name: "Current", address: "http://127.0.0.1:6767" }],
    onAction: async (action) => {
      actions.push(action);
      return { accepted: true };
    },
  });

  try {
    const address = await server.start();

    const page = await fetch(address);
    assert.equal(page.status, 200);
    assert.match(await page.text(), /Pi Remote/);
    assert.match(page.headers.get("content-security-policy"), /default-src 'self'/);

    const denied = await fetch(`${address}/api/snapshot`);
    assert.equal(denied.status, 401);

    const deniedPair = await fetch(`${address}/api/pair`, { method: "POST" });
    assert.equal(deniedPair.status, 401);

    const pair = await fetch(`${address}/api/pair`, {
      method: "POST",
      headers: { Authorization: `Bearer ${"a".repeat(64)}` },
    });
    assert.equal(pair.status, 201);
    const pairing = await pair.json();
    assert.match(pairing.code, /^[A-Za-z0-9_-]{24}$/);
    assert.ok(pairing.expiresAt > Date.now());

    const pairLogin = await fetch(`${address}/api/pair/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Origin: address },
      body: JSON.stringify({ code: pairing.code }),
    });
    assert.equal(pairLogin.status, 204);
    const pairCookie = pairLogin.headers.get("set-cookie").split(";", 1)[0];
    const pairedSnapshot = await fetch(`${address}/api/snapshot`, { headers: { Cookie: pairCookie } });
    assert.equal(pairedSnapshot.status, 200);

    const reusedPair = await fetch(`${address}/api/pair/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Origin: address },
      body: JSON.stringify({ code: pairing.code }),
    });
    assert.equal(reusedPair.status, 401);

    const badLogin = await fetch(`${address}/api/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Origin: address },
      body: JSON.stringify({ token: "wrong" }),
    });
    assert.equal(badLogin.status, 401);

    const login = await fetch(`${address}/api/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Origin: address },
      body: JSON.stringify({ token: "a".repeat(64) }),
    });
    assert.equal(login.status, 204);
    const cookie = login.headers.get("set-cookie").split(";", 1)[0];

    const snapshot = await fetch(`${address}/api/snapshot`, { headers: { Cookie: cookie } });
    assert.equal(snapshot.status, 200);
    assert.equal((await snapshot.json()).session.id, "session-1");

    const sessions = await fetch(`${address}/api/sessions`, { headers: { Cookie: cookie } });
    assert.equal(sessions.status, 200);
    assert.equal((await sessions.json()).sessions[0].name, "Current");

    const crossOrigin = await fetch(`${address}/api/action`, {
      method: "POST",
      headers: { Cookie: cookie, "Content-Type": "application/json", Origin: "http://attacker.invalid" },
      body: JSON.stringify({ type: "abort" }),
    });
    assert.equal(crossOrigin.status, 403);

    const action = await fetch(`${address}/api/action`, {
      method: "POST",
      headers: { Cookie: cookie, "Content-Type": "application/json", Origin: address },
      body: JSON.stringify({ type: "prompt", text: "hello" }),
    });
    assert.equal(action.status, 202);
    assert.deepEqual(actions, [{ type: "prompt", text: "hello" }]);

    const controller = new AbortController();
    const events = await fetch(`${address}/events`, {
      headers: { Cookie: cookie },
      signal: controller.signal,
    });
    assert.equal(events.status, 200);
    const reader = events.body.getReader();
    const firstEvent = new TextDecoder().decode((await reader.read()).value);
    assert.match(firstEvent, /"type":"snapshot"/);
    assert.match(firstEvent, /"session-1"/);
    controller.abort();
  } finally {
    await server.close();
    fs.rmSync(root, { recursive: true, force: true });
  }
});
