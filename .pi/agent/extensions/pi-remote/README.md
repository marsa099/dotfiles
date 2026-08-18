# Pi Remote

Pi Remote keeps Pi's native laptop TUI and gives the phone a separate browser renderer for the same live session.

```text
Pi AgentSession
├─ Pi TUI → laptop terminal
└─ semantic events → authenticated HTTP/SSE → phone browser
                         phone actions → sendUserMessage / abort
```

The phone never receives ANSI bytes, terminal dimensions, or laptop keystrokes. Resizing either device cannot affect the other.

## Start

```bash
pi-shared                 # create or attach the persistent tmux session
pi-shared url             # print the Tailscale-only browser URL
pi-shared token           # print the private browser login token
```

Open the URL on a phone connected to the same Tailscale network and enter the token once. The browser keeps an HttpOnly, same-site session cookie.

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

The first version supports one remotely exposed Pi process on the configured port.
