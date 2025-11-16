#!/bin/bash

# Claude Code Stop Hook - Desktop Notification
# Sends a notification when Claude finishes responding

# Default title fallback
CONVERSATION_TITLE="Claude Code"

# Try to get the conversation title from tmux pane title
if [ -n "$TMUX" ]; then
    TMUX_TITLE=$(tmux display-message -p '#{pane_title}' 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$TMUX_TITLE" ]; then
        CONVERSATION_TITLE="$TMUX_TITLE"
    fi
fi

# Send desktop notification
dunstify "$CONVERSATION_TITLE" "Ready for input" -u normal -i robot
