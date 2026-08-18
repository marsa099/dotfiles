import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const require = createRequire(import.meta.url);
const { PiRemoteServer, readOrCreateConfig } = require("./server.cjs") as {
  PiRemoteServer: new (options: Record<string, unknown>) => {
    start(): Promise<string>;
    close(): Promise<void>;
    address(): string;
    broadcast(payload: unknown): void;
  };
  readOrCreateConfig(): { host: string; port: number; token: string; file: string };
};

const extensionDirectory = dirname(fileURLToPath(import.meta.url));
const MAX_TEXT_LENGTH = 200_000;
const MAX_PROMPT_LENGTH = 50_000;

function boundedText(value: unknown): string {
  const text = typeof value === "string" ? value : String(value ?? "");
  return text.length <= MAX_TEXT_LENGTH ? text : `${text.slice(0, MAX_TEXT_LENGTH)}\n… output truncated for remote display`;
}

function safeValue(value: unknown, depth = 0): unknown {
  if (value === null || typeof value === "boolean" || typeof value === "number") return value;
  if (typeof value === "string") return boundedText(value);
  if (typeof value === "bigint") return String(value);
  if (depth >= 6) return "[nested value omitted]";
  if (Array.isArray(value)) return value.slice(0, 200).map((item) => safeValue(item, depth + 1));
  if (typeof value === "object") {
    const output: Record<string, unknown> = {};
    for (const [key, item] of Object.entries(value as Record<string, unknown>).slice(0, 200)) {
      output[key] = safeValue(item, depth + 1);
    }
    return output;
  }
  return String(value);
}

function normalizeContent(content: unknown): unknown {
  if (typeof content === "string") return boundedText(content);
  if (!Array.isArray(content)) return [];
  return content.map((block) => {
    if (!block || typeof block !== "object") return { type: "text", text: boundedText(block) };
    const typed = block as Record<string, unknown>;
    if (typed.type === "image") {
      return {
        type: "image",
        mimeType: typed.mimeType ?? (typed.source as Record<string, unknown> | undefined)?.mediaType,
        omitted: true,
      };
    }
    if (typed.type === "text") return { type: "text", text: boundedText(typed.text) };
    if (typed.type === "thinking") return { type: "thinking", thinking: boundedText(typed.thinking) };
    if (typed.type === "toolCall") {
      return {
        type: "toolCall",
        id: typed.id,
        name: typed.name,
        arguments: safeValue(typed.arguments),
      };
    }
    return safeValue(typed);
  });
}

function normalizeMessage(message: unknown): unknown {
  if (!message || typeof message !== "object") return safeValue(message);
  const typed = message as Record<string, unknown>;
  const output: Record<string, unknown> = {
    role: typed.role,
    content: normalizeContent(typed.content),
    timestamp: typed.timestamp,
  };
  for (const key of ["toolCallId", "toolName", "isError", "stopReason", "errorMessage", "model", "provider", "customType", "display"]) {
    if (typed[key] !== undefined) output[key] = safeValue(typed[key]);
  }
  return output;
}

function normalizeEntry(entry: unknown): unknown {
  if (!entry || typeof entry !== "object") return safeValue(entry);
  const typed = entry as Record<string, unknown>;
  const base: Record<string, unknown> = {
    type: typed.type,
    id: typed.id,
    parentId: typed.parentId,
    timestamp: typed.timestamp,
  };
  if (typed.message !== undefined) base.message = normalizeMessage(typed.message);
  if (typed.summary !== undefined) base.summary = boundedText(typed.summary);
  if (typed.name !== undefined) base.name = boundedText(typed.name);
  if (typed.label !== undefined) base.label = boundedText(typed.label);
  if (typed.targetId !== undefined) base.targetId = typed.targetId;
  if (typed.customType !== undefined) base.customType = typed.customType;
  return base;
}

export default function piRemote(pi: ExtensionAPI) {
  pi.registerFlag("remote", {
    description: "Expose this Pi session through the Tailscale-only Pi Remote web UI",
    type: "boolean",
    default: false,
  });

  let server: InstanceType<typeof PiRemoteServer> | undefined;
  let latestContext: ExtensionContext | undefined;
  let startPromise: Promise<void> | undefined;

  const remember = (ctx: ExtensionContext) => {
    latestContext = ctx;
  };

  const state = (ctx = latestContext) => ({
    isIdle: ctx?.isIdle() ?? true,
    hasPendingMessages: ctx?.hasPendingMessages() ?? false,
    model: ctx?.model ? { provider: ctx.model.provider, id: ctx.model.id, name: ctx.model.name } : null,
    thinkingLevel: ctx?.thinkingLevel ?? "off",
  });

  const snapshot = () => {
    const ctx = latestContext;
    if (!ctx) return { session: null, state: state(), entries: [] };
    return {
      session: {
        id: ctx.sessionManager.getSessionId(),
        name: pi.getSessionName() ?? null,
        cwd: ctx.cwd,
        file: ctx.sessionManager.getSessionFile() ?? null,
      },
      state: state(ctx),
      entries: ctx.sessionManager.getBranch().map(normalizeEntry),
    };
  };

  const broadcast = (type: string, payload: Record<string, unknown> = {}) => {
    server?.broadcast({ type, ...payload });
  };

  const httpError = (statusCode: number, message: string) => {
    const error = new Error(message) as Error & { statusCode?: number };
    error.statusCode = statusCode;
    return error;
  };

  const handleAction = async (input: unknown) => {
    if (!input || typeof input !== "object") throw httpError(400, "Action must be an object");
    const action = input as Record<string, unknown>;
    const ctx = latestContext;
    if (!ctx) throw httpError(503, "Pi session is not ready");

    if (action.type === "abort") {
      if (!ctx.isIdle()) ctx.abort();
      return { accepted: true, state: state(ctx) };
    }

    if (action.type !== "prompt") throw httpError(400, "Unknown action");
    const text = typeof action.text === "string" ? action.text.trim() : "";
    if (!text) throw httpError(400, "Message cannot be empty");
    if (text.length > MAX_PROMPT_LENGTH) throw httpError(413, `Message exceeds ${MAX_PROMPT_LENGTH} characters`);

    const delivery = action.delivery;
    if (delivery !== undefined && delivery !== "steer" && delivery !== "followUp") {
      throw httpError(400, "Delivery must be steer or followUp");
    }
    if (!ctx.isIdle() && delivery === undefined) {
      throw httpError(409, "Pi is working; choose steer or followUp");
    }

    pi.sendUserMessage(text, delivery ? { deliverAs: delivery } : undefined);
    return { accepted: true, delivery: delivery ?? "now", state: state(ctx) };
  };

  const startServer = async (ctx: ExtensionContext) => {
    remember(ctx);
    if (server || startPromise) return startPromise;
    startPromise = (async () => {
      const config = readOrCreateConfig();
      const nextServer = new PiRemoteServer({
        host: config.host,
        port: config.port,
        token: config.token,
        webRoot: join(extensionDirectory, "web"),
        getSnapshot: snapshot,
        onAction: handleAction,
      });
      try {
        const address = await nextServer.start();
        server = nextServer;
        ctx.ui.setStatus("pi-remote", ctx.ui.theme.fg("success", "remote"));
        ctx.ui.notify(`Pi Remote: ${address} — token: pi-shared token`, "info");
      } catch (error) {
        await nextServer.close().catch(() => {});
        throw error;
      } finally {
        startPromise = undefined;
      }
    })();
    return startPromise;
  };

  const stopServer = async (ctx?: ExtensionContext) => {
    const current = server;
    server = undefined;
    if (current) await current.close();
    ctx?.ui.setStatus("pi-remote", undefined);
  };

  pi.registerCommand("remote", {
    description: "Start, stop, or show the independent Pi Remote browser UI",
    handler: async (args, ctx) => {
      remember(ctx);
      const command = args.trim() || "status";
      if (command === "start") {
        await startServer(ctx);
      } else if (command === "stop") {
        await stopServer(ctx);
        ctx.ui.notify("Pi Remote stopped", "info");
      } else if (command === "status") {
        if (server) ctx.ui.notify(`Pi Remote: ${server.address()}`, "info");
        else ctx.ui.notify("Pi Remote is stopped. Run /remote start", "info");
      } else {
        ctx.ui.notify("Usage: /remote [start|stop|status]", "warning");
      }
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    remember(ctx);
    if (pi.getFlag("remote")) {
      try {
        await startServer(ctx);
      } catch (error) {
        ctx.ui.notify(`Pi Remote failed: ${error instanceof Error ? error.message : String(error)}`, "error");
      }
    }
  });

  pi.on("session_info_changed", (event, ctx) => {
    remember(ctx);
    broadcast("session", { session: snapshot().session, name: event.name ?? null });
  });

  pi.on("agent_start", (_event, ctx) => {
    remember(ctx);
    broadcast("state", { state: state(ctx) });
  });

  pi.on("agent_settled", (_event, ctx) => {
    remember(ctx);
    broadcast("state", { state: state(ctx) });
  });

  pi.on("message_start", (event, ctx) => {
    remember(ctx);
    broadcast("message_start", { message: normalizeMessage(event.message), state: state(ctx) });
  });

  pi.on("message_update", (event, ctx) => {
    remember(ctx);
    broadcast("message_update", { update: safeValue(event.assistantMessageEvent) });
  });

  pi.on("message_end", (event, ctx) => {
    remember(ctx);
    broadcast("message_end", { message: normalizeMessage(event.message), state: state(ctx) });
  });

  pi.on("tool_execution_start", (event, ctx) => {
    remember(ctx);
    broadcast("tool_start", {
      toolCallId: event.toolCallId,
      toolName: event.toolName,
      args: safeValue(event.args),
    });
  });

  pi.on("tool_execution_update", (event, ctx) => {
    remember(ctx);
    broadcast("tool_update", {
      toolCallId: event.toolCallId,
      toolName: event.toolName,
      partialResult: safeValue(event.partialResult),
    });
  });

  pi.on("tool_execution_end", (event, ctx) => {
    remember(ctx);
    broadcast("tool_end", {
      toolCallId: event.toolCallId,
      toolName: event.toolName,
      result: safeValue(event.result),
      isError: event.isError,
    });
  });

  pi.on("model_select", (_event, ctx) => {
    remember(ctx);
    broadcast("state", { state: state(ctx) });
  });

  pi.on("thinking_level_select", (_event, ctx) => {
    remember(ctx);
    broadcast("state", { state: state(ctx) });
  });

  pi.on("session_compact", (_event, ctx) => {
    remember(ctx);
    broadcast("snapshot", snapshot());
  });

  pi.on("session_tree", (_event, ctx) => {
    remember(ctx);
    broadcast("snapshot", snapshot());
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    remember(ctx);
    broadcast("offline", {});
    await stopServer(ctx);
  });
}
