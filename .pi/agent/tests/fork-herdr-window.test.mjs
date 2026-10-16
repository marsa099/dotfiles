import assert from "node:assert/strict";
import { afterEach, beforeEach, test } from "node:test";
import { execFileSync } from "node:child_process";
import register from "../extensions/fork-herdr-window.ts";

let previousEnvironment;
beforeEach(() => {
  previousEnvironment = process.env.HERDR_ENV;
  process.env.HERDR_ENV = "1";
});
afterEach(() => {
  if (previousEnvironment === undefined) delete process.env.HERDR_ENV;
  else process.env.HERDR_ENV = previousEnvironment;
});

function setup({ sessionFile = "/tmp/session 'with spaces.jsonl", model = { provider: "openai", id: "test-model" }, responses = {} } = {}) {
  let handler;
  let idle = false;
  const calls = [];
  const notices = [];
  const defaults = [
    { pane: { workspace_id: "caller-workspace" } },
    { tab: { tab_id: "new-tab" }, root_pane: { pane_id: "new-pane" } },
    undefined,
    undefined,
  ];
  register({
    registerCommand(name, definition) {
      assert.equal(name, "fork-herdr-window");
      handler = definition.handler;
    },
    getThinkingLevel: () => "high",
    async exec(executable, args, options) {
      assert.equal(idle, true);
      const index = calls.length;
      calls.push({ executable, args, options });
      if (responses[index] instanceof Error) throw responses[index];
      return responses[index] ?? {
        code: 0, stderr: "", stdout: defaults[index] ? JSON.stringify({ result: defaults[index] }) : "",
      };
    },
  });
  const ctx = {
    cwd: "/tmp/project with spaces",
    model,
    waitForIdle: async () => { idle = true; },
    sessionManager: { getSessionFile: () => sessionFile },
    ui: { notify: (message, level) => notices.push({ message, level }) },
  };
  return { run: (name = "review") => handler(name, ctx), calls, notices };
}

test("creates a named tab in the caller's workspace and runs only in its returned pane", async () => {
  const harness = setup();
  const name = "Review 'quotes' $(false); $HOME `false`";
  await harness.run(name);
  assert.deepEqual(harness.calls.map((call) => call.args.slice(0, 3)), [
    ["pane", "current", "--current"],
    ["tab", "create", "--workspace"],
    ["pane", "run", "new-pane"],
    ["tab", "focus", "new-tab"],
  ]);
  assert.deepEqual(harness.calls[1].args, [
    "tab", "create", "--workspace", "caller-workspace", "--cwd", "/tmp/project with spaces",
    "--label", name, "--no-focus",
  ]);
  for (const call of harness.calls) {
    assert.equal(call.executable, "herdr");
    assert.deepEqual(call.options, { timeout: 30000 });
  }
  // Parse shell words without executing the generated command or its arguments.
  const words = JSON.parse(execFileSync("python3", ["-c",
    "import json, shlex, sys\nprint(json.dumps(shlex.split(sys.argv[1])))",
    harness.calls[2].args[3],
  ], { encoding: "utf8" }));
  assert.deepEqual(words, [
    "pi", "--fork", "/tmp/session 'with spaces.jsonl", "--name", name,
    "--provider", "openai", "--model", "test-model", "--thinking", "high",
  ]);
  assert.equal(harness.notices[0].level, "info");
});

test("supports sessions with no selected model", async () => {
  const harness = setup({ model: null });
  await harness.run();
  assert.doesNotMatch(harness.calls[2].args[3], /--provider|--model/);
  assert.equal(harness.notices[0].level, "info");
});

test("rejects missing names and control characters before calling Herdr", async () => {
  for (const name of ["  ", "bad\nname", "bad\0name", "bad\x7fname"]) {
    const harness = setup();
    await harness.run(name);
    assert.equal(harness.calls.length, 0);
    assert.notEqual(harness.notices[0].level, "info");
  }
});

test("refuses to control Herdr outside a Herdr session", async () => {
  delete process.env.HERDR_ENV;
  const harness = setup();
  await harness.run();
  assert.equal(harness.calls.length, 0);
  assert.match(harness.notices[0].message, /inside Herdr/);
});

test("rejects unsaved Pi sessions", async () => {
  const harness = setup({ sessionFile: null });
  await harness.run();
  assert.equal(harness.calls.length, 0);
  assert.match(harness.notices[0].message, /unsaved session/);
});

test("stops on CLI failures, timeouts, invalid JSON, and API errors", async () => {
  for (const response of [
    { code: 1, stderr: "Unavailable", stdout: "" },
    { code: 0, killed: true, stderr: "", stdout: "" },
    { code: 0, stderr: "", stdout: "not JSON" },
    { code: 0, stderr: "", stdout: JSON.stringify({ error: { message: "Denied" } }) },
    new Error("ENOENT"),
    { code: 0, stderr: "", stdout: JSON.stringify({ result: { pane: {} } }) },
  ]) {
    const harness = setup({ responses: { 0: response } });
    await harness.run();
    assert.equal(harness.calls.length, 1);
    assert.equal(harness.notices[0].level, "error");
  }
});

test("does not run or focus anything when creation returns missing IDs", async () => {
  const harness = setup({ responses: { 1: { code: 0, stderr: "", stdout: '{"result":{}}' } } });
  await harness.run();
  assert.equal(harness.calls.length, 2);
  assert.match(harness.notices[0].message, /Inspect the tab list/);
});

test("reports the created tab and does not focus it when launch fails", async () => {
  const harness = setup({ responses: { 2: new Error("Launch refused") } });
  await harness.run();
  assert.equal(harness.calls.length, 3);
  assert.match(harness.notices[0].message, /Tab new-tab was created.*launching the fork failed/);
});

test("distinguishes a focus failure after the fork command was sent", async () => {
  const harness = setup({ responses: { 3: new Error("Focus refused") } });
  await harness.run();
  assert.equal(harness.calls.length, 4);
  assert.match(harness.notices[0].message, /fork command was sent, but focusing failed/);
  assert.equal(harness.notices[0].level, "error");
});
