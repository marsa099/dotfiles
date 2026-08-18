# Pi Remote

Pi Remote keeps each Pi process in its native laptop TUI and gives the phone a separate browser renderer with navigation across active sessions.

```text
Pi AgentSession
├─ Pi TUI → laptop terminal
└─ semantic events → authenticated HTTP/SSE → phone browser
                         phone actions → sendUserMessage / abort
```

The phone never receives ANSI bytes, terminal dimensions, or laptop keystrokes. Resizing either device cannot affect the other.

## Start

```bash
pi-shared [name]          # create or attach a persistent tmux session
pi-shared new <name>      # start another independently rendered session
pi-shared list            # list active sessions and ports
pi-shared qr [name]       # scan once to open and sign in on the phone
pi-shared url [name]      # print a session's Tailscale-only browser URL
pi-shared token           # manual login fallback
```

Run `pi-shared qr` and scan the terminal with a phone connected to the same Tailscale network. The QR contains a random one-time pairing code—not the long-lived access token—and expires after two minutes. The browser exchanges it for an HttpOnly, same-site session cookie and immediately removes the pairing code from its address.

Detach the laptop with `Ctrl-B`, then `D`. Pi and the mobile renderer continue running inside tmux. Reattach with:

```bash
pi-shared
```

A plain Pi process can expose the same interface without the wrapper:

```bash
pi --remote
```

Or start and stop it inside an existing Pi process:

```text
/remote start
/remote status
/remote stop
```

If that process started before the Pi Remote extension was installed, run `/reload` once before `/remote start`. This exposes the existing process immediately, but it remains tied to its original terminal.

To move a legacy session into persistent tmux, first run `/quit` in the old Pi. Then run this once from the shell:

```bash
pi-shared migrate                 # reopen the newest Pi session remotely
pi-shared migrate <session-id>    # choose a specific session when needed
```

Migration refuses to reopen a session file while its old Pi process is still running.

## Core controls

- Restore active-branch history
- Stream assistant text
- Inspect compact tool activity
- Send immediately while idle
- Queue a steering message or follow-up while Pi works
- Abort the active run
- Preserve reading position when scrolling away from live output

## Security boundary

- The server binds to `PI_REMOTE_HOST` (the configured Tailscale IP).
- NixOS opens the port only on `tailscale0`.
- A random 256-bit token is stored in `~/.local/share/pi-remote/config.json` with mode `0600`.
- State-changing requests require same-origin JSON requests and a same-site HttpOnly cookie.

Pi Remote supports up to 16 active sessions on ports `6767–6782`. Each process remains isolated; the browser sidebar performs a full navigation when switching endpoints, and the host-scoped authentication cookie remains valid across the port range.
