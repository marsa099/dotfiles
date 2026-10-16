import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// pane run accepts shell text, so quote every argument (including embedded quotes).
function shellQuote(value: string): string {
  return "'" + value.replaceAll("'", "'\"'\"'") + "'";
}

export default function (pi: ExtensionAPI) {
  async function herdr(args: string[]) {
    const result = await pi.exec("herdr", args, { timeout: 30000 });
    if (result.code !== 0 || result.killed) {
      throw new Error(result.stderr.trim() || result.stdout.trim() || "Herdr command failed or timed out.");
    }
    // Successful pane run and focus mutations may have no response body.
    if (!result.stdout.trim()) return undefined;
    const response = JSON.parse(result.stdout);
    if (response.error) throw new Error(JSON.stringify(response.error));
    return response.result;
  }

  pi.registerCommand("fork-herdr-window", {
    description: "Fork this conversation into a new tab in this Herdr session: /fork-herdr-window <name>",
    handler: async (args, ctx) => {
      const name = args.trim();
      if (!name) {
        ctx.ui.notify("Usage: /fork-herdr-window <name> (spaces are allowed)", "warning");
        return;
      }
      if (/[\x00-\x1f\x7f]/.test(name)) {
        ctx.ui.notify("Fork name must not contain control characters.", "error");
        return;
      }
      if (process.env.HERDR_ENV !== "1") {
        ctx.ui.notify("Run /fork-herdr-window inside Herdr.", "error");
        return;
      }

      let createdTab: string | undefined;
      let started = false;
      try {
        await ctx.waitForIdle();
        const sessionFile = ctx.sessionManager.getSessionFile();
        if (!sessionFile) {
          ctx.ui.notify("Cannot fork an unsaved session. Start a saved session first.", "error");
          return;
        }

        // --current resolves inherited caller context, not another client's focused pane.
        const source = await herdr(["pane", "current", "--current"]);
        const workspace = source?.pane?.workspace_id;
        if (typeof workspace !== "string" || !workspace) {
          throw new Error("The current Herdr workspace is unavailable; nothing created.");
        }
        const launchArgs = ["pi", "--fork", sessionFile, "--name", name];
        if (ctx.model) {
          launchArgs.push("--provider", ctx.model.provider, "--model", ctx.model.id);
        }
        launchArgs.push("--thinking", pi.getThinkingLevel());

        const created = await herdr([
          "tab", "create", "--workspace", workspace,
          "--cwd", ctx.cwd, "--label", name, "--no-focus",
        ]);
        const tabId = created?.tab?.tab_id;
        const paneId = created?.root_pane?.pane_id;
        if (typeof tabId === "string" && tabId) createdTab = tabId;
        if (!createdTab || typeof paneId !== "string" || !paneId) {
          throw new Error("Herdr did not return the new tab and pane IDs. Inspect the tab list before retrying.");
        }
        // Only send commands to the newly returned pane, never the original pane.
        await herdr(["pane", "run", paneId, launchArgs.map(shellQuote).join(" ")]);
        started = true;
        await herdr(["tab", "focus", createdTab]);
        ctx.ui.notify(`Launched fork “${name}” in a new Herdr tab. This Pi session is unchanged.`, "info");
      } catch (error) {
        const state = createdTab
          ? `Tab ${createdTab} was created${started ? " and the fork command was sent, but focusing failed" : ", but launching the fork failed"}. `
          : "";
        ctx.ui.notify(`Herdr fork failed: ${state}${error instanceof Error ? error.message : String(error)}`, "error");
      }
    },
  });
}
