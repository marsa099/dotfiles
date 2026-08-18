"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");

const DEFAULT_HOST = "100.121.105.35";
const DEFAULT_PORT = 6767;
const MAX_BODY_BYTES = 64 * 1024;
const COOKIE_NAME = "pi_remote_session";
const PAIRING_CODE_TTL_MS = 2 * 60 * 1000;
const TOKEN_PATTERN = /^[a-f0-9]{64}$/;

function stateDirectory(env = process.env, home = os.homedir()) {
  return env.PI_REMOTE_STATE_DIR || path.join(env.XDG_DATA_HOME || path.join(home, ".local", "share"), "pi-remote");
}

function configPath(env = process.env, home = os.homedir()) {
  return path.join(stateDirectory(env, home), "config.json");
}

function constantTimeEqual(left, right) {
  const a = Buffer.from(String(left));
  const b = Buffer.from(String(right));
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

function sessionCredential(token) {
  return crypto.createHash("sha256").update(`pi-remote-session:${token}`).digest("hex");
}

function normalizeConfig(input, env = process.env) {
  const host = env.PI_REMOTE_HOST || input.host || DEFAULT_HOST;
  const rawPort = env.PI_REMOTE_PORT || input.port || DEFAULT_PORT;
  const port = Number(rawPort);
  const token = env.PI_REMOTE_TOKEN || input.token;

  if (typeof host !== "string" || host.length === 0) throw new Error("Pi Remote host is empty");
  if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error(`Invalid Pi Remote port: ${rawPort}`);
  if (typeof token !== "string" || !TOKEN_PATTERN.test(token)) {
    throw new Error("Pi Remote token must be 32 random bytes encoded as lowercase hexadecimal");
  }
  return { host, port, token };
}

function readOrCreateConfig(env = process.env, home = os.homedir()) {
  const directory = stateDirectory(env, home);
  const file = configPath(env, home);
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  fs.chmodSync(directory, 0o700);

  let persisted = {};
  if (fs.existsSync(file)) {
    const mode = fs.statSync(file).mode & 0o777;
    if ((mode & 0o077) !== 0) {
      throw new Error(`${file} must not be accessible by group or others (run: chmod 600 ${file})`);
    }
    persisted = JSON.parse(fs.readFileSync(file, "utf8"));
  }

  if (!persisted.token) {
    persisted = {
      host: persisted.host || DEFAULT_HOST,
      port: persisted.port || DEFAULT_PORT,
      token: crypto.randomBytes(32).toString("hex"),
    };
    const temporary = `${file}.${process.pid}.tmp`;
    fs.writeFileSync(temporary, `${JSON.stringify(persisted, null, 2)}\n`, { mode: 0o600 });
    fs.renameSync(temporary, file);
    fs.chmodSync(file, 0o600);
  }

  return { ...normalizeConfig(persisted, env), file };
}

function parseCookies(header) {
  const cookies = {};
  for (const part of String(header || "").split(";")) {
    const separator = part.indexOf("=");
    if (separator < 0) continue;
    const key = part.slice(0, separator).trim();
    const value = part.slice(separator + 1).trim();
    if (key) cookies[key] = value;
  }
  return cookies;
}

function jsonResponse(response, status, payload, extraHeaders = {}) {
  const body = payload === undefined ? "" : `${JSON.stringify(payload)}\n`;
  response.writeHead(status, {
    "Cache-Control": "no-store",
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
    ...extraHeaders,
  });
  response.end(body);
}

function securityHeaders() {
  return {
    "Content-Security-Policy": "default-src 'self'; base-uri 'none'; connect-src 'self'; form-action 'self'; frame-ancestors 'none'; img-src 'self' data:; object-src 'none'; script-src 'self'; style-src 'self'",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Referrer-Policy": "no-referrer",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
  };
}

function readJsonBody(request) {
  return new Promise((resolve, reject) => {
    if (!String(request.headers["content-type"] || "").toLowerCase().startsWith("application/json")) {
      const error = new Error("Content-Type must be application/json");
      error.statusCode = 415;
      reject(error);
      return;
    }

    let size = 0;
    const chunks = [];
    request.on("data", (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        const error = new Error("Request body is too large");
        error.statusCode = 413;
        reject(error);
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });
    request.on("end", () => {
      if (size > MAX_BODY_BYTES) return;
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}"));
      } catch {
        const error = new Error("Request body is not valid JSON");
        error.statusCode = 400;
        reject(error);
      }
    });
    request.on("error", reject);
  });
}

function contentType(file) {
  switch (path.extname(file)) {
    case ".css": return "text/css; charset=utf-8";
    case ".js": return "text/javascript; charset=utf-8";
    case ".svg": return "image/svg+xml";
    case ".webmanifest": return "application/manifest+json";
    default: return "text/html; charset=utf-8";
  }
}

class PiRemoteServer {
  constructor(options) {
    this.host = options.host;
    this.port = options.port;
    this.token = options.token;
    this.webRoot = path.resolve(options.webRoot);
    this.getSnapshot = options.getSnapshot;
    this.onAction = options.onAction;
    this.clients = new Set();
    this.pairingCodes = new Map();
    this.nextEventId = 1;
    this.heartbeat = undefined;
    this.server = http.createServer((request, response) => {
      void this.handleRequest(request, response);
    });
    this.server.on("clientError", (_error, socket) => {
      socket.end("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n");
    });
  }

  isAuthorized(request) {
    const cookies = parseCookies(request.headers.cookie);
    return constantTimeEqual(cookies[COOKIE_NAME] || "", sessionCredential(this.token));
  }

  hasSameOrigin(request) {
    const origin = request.headers.origin;
    if (!origin) return true;
    try {
      return new URL(origin).host === request.headers.host;
    } catch {
      return false;
    }
  }

  hasTokenAuthorization(request) {
    const header = String(request.headers.authorization || "");
    return header.startsWith("Bearer ") && constantTimeEqual(header.slice(7), this.token);
  }

  createPairingCode() {
    const now = Date.now();
    for (const [code, expiresAt] of this.pairingCodes) {
      if (expiresAt <= now) this.pairingCodes.delete(code);
    }
    while (this.pairingCodes.size >= 8) {
      this.pairingCodes.delete(this.pairingCodes.keys().next().value);
    }
    const code = crypto.randomBytes(18).toString("base64url");
    const expiresAt = now + PAIRING_CODE_TTL_MS;
    this.pairingCodes.set(code, expiresAt);
    return { code, expiresAt };
  }

  consumePairingCode(code) {
    const expiresAt = this.pairingCodes.get(code);
    this.pairingCodes.delete(code);
    return Number.isFinite(expiresAt) && expiresAt > Date.now();
  }

  sessionCookie(maxAge = 2592000) {
    const value = maxAge === 0 ? "" : sessionCredential(this.token);
    return `${COOKIE_NAME}=${value}; HttpOnly; SameSite=Strict; Path=/; Max-Age=${maxAge}`;
  }

  async start() {
    await new Promise((resolve, reject) => {
      const onError = (error) => {
        this.server.off("listening", onListening);
        reject(error);
      };
      const onListening = () => {
        this.server.off("error", onError);
        resolve();
      };
      this.server.once("error", onError);
      this.server.once("listening", onListening);
      this.server.listen(this.port, this.host);
    });
    const address = this.server.address();
    if (address && typeof address === "object") this.port = address.port;
    this.heartbeat = setInterval(() => {
      for (const client of this.clients) {
        if (!client.blocked) client.response.write(": heartbeat\n\n");
      }
    }, 15_000);
    this.heartbeat.unref?.();
    return this.address();
  }

  address() {
    const host = this.host.includes(":") && !this.host.startsWith("[") ? `[${this.host}]` : this.host;
    return `http://${host}:${this.port}`;
  }

  writeClient(client, frame) {
    if (client.closed) return;
    if (client.blocked) {
      client.pending = frame;
      return;
    }
    if (!client.response.write(frame)) {
      client.blocked = true;
      client.response.once("drain", () => {
        if (client.closed) return;
        client.blocked = false;
        const pending = client.pending;
        client.pending = undefined;
        if (pending) this.writeClient(client, pending);
      });
    }
  }

  broadcast(payload) {
    const data = JSON.stringify(payload);
    const frame = `id: ${this.nextEventId++}\ndata: ${data}\n\n`;
    for (const client of this.clients) this.writeClient(client, frame);
  }

  async close() {
    if (this.heartbeat) clearInterval(this.heartbeat);
    for (const client of this.clients) {
      client.closed = true;
      client.response.end();
    }
    this.clients.clear();
    this.pairingCodes.clear();
    if (!this.server.listening) return;
    await new Promise((resolve) => this.server.close(resolve));
  }

  async handleRequest(request, response) {
    try {
      const url = new URL(request.url || "/", `http://${request.headers.host || "localhost"}`);
      const method = request.method || "GET";

      for (const [name, value] of Object.entries(securityHeaders())) response.setHeader(name, value);

      if (method === "POST" && url.pathname === "/api/pair") {
        if (!this.hasTokenAuthorization(request)) {
          return jsonResponse(response, 401, { error: "Invalid access token" });
        }
        return jsonResponse(response, 201, this.createPairingCode());
      }

      if (method === "POST" && url.pathname === "/api/pair/login") {
        if (!this.hasSameOrigin(request)) return jsonResponse(response, 403, { error: "Origin rejected" });
        const body = await readJsonBody(request);
        if (typeof body.code !== "string" || !this.consumePairingCode(body.code)) {
          return jsonResponse(response, 401, { error: "Pairing code is invalid or expired" });
        }
        return jsonResponse(response, 204, undefined, { "Set-Cookie": this.sessionCookie() });
      }

      if (method === "POST" && url.pathname === "/api/login") {
        if (!this.hasSameOrigin(request)) return jsonResponse(response, 403, { error: "Origin rejected" });
        const body = await readJsonBody(request);
        if (!constantTimeEqual(body.token || "", this.token)) {
          return jsonResponse(response, 401, { error: "Invalid access token" });
        }
        return jsonResponse(response, 204, undefined, { "Set-Cookie": this.sessionCookie() });
      }

      if (method === "POST" && url.pathname === "/api/logout") {
        if (!this.hasSameOrigin(request)) return jsonResponse(response, 403, { error: "Origin rejected" });
        return jsonResponse(response, 204, undefined, { "Set-Cookie": this.sessionCookie(0) });
      }

      if (url.pathname.startsWith("/api/") || url.pathname === "/events") {
        if (!this.isAuthorized(request)) return jsonResponse(response, 401, { error: "Authentication required" });
      }

      if (method === "GET" && url.pathname === "/api/snapshot") {
        return jsonResponse(response, 200, this.getSnapshot());
      }

      if (method === "POST" && url.pathname === "/api/action") {
        if (!this.hasSameOrigin(request)) return jsonResponse(response, 403, { error: "Origin rejected" });
        const body = await readJsonBody(request);
        const result = await this.onAction(body);
        return jsonResponse(response, 202, result || { accepted: true });
      }

      if (method === "GET" && url.pathname === "/events") {
        response.writeHead(200, {
          "Cache-Control": "no-cache, no-transform",
          "Connection": "keep-alive",
          "Content-Type": "text/event-stream; charset=utf-8",
          "X-Accel-Buffering": "no",
        });
        response.write(`retry: 1500\ndata: ${JSON.stringify({ type: "snapshot", ...this.getSnapshot() })}\n\n`);
        const client = { response, blocked: false, closed: false, pending: undefined };
        this.clients.add(client);
        request.on("close", () => {
          client.closed = true;
          this.clients.delete(client);
        });
        return;
      }

      if (method !== "GET" && method !== "HEAD") {
        return jsonResponse(response, 405, { error: "Method not allowed" }, { Allow: "GET, HEAD, POST" });
      }

      const relative = url.pathname === "/" ? "index.html" : url.pathname.replace(/^\/+/, "");
      const file = path.resolve(this.webRoot, relative);
      if (file !== this.webRoot && !file.startsWith(`${this.webRoot}${path.sep}`)) {
        return jsonResponse(response, 404, { error: "Not found" });
      }
      if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
        return jsonResponse(response, 404, { error: "Not found" });
      }
      const body = fs.readFileSync(file);
      response.writeHead(200, {
        "Cache-Control": "no-cache",
        "Content-Type": contentType(file),
        "Content-Length": body.length,
      });
      response.end(method === "HEAD" ? undefined : body);
    } catch (error) {
      if (response.headersSent) {
        response.end();
        return;
      }
      const status = Number(error?.statusCode) || 500;
      jsonResponse(response, status, { error: status === 500 ? "Internal server error" : error.message });
    }
  }
}

module.exports = {
  COOKIE_NAME,
  DEFAULT_HOST,
  DEFAULT_PORT,
  PAIRING_CODE_TTL_MS,
  PiRemoteServer,
  configPath,
  constantTimeEqual,
  readOrCreateConfig,
  sessionCredential,
  stateDirectory,
};
