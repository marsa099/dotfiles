#!/bin/bash

# Claude Code Stop Hook - Desktop Notification & tmux Integration
# Triggers when Claude finishes responding and waits for input
# Features:
#   - Updates tmux pane title to show "Waiting for input" state
#   - Sends bell character to trigger tmux bell monitoring
#   - Sends desktop notification

# Default title fallback
CONVERSATION_TITLE="Claude Code"

# Try to get the conversation title from tmux pane title
if [ -n "$TMUX" ]; then
    TMUX_TITLE=$(tmux display-message -p '#{pane_title}' 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$TMUX_TITLE" ]; then
        CONVERSATION_TITLE="$TMUX_TITLE"
    fi

    # Update tmux pane title to show "waiting" state
    printf '\033]2;Claude: Waiting for input ⌨\033\\'

    # Send bell character to trigger tmux bell monitoring
    # This will show the bell icon (󰂞) in the window status bar
    printf '\a'
fi

# Send desktop notification
dunstify "$CONVERSATION_TITLE" "Ready for input" -u normal -i robot
