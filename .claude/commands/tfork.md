---
description: Fork conversation into a new kitty terminal window (original stays here). Optional arg = window title + session name.
argument-hint: [name]
allowed-tools: Bash
---

Fork this conversation into a new kitty terminal window via the Bash tool. The original session stays untouched.

Argument from the user: `$ARGUMENTS`

The `-d "$(jq …)"` part below resolves the session's original project directory from its JSONL transcript, so the forked claude can locate the session even if the calling shell has cd'd elsewhere mid-conversation.

Behavior:
- **If the argument is non-empty**, use it (verbatim) as both the kitty window title AND the forked claude session's `--name`. Run:
  ```
  kitty --detach -d "$(jq -r 'select(.cwd) | .cwd' ~/.claude/projects/*/${CLAUDE_SESSION_ID}.jsonl 2>/dev/null | head -1)" -T "<ARG>" claude --resume '${CLAUDE_SESSION_ID}' --fork-session --name '<ARG>'
  ```
  Replace `<ARG>` with the actual argument text. Quote it properly so spaces are preserved.
- **If the argument is empty**, default the title to `claude` and omit `--name`:
  ```
  kitty --detach -d "$(jq -r 'select(.cwd) | .cwd' ~/.claude/projects/*/${CLAUDE_SESSION_ID}.jsonl 2>/dev/null | head -1)" -T claude claude --resume '${CLAUDE_SESSION_ID}' --fork-session
  ```

Do not modify the session id. After running, reply with ONE short sentence confirming the fork (mention the name if provided), or report bash errors verbatim.
