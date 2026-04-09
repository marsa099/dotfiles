#!/bin/bash

# Claude Code UserPromptSubmit Hook
# Triggers when user submits a prompt to Claude

LOG="$HOME/.cache/claude/hooks.log"
STATE_DIR="/tmp/claude-permissions"

if [ -n "$TMUX_PANE" ]; then
    INSTANCE_ID="${TMUX_PANE#%}"
else
    INSTANCE_ID="d$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' | grep -oP 'pts/\K\d+')"
    [ "$INSTANCE_ID" = "d" ] && INSTANCE_ID=""
fi

echo "$(date '+%Y-%m-%dT%H:%M:%S.%3N') [submit] Prompt submitted" >> "$LOG"

# Clean up any pending permission state for this instance
if [ -n "$INSTANCE_ID" ]; then
    [ -f "$STATE_DIR/notif-id-${INSTANCE_ID}" ] && dunstify -C "$(cat "$STATE_DIR/notif-id-${INSTANCE_ID}")" 2>/dev/null
    rm -f "$STATE_DIR/$INSTANCE_ID" "$STATE_DIR/tool-info-${INSTANCE_ID}.json" "$STATE_DIR/notif-id-${INSTANCE_ID}"
fi

if [ -n "$TMUX" ]; then
    printf '\033]2;Claude: Processing... \xf0\x9f\xa4\x94\033\\'
fi

if [ -n "$INSTANCE_ID" ]; then
    [ -f "$STATE_DIR/stop-notif-id-${INSTANCE_ID}" ] && dunstify -C "$(cat "$STATE_DIR/stop-notif-id-${INSTANCE_ID}")" 2>/dev/null
    rm -f "$STATE_DIR/stop-notif-id-${INSTANCE_ID}"
fi
