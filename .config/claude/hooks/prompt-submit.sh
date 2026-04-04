#!/bin/bash

# Claude Code UserPromptSubmit Hook
# Triggers when user submits a prompt to Claude

LOG="$HOME/.cache/claude/hooks.log"

echo "$(date '+%Y-%m-%dT%H:%M:%S.%3N') [submit] Prompt submitted" >> "$LOG"

if [ -n "$TMUX" ]; then
    printf '\033]2;Claude: Processing... 🤔\033\\'
fi

dunstify "" --stack-tag claude-prompt -t 1 2>/dev/null
