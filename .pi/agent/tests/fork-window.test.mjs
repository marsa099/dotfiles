import assert from "node:assert/strict";
import { test } from "node:test";
import register from "../extensions/fork-window.ts";

function setup({ sessionFile = "/tmp/session with spaces.jsonl", result = { code: 0, stderr: "" }, error } = {}) {
  let command;
  const calls = [];
  const notices = [];
  let idle = false;
  register({
    registerCommand(name, definition) {
      assert.equal(name, "fork-window");
      command = definition.handler;
    },
    getThinkingLevel: () => "high",
    async exec(executable, args, options) {
      assert.equal(idle, true);
      calls.push({ executable, args, options });
      if (error) throw error;
      return result;
    },
  });
  const ctx = {
    cwd: "/tmp/project with spaces",
    model: { provider: "openai", id: "gpt-5.4" },
    waitForIdle: async () => { idle = true; },
    sessionManager: { getSessionFile: () => sessionFile },
    ui: { notify: (message, level) => notices.push({ message, level }) },
  };
  return { run: (name) => command(name, ctx), calls, notices };
}

test("launches a named fork with literal arguments and current model", async () => {
  const harness = setup();
  const name = "Review $(touch /tmp/never-run)";
  await harness.run(name);
  assert.deepEqual(harness.calls[0], {
    executable: "kitty",
    args: ["--detach", "--directory", "/tmp/project with spaces", "pi", "--fork", "/tmp/session with spaces.jsonl", "--name", name, "--provider", "openai", "--model", "gpt-5.4", "--thinking", "high"],
    options: { timeout: 10000 },
  });
  assert.equal(harness.notices[0].level, "info");
});

test("rejects missing names and control characters without spawning", async () => {
  for (const name of ["  ", "bad\nname", "bad\0name"]) {
    const harness = setup();
    await harness.run(name);
    assert.equal(harness.calls.length, 0);
    assert.notEqual(harness.notices[0].level, "info");
  }
});

test("rejects ephemeral sessions", async () => {
  const harness = setup({ sessionFile: null });
  await harness.run("review");
  assert.equal(harness.calls.length, 0);
  assert.equal(harness.notices[0].level, "error");
});

test("reports launch failures, timeouts, and missing executables", async () => {
  for (const options of [
    { result: { code: 1, stderr: "No display" } },
    { result: { code: 0, stderr: "", killed: true } },
    { error: new Error("ENOENT") },
  ]) {
    const harness = setup(options);
    await harness.run("review");
    assert.equal(harness.notices[0].level, "error");
  }
});
