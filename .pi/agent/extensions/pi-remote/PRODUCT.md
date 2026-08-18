# Pi Remote

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static HTML, CSS, and JavaScript served directly by the Pi extension. No frontend framework or build step.

## Users

The primary user is Martin, moving between laptop terminals and a phone browser while several Pi coding sessions may be active. The phone experience is optimized for selecting one running session, reading progress, and responding quickly when away from the laptop keyboard.

## Product Purpose

Pi Remote makes active Pi sessions reachable from laptop and phone without sharing terminal rendering. Success means each laptop session keeps Pi's normal full-width TUI while the phone can select a running session, receive its conversation, and submit input through an interface rendered for its own viewport.

## Positioning

Pi Remote transports structured session, message, and tool events rather than ANSI terminal output. Each device renders independently; neither device can change the other's layout or PTY dimensions.

## Operating Context

Each Pi process runs persistently inside its own laptop tmux session. The laptop is the only terminal client for each process. Every active session registers a separate Tailscale-only endpoint, and the phone switches between them through one session navigator. The user may detach the laptop while the Pi processes continue running.

## Capabilities and Constraints

- Discover and switch between active Pi Remote sessions.
- Show the selected session's active-branch history and authoritative completed messages.
- Stream assistant text and concise tool activity as semantic events.
- Submit prompts immediately while idle, or queue them as steering or follow-up messages while Pi works.
- Abort the active agent run.
- Report connection, working, queued, and error states clearly.
- Bind HTTP only to the configured Tailscale address and require a persistent private access token.
- Pair a phone through a short-lived, one-use QR code while retaining the access token as a manual fallback.
- Support up to 16 concurrently exposed Pi processes on a private configured port range.
- The first version does not mirror terminal bytes, synchronize drafts, provide full Pi settings/session management, or transfer image payloads.

## Brand Commitments

The product name is Pi Remote. It is an operational companion to Pi, not a simulated terminal. Language should be direct, compact, and factual.

## Evidence on Hand

The Pi SDK and extension APIs provide message lifecycle events, tool execution events, session history, abort control, pending-state inspection, and `sendUserMessage()`. No external performance, security, or reliability claims should be invented.

## Product Principles

- Preserve one source of session truth while allowing many presentation layers.
- Keep terminal geometry and input bytes out of the mobile transport.
- Make current agent state obvious before the user acts.
- Optimize the phone for reading and responding, not desktop feature parity.
- Fail closed outside the Tailscale-bound, token-authenticated path.
