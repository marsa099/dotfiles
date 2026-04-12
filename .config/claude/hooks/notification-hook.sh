#!/bin/bash

# Claude Code Notification Hook - handles idle_prompt notifications only
# Permission prompts are handled by the PermissionRequest hook (permission-save-tool.sh)
# for instant delivery, bypassing the ~8s Notification delay bug.

ICON="$HOME/.config/claude/icons/claude-code.svg"

INPUT=$(cat)
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs attention"')

dunstify "$TITLE" "$MESSAGE" \
    -u normal -I "$ICON"
