#!/bin/bash

# Claude Code Stop Hook
# Triggers when Claude finishes responding and waits for input

LOG="$HOME/.cache/claude/hooks.log"

echo "$(date '+%Y-%m-%dT%H:%M:%S.%3N') [stop] Claude finished" >> "$LOG"

if [ -n "$TMUX" ]; then
    printf '\033]2;Claude: Waiting for input ⌨\033\\'
    printf '\a'
fi

ICON="$HOME/.config/claude/icons/claude-code.svg"
dunstify "Claude Code" "Ready for input" \
    --stack-tag claude-prompt \
    -u normal -I "$ICON"
