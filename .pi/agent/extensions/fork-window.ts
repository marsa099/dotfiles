import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("fork-window", {
    description: "Fork this conversation into a new Kitty window: /fork-window <name>",
    handler: async (args, ctx) => {
      const name = args.trim();
      if (!name) {
        ctx.ui.notify("Usage: /fork-window <name> (spaces are allowed)", "warning");
        return;
      }
      if (/[\x00-\x1f\x7f]/.test(name)) {
        ctx.ui.notify("Fork name must not contain control characters.", "error");
        return;
      }

      await ctx.waitForIdle();
      const sessionFile = ctx.sessionManager.getSessionFile();
      if (!sessionFile) {
        ctx.ui.notify("Cannot fork an unsaved session. Start a saved session first.", "error");
        return;
      }

      // Argument arrays keep names and paths literal: no shell interpolation.
      const launchArgs = [
        "--detach", "--directory", ctx.cwd,
        "pi", "--fork", sessionFile, "--name", name,
      ];
      if (ctx.model) {
        launchArgs.push("--provider", ctx.model.provider, "--model", ctx.model.id);
      }
      launchArgs.push("--thinking", pi.getThinkingLevel());

      try {
        const result = await pi.exec("kitty", launchArgs, { timeout: 10000 });
        if (result.code !== 0 || result.killed) {
          ctx.ui.notify(
            `Kitty launch failed: ${result.stderr.trim() || "check that Kitty is installed and a graphical display is available"}`,
            "error",
          );
          return;
        }
        ctx.ui.notify(`Launched fork “${name}” in a new Kitty window. This session is unchanged.`, "info");
      } catch (error) {
        ctx.ui.notify(`Kitty launch failed: ${error instanceof Error ? error.message : String(error)}`, "error");
      }
    },
  });
}
