"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  PiRemoteServer,
  readOrCreateConfig,
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

test("serves authenticated snapshots, actions, static assets, and semantic events", async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pi-remote-web."));
  fs.writeFileSync(path.join(root, "index.html"), "<!doctype html><title>Pi Remote</title>");
  const actions = [];
  const server = new PiRemoteServer({
    host: "127.0.0.1",
    port: 0,
    token: "a".repeat(64),
    webRoot: root,
    getSnapshot: () => ({ session: { id: "session-1" }, state: { isIdle: true }, entries: [] }),
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
