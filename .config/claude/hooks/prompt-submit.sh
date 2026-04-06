#!/bin/bash

# Claude Code UserPromptSubmit Hook
# Triggers when user submits a prompt to Claude

LOG="$HOME/.cache/claude/hooks.log"
STATE_DIR="/tmp/claude-permissions"
PANE_NUM="${TMUX_PANE#%}"

echo "$(date '+%Y-%m-%dT%H:%M:%S.%3N') [submit] Prompt submitted" >> "$LOG"

# Clean up any pending permission state for this pane
if [ -n "$PANE_NUM" ]; then
    [ -f "$STATE_DIR/$PANE_NUM" ] && dunstify "" --stack-tag "claude-perm-$PANE_NUM" -t 1 2>/dev/null
    rm -f "$STATE_DIR/$PANE_NUM" "$STATE_DIR/tool-info-${PANE_NUM}.json"
fi

if [ -n "$TMUX" ]; then
    printf '\033]2;Claude: Processing... 🤔\033\\'
fi

dunstify "" --stack-tag "claude-stop-$PANE_NUM" -t 1 2>/dev/null
