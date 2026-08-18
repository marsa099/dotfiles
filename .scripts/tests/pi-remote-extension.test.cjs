"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawn } = require("node:child_process");
const test = require("node:test");

const { readOrCreateConfig } = require("../../.pi/agent/extensions/pi-remote/server.cjs");

function waitForLine(child, predicate, timeoutMs = 15_000) {
  return new Promise((resolve, reject) => {
    let buffer = "";
    const timeout = setTimeout(() => {
      cleanup();
      reject(new Error(`Timed out waiting for Pi RPC output. stderr:\n${child.stderrText || ""}`));
    }, timeoutMs);

    const onData = (chunk) => {
      buffer += chunk.toString("utf8");
      while (true) {
        const newline = buffer.indexOf("\n");
        if (newline < 0) break;
        let line = buffer.slice(0, newline);
        buffer = buffer.slice(newline + 1);
        if (line.endsWith("\r")) line = line.slice(0, -1);
        if (!line) continue;
        try {
          const payload = JSON.parse(line);
          if (predicate(payload)) {
            cleanup();
            resolve(payload);
            return;
          }
        } catch {
          // Non-protocol output is ignored; RPC diagnostics belong on stderr.
        }
      }
    };

    const onExit = (code) => {
      cleanup();
      reject(new Error(`Pi exited before becoming ready (code ${code}). stderr:\n${child.stderrText || ""}`));
    };

    const cleanup = () => {
      clearTimeout(timeout);
      child.stdout.off("data", onData);
      child.off("exit", onExit);
    };

    child.stdout.on("data", onData);
    child.on("exit", onExit);
  });
}

async function stopChild(child) {
  if (child.exitCode !== null) return;
  child.kill("SIGTERM");
  await Promise.race([
    new Promise((resolve) => child.once("exit", resolve)),
    new Promise((resolve) => setTimeout(resolve, 3000)),
  ]);
  if (child.exitCode === null) child.kill("SIGKILL");
}

test("loads as a real Pi extension and serves the active session", { timeout: 25_000 }, async (t) => {
  const root = path.resolve(__dirname, "../..");
  const piBinary = process.env.PI_TEST_BINARY || path.join(os.homedir(), ".npm-global", "bin", "pi");
  if (!fs.existsSync(piBinary)) {
    t.skip(`Pi binary not found: ${piBinary}`);
    return;
  }

  const stateDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-remote-extension."));
  const env = {
    ...process.env,
    PI_OFFLINE: "1",
    PI_REMOTE_STATE_DIR: stateDir,
    PI_REMOTE_HOST: "127.0.0.1",
    PI_REMOTE_PORT: "0",
  };
  const child = spawn(piBinary, [
    "--mode", "rpc",
    "--no-session",
    "--no-extensions",
    "--extension", path.join(root, ".pi/agent/extensions/pi-remote/index.ts"),
    "--remote",
  ], { cwd: root, env, stdio: ["pipe", "pipe", "pipe"] });
  child.stderrText = "";
  child.stderr.on("data", (chunk) => { child.stderrText += chunk.toString("utf8"); });

  try {
    const notification = await waitForLine(
      child,
      (payload) => payload.type === "extension_ui_request" && payload.method === "notify" && payload.message?.startsWith("Pi Remote: http://"),
    );
    const address = notification.message.match(/Pi Remote: (http:\/\/[^ ]+)/)?.[1];
    assert.ok(address, `Missing server address in ${notification.message}`);

    const page = await fetch(address);
    assert.equal(page.status, 200);
    assert.match(await page.text(), /Open your Pi session/);

    const config = readOrCreateConfig(env, os.homedir());
    const pair = await fetch(`${address}/api/pair`, {
      method: "POST",
      headers: { Authorization: `Bearer ${config.token}` },
    });
    assert.equal(pair.status, 201);
    const pairing = await pair.json();
    const login = await fetch(`${address}/api/pair/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Origin: address },
      body: JSON.stringify({ code: pairing.code }),
    });
    assert.equal(login.status, 204);
    const cookie = login.headers.get("set-cookie").split(";", 1)[0];

    const snapshot = await fetch(`${address}/api/snapshot`, { headers: { Cookie: cookie } });
    assert.equal(snapshot.status, 200);
    const payload = await snapshot.json();
    assert.equal(typeof payload.session.id, "string");
    assert.equal(payload.session.cwd, root);
    assert.equal(payload.entries.some((entry) => entry.message), false);

    const sessions = await fetch(`${address}/api/sessions`, { headers: { Cookie: cookie } });
    assert.equal(sessions.status, 200);
    const discovered = (await sessions.json()).sessions;
    assert.equal(discovered.some((session) => session.id === payload.session.id && session.address === address), true);

    const abort = await fetch(`${address}/api/action`, {
      method: "POST",
      headers: { Cookie: cookie, "Content-Type": "application/json", Origin: address },
      body: JSON.stringify({ type: "abort" }),
    });
    assert.equal(abort.status, 202);
    assert.equal((await abort.json()).accepted, true);
  } finally {
    await stopChild(child);
    fs.rmSync(stateDir, { recursive: true, force: true });
  }
});
