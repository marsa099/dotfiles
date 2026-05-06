---
description: Fork conversation into a new tmux window (original stays here). Optional arg = window + session name.
argument-hint: [name]
allowed-tools: Bash(tmux:*)
---

Fork this conversation into a new tmux window via the Bash tool. The original session stays untouched.

Argument from the user: `$ARGUMENTS`

Behavior:
- **If the argument is non-empty**, use it (verbatim) as both the tmux window name AND the forked claude session's `--name`. Run:
  ```
  tmux new-window -n "<ARG>" "claude --resume '${CLAUDE_SESSION_ID}' --fork-session --name '<ARG>'"
  ```
  Replace `<ARG>` with the actual argument text. Quote it properly so spaces are preserved.
- **If the argument is empty**, default the window name to `claude` and omit `--name`:
  ```
  tmux new-window -n claude "claude --resume '${CLAUDE_SESSION_ID}' --fork-session"
  ```

Do not modify the session id. After running, reply with ONE short sentence confirming the fork (mention the name if provided), or report bash errors verbatim.
