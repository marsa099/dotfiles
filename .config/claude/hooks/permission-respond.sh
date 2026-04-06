#!/bin/bash

# Claude Code Permission Response (multi-instance)
# Called by niri global keybindings to respond to the most recent permission prompt
# Sends keystroke to Claude Code's tmux pane without changing focus
#
# Usage: permission-respond.sh <1|2|3>
#   1 = Allow, 2 = Always Allow, 3 = Deny

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_DIR="/tmp/claude-permissions"
ICON="$HOME/.config/claude/icons/claude-code.svg"
KEY="$1"

if [ -z "$KEY" ]; then
    echo "$(ts) [respond] error: no key argument" >> "$LOG"
    exit 1
fi

# Find the most recent pending permission (by modification time)
LATEST=$(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '*-*' -printf '%T@ %f\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')

if [ -z "$LATEST" ]; then
    echo "$(ts) [respond] error: no pending permissions" >> "$LOG"
    exit 1
fi

STATE_FILE="$STATE_DIR/$LATEST"
PANE=$(grep '^pane=' "$STATE_FILE" 2>/dev/null | cut -d= -f2)

if [ -z "$PANE" ]; then
    echo "$(ts) [respond] error: empty pane in state file $LATEST" >> "$LOG"
    rm -f "$STATE_FILE"
    exit 1
fi

# Remap keys for Yes/No prompts (No=2, not 3)
PROMPT_TYPE=$(grep '^prompt_type=' "$STATE_FILE" 2>/dev/null | cut -d= -f2)
SEND_KEY="$KEY"
if [ "$PROMPT_TYPE" = "yesno" ]; then
    case "$KEY" in
        2) SEND_KEY="2" ;;  # Always Allow → No
        3) SEND_KEY="2" ;;  # Deny → No
    esac
fi

tmux send-keys -t "$PANE" "$SEND_KEY" 2>>"$LOG"
RESULT=$?

# Close this instance's notification by ID (avoids flash from -t 1 replacement)
NOTIF_ID_FILE="$STATE_DIR/notif-id-${LATEST}"
[ -f "$NOTIF_ID_FILE" ] && dunstify -C "$(cat "$NOTIF_ID_FILE")" 2>/dev/null

# Clean up state
rm -f "$STATE_FILE" "$STATE_DIR/tool-info-${LATEST}.json" "$NOTIF_ID_FILE"

LABELS=("" "Allow" "Always Allow" "Deny")
YESNO_LABELS=("" "Yes" "No" "No")
if [ "$PROMPT_TYPE" = "yesno" ]; then
    echo "$(ts) [respond] sent key=$SEND_KEY (${YESNO_LABELS[$KEY]}) to pane=$PANE exit=$RESULT [yesno]" >> "$LOG"
else
    echo "$(ts) [respond] sent key=$SEND_KEY (${LABELS[$KEY]}) to pane=$PANE exit=$RESULT" >> "$LOG"
fi

# Notify if more prompts remain
REMAINING=$(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' 2>/dev/null | wc -l)
if [ "$REMAINING" -gt 0 ]; then
    dunstify "Claude Code" "${REMAINING} permission prompt(s) pending" \
        --stack-tag claude-pending-count -u normal -I "$ICON" -t 5000
    echo "$(ts) [respond] $REMAINING prompts still pending" >> "$LOG"
fi
