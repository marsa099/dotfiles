"use strict";

const elements = {
  authView: document.querySelector("#auth-view"),
  authForm: document.querySelector("#auth-form"),
  authError: document.querySelector("#auth-error"),
  token: document.querySelector("#token"),
  toggleToken: document.querySelector("#toggle-token"),
  appShell: document.querySelector("#app-shell"),
  logout: document.querySelector("#logout-button"),
  sessionLabel: document.querySelector("#session-label"),
  statusChip: document.querySelector("#status-chip"),
  statusText: document.querySelector("#status-text"),
  transcript: document.querySelector("#transcript"),
  messageList: document.querySelector("#message-list"),
  liveTools: document.querySelector("#live-tools"),
  emptyState: document.querySelector("#empty-state"),
  jump: document.querySelector("#jump-button"),
  notice: document.querySelector("#notice"),
  composerForm: document.querySelector("#composer-form"),
  composerInput: document.querySelector("#composer-input"),
  send: document.querySelector("#send-button"),
  abort: document.querySelector("#abort-button"),
  queueControls: document.querySelector("#queue-controls"),
  composerHint: document.querySelector("#composer-hint"),
};

const app = {
  source: null,
  connected: false,
  sending: false,
  following: true,
  state: { isIdle: true, hasPendingMessages: false, model: null, thinkingLevel: "off" },
  session: null,
  currentAssistant: null,
  currentAssistantElement: null,
  renderFrame: null,
  toolRenderFrame: null,
  tools: new Map(),
  noticeTimer: null,
};

function createSvg(paths, className = "") {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("aria-hidden", "true");
  if (className) svg.setAttribute("class", className);
  for (const attributes of paths) {
    const path = document.createElementNS("http://www.w3.org/2000/svg", attributes.element || "path");
    for (const [name, value] of Object.entries(attributes)) {
      if (name !== "element") path.setAttribute(name, value);
    }
    svg.append(path);
  }
  return svg;
}

function chevronIcon() {
  return createSvg([{ d: "m7 9.5 5 5 5-5" }], "chevron");
}

function toolIcon() {
  return createSvg([
    { d: "M14.7 6.3a4 4 0 0 0-5 5L4.5 16.5a1.4 1.4 0 0 0 2 2l5.2-5.2a4 4 0 0 0 5-5l-2.4 2.4-1.7-1.7Z" },
  ], "tool-icon");
}

function textContentFrom(value) {
  if (typeof value === "string") return value;
  if (!Array.isArray(value)) return "";
  return value
    .filter((block) => block && block.type === "text")
    .map((block) => block.text || "")
    .join("\n");
}

function appendInline(parent, text) {
  const pattern = /(\*\*[^*]+\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\)|\*[^*\n]+\*)/g;
  let cursor = 0;
  for (const match of text.matchAll(pattern)) {
    if (match.index > cursor) parent.append(document.createTextNode(text.slice(cursor, match.index)));
    const token = match[0];
    if (token.startsWith("**")) {
      const strong = document.createElement("strong");
      strong.textContent = token.slice(2, -2);
      parent.append(strong);
    } else if (token.startsWith("`")) {
      const code = document.createElement("code");
      code.textContent = token.slice(1, -1);
      parent.append(code);
    } else if (token.startsWith("[")) {
      const linkMatch = token.match(/^\[([^\]]+)\]\(([^)]+)\)$/);
      const href = linkMatch?.[2] || "";
      if (linkMatch && /^(https?:|mailto:)/i.test(href)) {
        const link = document.createElement("a");
        link.textContent = linkMatch[1];
        link.href = href;
        link.target = "_blank";
        link.rel = "noreferrer noopener";
        parent.append(link);
      } else {
        parent.append(document.createTextNode(token));
      }
    } else {
      const emphasis = document.createElement("em");
      emphasis.textContent = token.slice(1, -1);
      parent.append(emphasis);
    }
    cursor = match.index + token.length;
  }
  if (cursor < text.length) parent.append(document.createTextNode(text.slice(cursor)));
}

function appendMarkdown(parent, markdown) {
  const lines = String(markdown || "").replace(/\r\n/g, "\n").split("\n");
  let index = 0;
  let paragraph = [];
  let list = null;

  const flushParagraph = () => {
    if (paragraph.length === 0) return;
    const element = document.createElement("p");
    appendInline(element, paragraph.join("\n"));
    parent.append(element);
    paragraph = [];
  };

  const closeList = () => {
    list = null;
  };

  while (index < lines.length) {
    const line = lines[index];
    const fence = line.match(/^```\s*([^\s`]*)\s*$/);
    if (fence) {
      flushParagraph();
      closeList();
      const codeLines = [];
      index += 1;
      while (index < lines.length && !/^```\s*$/.test(lines[index])) {
        codeLines.push(lines[index]);
        index += 1;
      }
      const wrapper = document.createElement("div");
      wrapper.className = "code-block";
      if (fence[1]) {
        const language = document.createElement("span");
        language.className = "code-language";
        language.textContent = fence[1];
        wrapper.append(language);
      }
      const pre = document.createElement("pre");
      const code = document.createElement("code");
      code.textContent = codeLines.join("\n");
      pre.append(code);
      wrapper.append(pre);
      parent.append(wrapper);
      index += 1;
      continue;
    }

    if (!line.trim()) {
      flushParagraph();
      closeList();
      index += 1;
      continue;
    }

    const heading = line.match(/^(#{1,4})\s+(.+)$/);
    if (heading) {
      flushParagraph();
      closeList();
      const level = Math.min(4, heading[1].length + 1);
      const element = document.createElement(`h${level}`);
      appendInline(element, heading[2]);
      parent.append(element);
      index += 1;
      continue;
    }

    if (/^\s*(---+|___+)\s*$/.test(line)) {
      flushParagraph();
      closeList();
      parent.append(document.createElement("hr"));
      index += 1;
      continue;
    }

    const quote = line.match(/^>\s?(.*)$/);
    if (quote) {
      flushParagraph();
      closeList();
      const blockquote = document.createElement("blockquote");
      const quoteLines = [quote[1]];
      index += 1;
      while (index < lines.length) {
        const next = lines[index].match(/^>\s?(.*)$/);
        if (!next) break;
        quoteLines.push(next[1]);
        index += 1;
      }
      appendInline(blockquote, quoteLines.join("\n"));
      parent.append(blockquote);
      continue;
    }

    const unordered = line.match(/^\s*[-*]\s+(.+)$/);
    const ordered = line.match(/^\s*\d+[.)]\s+(.+)$/);
    if (unordered || ordered) {
      flushParagraph();
      const tag = ordered ? "ol" : "ul";
      if (!list || list.tagName.toLowerCase() !== tag) {
        list = document.createElement(tag);
        parent.append(list);
      }
      const item = document.createElement("li");
      appendInline(item, (unordered || ordered)[1]);
      list.append(item);
      index += 1;
      continue;
    }

    closeList();
    paragraph.push(line);
    index += 1;
  }

  flushParagraph();
}

function createToolCard(input) {
  const details = document.createElement("details");
  details.className = "tool-card";
  const summary = document.createElement("summary");
  summary.append(toolIcon());
  const label = document.createElement("span");
  label.textContent = input.label || input.toolName || "Tool activity";
  summary.append(label);
  const state = document.createElement("span");
  state.className = `tool-state ${input.state || "success"}`;
  state.setAttribute("aria-label", input.state === "error" ? "Failed" : input.state === "running" ? "Running" : "Completed");
  summary.append(state, chevronIcon());
  details.append(summary);

  const body = document.createElement("pre");
  body.className = "tool-detail";
  body.textContent = input.detail || "No additional output";
  details.append(body);
  return details;
}

function toolDetailFromMessage(message, toolCall) {
  if (toolCall) {
    try {
      return JSON.stringify(toolCall.arguments || {}, null, 2);
    } catch {
      return String(toolCall.arguments || "");
    }
  }
  return textContentFrom(message.content) || (message.isError ? "Tool failed without output" : "Completed");
}

function renderMessageContent(container, message, streaming = false) {
  container.replaceChildren();
  const content = typeof message.content === "string" ? [{ type: "text", text: message.content }] : (message.content || []);

  for (const block of content) {
    if (!block) continue;
    if (block.type === "text") {
      appendMarkdown(container, block.text || "");
    } else if (block.type === "thinking") {
      const details = document.createElement("details");
      details.className = "thinking-block";
      const summary = document.createElement("summary");
      summary.textContent = "Reasoning";
      summary.append(chevronIcon());
      const body = document.createElement("div");
      body.className = "thinking-content";
      body.textContent = block.thinking || "";
      details.append(summary, body);
      container.append(details);
    } else if (block.type === "toolCall") {
      container.append(createToolCard({
        toolName: block.name,
        label: block.name ? `Using ${block.name}` : "Preparing tool",
        detail: toolDetailFromMessage(message, block),
        state: streaming ? "running" : "success",
      }));
    } else if (block.type === "image") {
      const note = document.createElement("p");
      note.className = "system-note";
      note.textContent = "Image attached · preview omitted in Pi Remote core";
      container.append(note);
    }
  }

  if (streaming) {
    const cursor = document.createElement("span");
    cursor.className = "stream-cursor";
    cursor.setAttribute("aria-label", "Response streaming");
    container.append(cursor);
  }
}

function createMessageElement(message, streaming = false) {
  const item = document.createElement("li");
  const role = message.role === "user" || message.role === "assistant" ? message.role : message.role === "custom" ? "custom" : "tool";
  item.className = "message";
  item.dataset.role = role;

  const body = document.createElement("div");
  body.className = "message-body";

  if (message.role === "toolResult") {
    body.append(createToolCard({
      toolName: message.toolName,
      label: message.toolName ? `${message.toolName} result` : "Tool result",
      detail: toolDetailFromMessage(message),
      state: message.isError ? "error" : "success",
    }));
  } else {
    renderMessageContent(body, message, streaming);
  }

  item.append(body);
  return item;
}

function createSystemMessage(text) {
  return { role: "custom", content: [{ type: "text", text }], timestamp: Date.now() };
}

function messagesFromEntries(entries) {
  const messages = [];
  for (const entry of entries || []) {
    if (entry.message) messages.push(entry.message);
    else if (entry.type === "compaction" && entry.summary) messages.push(createSystemMessage(`Earlier context compacted\n\n${entry.summary}`));
    else if (entry.type === "branch_summary" && entry.summary) messages.push(createSystemMessage(`Branch summary\n\n${entry.summary}`));
  }
  return messages;
}

function shouldFollow() {
  const distance = elements.transcript.scrollHeight - elements.transcript.scrollTop - elements.transcript.clientHeight;
  return distance < 96;
}

function followLatest(force = false) {
  if (!force && !app.following) {
    elements.jump.hidden = false;
    return;
  }
  requestAnimationFrame(() => {
    elements.transcript.scrollTo({ top: elements.transcript.scrollHeight, behavior: force ? "smooth" : "auto" });
    elements.jump.hidden = true;
  });
}

function renderMessages(messages, { preservePosition = false } = {}) {
  const wasFollowing = preservePosition ? shouldFollow() : true;
  const fragment = document.createDocumentFragment();
  for (const message of messages) fragment.append(createMessageElement(message));
  elements.messageList.replaceChildren(fragment);
  elements.emptyState.hidden = messages.length > 0;
  app.currentAssistant = null;
  app.currentAssistantElement = null;
  app.following = wasFollowing;
  followLatest();
}

function applySnapshot(payload) {
  app.session = payload.session || null;
  app.state = { ...app.state, ...(payload.state || {}) };
  app.tools.clear();
  renderLiveTools();
  renderMessages(messagesFromEntries(payload.entries), { preservePosition: true });
  updateSessionHeader();
  updateAgentState();
}

function updateSessionHeader() {
  const sessionName = app.session?.name || app.session?.cwd?.split("/").filter(Boolean).pop() || "Active session";
  const modelName = app.state.model?.name || app.state.model?.id;
  elements.sessionLabel.textContent = modelName ? `${sessionName} · ${modelName}` : sessionName;
}

function setConnectionStatus(state, text) {
  elements.statusChip.dataset.state = state;
  elements.statusText.textContent = text;
}

function updateAgentState() {
  const busy = !app.state.isIdle;
  elements.queueControls.hidden = !busy;
  elements.abort.hidden = !busy;
  if (!app.connected) {
    setConnectionStatus("offline", "Reconnecting");
  } else if (app.state.hasPendingMessages) {
    setConnectionStatus("queued", "Queued");
  } else if (busy) {
    setConnectionStatus("working", "Working");
  } else {
    setConnectionStatus("ready", "Ready");
  }
  updateComposer();
  updateSessionHeader();
}

function updateComposer() {
  const hasText = elements.composerInput.value.trim().length > 0;
  elements.send.disabled = !app.connected || app.sending || !hasText;
  if (!app.connected) elements.composerHint.textContent = "Reconnecting to the Pi session…";
  else if (!app.state.isIdle) elements.composerHint.textContent = "Choose when this message should reach Pi";
  else elements.composerHint.textContent = "Enter to send · Shift+Enter for a new line";
}

function resizeComposer() {
  elements.composerInput.style.height = "auto";
  elements.composerInput.style.height = `${Math.min(elements.composerInput.scrollHeight, 144)}px`;
}

function showNotice(message, kind = "info", duration = 4000) {
  clearTimeout(app.noticeTimer);
  elements.notice.textContent = message;
  elements.notice.dataset.kind = kind;
  elements.notice.hidden = false;
  app.noticeTimer = setTimeout(() => {
    elements.notice.hidden = true;
  }, duration);
}

function appendCompletedMessage(message) {
  const element = createMessageElement(message);
  elements.messageList.append(element);
  elements.emptyState.hidden = true;
  if (message.role === "toolResult" && message.toolCallId) {
    app.tools.delete(message.toolCallId);
    scheduleLiveTools();
  }
  followLatest();
}

function startAssistant(message) {
  app.currentAssistant = {
    ...message,
    role: "assistant",
    content: Array.isArray(message.content) ? [...message.content] : [],
  };
  app.currentAssistantElement = createMessageElement(app.currentAssistant, true);
  elements.messageList.append(app.currentAssistantElement);
  elements.emptyState.hidden = true;
  followLatest();
}

function applyAssistantUpdate(update) {
  if (!app.currentAssistant) startAssistant({ role: "assistant", content: [] });
  const index = Number.isInteger(update.contentIndex) ? update.contentIndex : app.currentAssistant.content.length;
  const content = app.currentAssistant.content;

  if (update.type === "text_start") content[index] = { type: "text", text: "" };
  else if (update.type === "text_delta") {
    if (!content[index] || content[index].type !== "text") content[index] = { type: "text", text: "" };
    content[index].text += update.delta || "";
  } else if (update.type === "text_end") content[index] = { type: "text", text: update.content || content[index]?.text || "" };
  else if (update.type === "thinking_start") content[index] = { type: "thinking", thinking: "" };
  else if (update.type === "thinking_delta") {
    if (!content[index] || content[index].type !== "thinking") content[index] = { type: "thinking", thinking: "" };
    content[index].thinking += update.delta || "";
  } else if (update.type === "thinking_end") content[index] = { type: "thinking", thinking: update.content || content[index]?.thinking || "" };
  else if (update.type === "toolcall_start") content[index] = { type: "toolCall", id: update.id, name: update.name, arguments: {} };
  else if (update.type === "toolcall_end" && update.toolCall) content[index] = update.toolCall;

  if (!app.renderFrame) {
    app.renderFrame = requestAnimationFrame(() => {
      app.renderFrame = null;
      const body = app.currentAssistantElement?.querySelector(".message-body");
      if (body && app.currentAssistant) renderMessageContent(body, app.currentAssistant, true);
      followLatest();
    });
  }
}

function finishAssistant(message) {
  if (!app.currentAssistantElement) {
    appendCompletedMessage(message);
  } else {
    const replacement = createMessageElement(message);
    app.currentAssistantElement.replaceWith(replacement);
  }
  app.currentAssistant = null;
  app.currentAssistantElement = null;
  followLatest();
}

function resultText(result) {
  if (!result) return "Waiting for output…";
  const content = result.content || result.partialResult?.content;
  const text = textContentFrom(content);
  if (text) return text;
  try {
    return JSON.stringify(result, null, 2);
  } catch {
    return String(result);
  }
}

function scheduleLiveTools() {
  if (app.toolRenderFrame) return;
  app.toolRenderFrame = requestAnimationFrame(() => {
    app.toolRenderFrame = null;
    renderLiveTools();
  });
}

function renderLiveTools() {
  elements.liveTools.replaceChildren();
  for (const tool of app.tools.values()) {
    elements.liveTools.append(createToolCard({
      toolName: tool.toolName,
      label: tool.state === "running" ? `Running ${tool.toolName}` : `${tool.toolName} ${tool.state === "error" ? "failed" : "finished"}`,
      detail: tool.detail || JSON.stringify(tool.args || {}, null, 2),
      state: tool.state,
    }));
  }
  elements.liveTools.hidden = app.tools.size === 0;
  followLatest();
}

function handleEvent(payload) {
  switch (payload.type) {
    case "snapshot":
      applySnapshot(payload);
      break;
    case "session":
      app.session = payload.session || app.session;
      updateSessionHeader();
      break;
    case "state":
      app.state = { ...app.state, ...(payload.state || {}) };
      updateAgentState();
      break;
    case "message_start":
      if (payload.message?.role === "assistant") startAssistant(payload.message);
      if (payload.state) app.state = { ...app.state, ...payload.state };
      updateAgentState();
      break;
    case "message_update":
      applyAssistantUpdate(payload.update || {});
      break;
    case "message_end":
      if (payload.message?.role === "assistant") finishAssistant(payload.message);
      else if (payload.message) appendCompletedMessage(payload.message);
      if (payload.state) app.state = { ...app.state, ...payload.state };
      updateAgentState();
      break;
    case "tool_start":
      app.tools.set(payload.toolCallId, { ...payload, state: "running", detail: "" });
      scheduleLiveTools();
      break;
    case "tool_update": {
      const current = app.tools.get(payload.toolCallId) || { ...payload, state: "running" };
      current.detail = resultText(payload.partialResult);
      app.tools.set(payload.toolCallId, current);
      scheduleLiveTools();
      break;
    }
    case "tool_end": {
      const current = app.tools.get(payload.toolCallId) || payload;
      current.state = payload.isError ? "error" : "success";
      current.detail = resultText(payload.result);
      app.tools.set(payload.toolCallId, current);
      scheduleLiveTools();
      break;
    }
    case "offline":
      app.connected = false;
      updateAgentState();
      break;
  }
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    credentials: "same-origin",
    ...options,
    headers: {
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...(options.headers || {}),
    },
  });
  let payload = null;
  if (response.status !== 204 && response.headers.get("content-type")?.includes("application/json")) {
    payload = await response.json();
  }
  if (!response.ok) {
    const error = new Error(payload?.error || `Request failed (${response.status})`);
    error.status = response.status;
    throw error;
  }
  return payload;
}

function showAuth() {
  app.source?.close();
  app.source = null;
  app.connected = false;
  elements.appShell.hidden = true;
  elements.authView.hidden = false;
  elements.token.focus();
}

function showApp() {
  elements.authView.hidden = true;
  elements.appShell.hidden = false;
}

function connectEvents() {
  app.source?.close();
  const source = new EventSource("/events");
  app.source = source;
  source.onopen = () => {
    app.connected = true;
    updateAgentState();
  };
  source.onmessage = (event) => {
    try {
      handleEvent(JSON.parse(event.data));
    } catch {
      showNotice("A remote update could not be read. Reconnecting will restore the session.", "error");
    }
  };
  source.onerror = () => {
    app.connected = false;
    updateAgentState();
  };
}

async function startAuthenticated(snapshot) {
  showApp();
  app.connected = true;
  applySnapshot(snapshot);
  connectEvents();
}

function takePairingCode() {
  const params = new URLSearchParams(location.hash.replace(/^#/, ""));
  const code = params.get("pair")?.trim();
  if (!code) return null;
  history.replaceState(null, "", `${location.pathname}${location.search}`);
  return code;
}

async function boot() {
  const pairingCode = takePairingCode();
  try {
    if (pairingCode) {
      await api("/api/pair/login", { method: "POST", body: JSON.stringify({ code: pairingCode }) });
    }
    const snapshot = await api("/api/snapshot");
    await startAuthenticated(snapshot);
  } catch (error) {
    showAuth();
    if (pairingCode && error.status === 401) {
      elements.authError.textContent = "That QR code expired or was already used. Run pi-shared qr again.";
    } else if (error.status !== 401) {
      elements.authError.textContent = "Pi Remote is not reachable. Confirm that the session is running.";
    }
  }
}

elements.authForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  elements.authError.textContent = "";
  const button = elements.authForm.querySelector("button[type='submit']");
  button.disabled = true;
  try {
    await api("/api/login", { method: "POST", body: JSON.stringify({ token: elements.token.value.trim() }) });
    const snapshot = await api("/api/snapshot");
    elements.token.value = "";
    await startAuthenticated(snapshot);
  } catch (error) {
    elements.authError.textContent = error.status === 401
      ? "That token does not match. Run pi-shared token on the laptop and try again."
      : error.message;
  } finally {
    button.disabled = false;
  }
});

elements.toggleToken.addEventListener("click", () => {
  const showing = elements.token.type === "text";
  elements.token.type = showing ? "password" : "text";
  elements.toggleToken.setAttribute("aria-pressed", String(!showing));
  elements.toggleToken.setAttribute("aria-label", showing ? "Show access token" : "Hide access token");
});

elements.logout.addEventListener("click", async () => {
  try {
    await api("/api/logout", { method: "POST", body: "{}" });
  } finally {
    showAuth();
  }
});

elements.composerInput.addEventListener("input", () => {
  resizeComposer();
  updateComposer();
});

elements.composerInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
    event.preventDefault();
    elements.composerForm.requestSubmit();
  }
});

elements.composerForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const text = elements.composerInput.value.trim();
  if (!text || app.sending || !app.connected) return;
  const delivery = app.state.isIdle
    ? undefined
    : document.querySelector("input[name='delivery']:checked")?.value;
  app.sending = true;
  updateComposer();
  try {
    await api("/api/action", {
      method: "POST",
      body: JSON.stringify({ type: "prompt", text, ...(delivery ? { delivery } : {}) }),
    });
    elements.composerInput.value = "";
    resizeComposer();
    app.following = true;
    followLatest(true);
    if (delivery) showNotice(delivery === "steer" ? "Steering message queued" : "Follow-up queued");
  } catch (error) {
    showNotice(error.message, "error", 6000);
    if (error.status === 409) app.state.isIdle = false;
  } finally {
    app.sending = false;
    updateAgentState();
    elements.composerInput.focus();
  }
});

elements.abort.addEventListener("click", async () => {
  elements.abort.disabled = true;
  try {
    await api("/api/action", { method: "POST", body: JSON.stringify({ type: "abort" }) });
    showNotice("Stop requested");
  } catch (error) {
    showNotice(error.message, "error");
  } finally {
    elements.abort.disabled = false;
  }
});

elements.transcript.addEventListener("scroll", () => {
  app.following = shouldFollow();
  elements.jump.hidden = app.following;
}, { passive: true });

elements.jump.addEventListener("click", () => {
  app.following = true;
  followLatest(true);
});

window.addEventListener("beforeunload", () => app.source?.close());

void boot();
