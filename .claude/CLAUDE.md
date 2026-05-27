# Git commande
## Commit
When using git commit, keep the message short and descriptive. Syntax for commit messages should be "Fixes bug #1234". instead of "Implemented a fix for bug #1234".

IMPORTANT: Always use English for commit messages, never Swedish or other languages.

IMPORTANT: Do NOT add Claude Code attribution or co-authored-by lines to commit messages. Keep commits clean and concise.

# Code Style Rules
IMPORTANT: NEVER add trailing whitespaces after lines or whitespace-only lines. This applies to ALL projects FOREVER. When writing or editing code:
- No trailing whitespaces at the end of lines
- No lines that contain only whitespace characters
- Empty lines should be completely empty with no spaces or tabs

# Solution Approach
IMPORTANT: Always push back when the user has an idea that seems overly complex. Keep solutions as simple and maintainable as possible. If a simpler solution exists, suggest it first before implementing complex workarounds. Question whether the complexity is really needed and propose alternatives that are easier to maintain.

# Where new tools/scripts live
When the user asks for a new project, script, or tool, make a judgement call up front about where it should live — don't default to dropping everything in `~/.scripts/`:

- **`~/.scripts/`** — short shell/python helpers, single file, < ~50 lines, no state, no external deps. Dotfile-tracked. E.g. wifi helpers, waybar scripts.
- **`~/repos/<name>/` as its own git repo** — anything multi-file, with persisted state, configurable, or that could plausibly be packaged. ~100+ lines is a strong signal. Mention to the user when you make this call so they can `gh repo create` and wire it as a `nixpkgs` flake input later (precedents: `bt-keyboard-bridge`, `claude-code-notify`).

Surface the decision: "this is N lines / multi-component, I'm putting it in `~/repos/<name>/` instead of `~/.scripts/` — say if you'd rather keep it inline." Don't ask permission — make the call, state it, let the user redirect.
