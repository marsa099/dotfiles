"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  DEFAULT_HOST,
  defaultTerminalName,
  parseArguments,
  readConfig,
  resolveTerminalReference,
  runtimeClientId,
  websocketUrl,
  writeConfig,
} = require("../pi-shared");

test("parses default open and passes explicit Pi arguments", () => {
  assert.deepEqual(parseArguments([], "/work/api"), {
    command: "open",
    name: "pi:api",
    piArgs: [],
  });
  assert.deepEqual(parseArguments(["review", "--", "--session", "/tmp/session.jsonl"], "/work/api"), {
    command: "open",
    name: "review",
    piArgs: ["--session", "/tmp/session.jsonl"],
  });
});

test("parses lifecycle commands and rejects unsafe ambiguity", () => {
  assert.deepEqual(parseArguments(["attach", "abc123"]), {
    command: "attach",
    reference: "abc123",
    piArgs: [],
  });
  assert.deepEqual(parseArguments(["configure"]), {
    command: "configure",
    host: DEFAULT_HOST,
    piArgs: [],
  });
  assert.throws(() => parseArguments(["kill"]), /Usage/);
  assert.throws(() => parseArguments(["list", "unexpected"]), /does not accept/);
});

test("resolves terminal IDs and names only when unique", () => {
  const terminals = [
    { id: "aaa111", name: "pi:api" },
    { id: "bbb222", name: "pi:web" },
  ];
  assert.equal(resolveTerminalReference("aaa", terminals)?.id, "aaa111");
  assert.equal(resolveTerminalReference("PI:WEB", terminals)?.id, "bbb222");
  assert.equal(resolveTerminalReference("missing", terminals), null);
  assert.throws(
    () => resolveTerminalReference("pi:", terminals),
    /ambiguous/,
  );
});

test("builds direct and TLS WebSocket URLs", () => {
  assert.equal(websocketUrl("100.121.105.35:6767"), "ws://100.121.105.35:6767/ws");
  assert.equal(websocketUrl("tcp://host.example:6767?ssl=true"), "wss://host.example:6767/ws");
  assert.equal(websocketUrl("wss://host.example/old?secret=yes"), "wss://host.example/ws");
  assert.throws(() => websocketUrl("not-a-host"), /Invalid/);
});

test("writes private config atomically and honors environment overrides", () => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), "pi-shared-test."));
  const env = { XDG_DATA_HOME: path.join(home, "data") };
  try {
    const file = writeConfig({ host: DEFAULT_HOST, password: "secret", clientId: "client-1" }, env, home);
    assert.equal(fs.statSync(file).mode & 0o777, 0o600);
    assert.equal(fs.statSync(path.dirname(file)).mode & 0o777, 0o700);
    assert.deepEqual(readConfig(env, home), {
      host: DEFAULT_HOST,
      password: "secret",
      clientId: "client-1",
      file,
    });
    assert.equal(readConfig({ ...env, PASEO_HOST: "localhost:9999", PASEO_PASSWORD: "override" }, home).host, "localhost:9999");
    fs.chmodSync(file, 0o644);
    assert.throws(() => readConfig(env, home), /must not be accessible/);
  } finally {
    fs.rmSync(home, { recursive: true, force: true });
  }
});

test("uses a stable cwd name and a unique client identity per process", () => {
  assert.equal(defaultTerminalName("/home/martin/repos/example"), "pi:example");
  assert.equal(runtimeClientId("base", 123, "abcd"), "base-123-abcd");
  assert.notEqual(runtimeClientId("base"), runtimeClientId("base"));
});
