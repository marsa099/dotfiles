#!/bin/bash

# Claude Code Notification Hook - fallback for all notification types
# - If a styled permission notification already exists for this instance, leave it alone
#   (unless the message indicates Claude moved on, i.e. "waiting for your input")
# - Otherwise send a generic notification if terminal is not focused

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
ICON="$HOME/.config/claude/icons/claude-code.png"
STATE_DIR="/tmp/claude-permissions"

INPUT=$(cat)
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs attention"')

echo "$(ts) [notification-hook] title='$TITLE' message='$MESSAGE'" >> "$LOG"

# Compute instance ID (same as permission-save-tool.sh)
if [ -n "$TMUX_PANE" ]; then
    ID="${TMUX_PANE#%}"
else
    pts_num=$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' | grep -oP 'pts/\K\d+')
    [ -n "$pts_num" ] && ID="d${pts_num}" || ID=""
fi

# Check if a permission notification is active for this instance
HAS_ACTIVE_PERMISSION=false
if [ -n "$ID" ] && [ -f "$STATE_DIR/$ID" ]; then
    HAS_ACTIVE_PERMISSION=true
fi

# If permission still pending, don't touch the styled notification
if [ "$HAS_ACTIVE_PERMISSION" = true ]; then
    case "$MESSAGE" in
        *"waiting for your input"*)
            # Claude moved on (user denied or tool finished) — clean up stale notification
            NID_FILE="$STATE_DIR/notif-id-${ID}"
            if [ -f "$NID_FILE" ]; then
                nid_val=$(cat "$NID_FILE")
                [ -n "$nid_val" ] && dunstify -C "$nid_val" 2>/dev/null
                echo "$(ts) [notification-hook] cleaned stale notification id=$nid_val for instance=$ID" >> "$LOG"
            fi
            rm -f "$STATE_DIR/$ID" "$STATE_DIR/tool-info-${ID}.json" "$NID_FILE"
            NAV="$STATE_DIR/.last-navigate"
            if [ -f "$NAV" ]; then
                nav_val=$(cat "$NAV")
                if [ "$nav_val" = "$ID" ] || [ -z "$(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '*-*' ! -name '*.json' 2>/dev/null)" ]; then
                    rm -f "$NAV"
                fi
            fi
            ;;
        *)
            # Permission still pending — styled notification is already showing
            echo "$(ts) [notification-hook] skipped: permission notification active for instance=$ID" >> "$LOG"
            exit 0
            ;;
    esac
fi

# Check if this terminal is focused
is_terminal_focused() {
    local focused_wid
    focused_wid=$(niri msg focused-window 2>/dev/null | awk '/^Window ID/ {print $3; exit}' | tr -d ':')
    [ -z "$focused_wid" ] && return 1
    local start_pid=$$
    if [ -n "$TMUX" ]; then
        start_pid=$(tmux display-message -t "${TMUX_PANE:-}" -p '#{client_pid}' 2>/dev/null)
    fi
    [ -z "$start_pid" ] && return 1
    local windows
    windows=$(niri msg windows 2>/dev/null)
    local pid=$start_pid
    while [ "$pid" != "1" ] && [ -n "$pid" ] && [ "$pid" != "0" ]; do
        local wid
        wid=$(echo "$windows" | awk -v p="$pid" '
            /^Window ID/ { id = $3; sub(/:$/, "", id) }
            /PID:/ && $2 == p { print id; exit }
        ')
        if [ -n "$wid" ]; then
            [ "$wid" = "$focused_wid" ] && return 0
            return 1
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
    return 1
}

# Check pane visibility for tmux
PANE_VISIBLE=false
if [ -n "$TMUX_PANE" ]; then
    SESSION=$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}' 2>/dev/null)
    CLIENT_ACTIVE_PANE=$(tmux list-clients -t "$SESSION" -F '#{pane_id}' 2>/dev/null | head -1)
    [ "$CLIENT_ACTIVE_PANE" = "$TMUX_PANE" ] && PANE_VISIBLE=true
else
    PANE_VISIBLE=true
fi

if is_terminal_focused && [ "$PANE_VISIBLE" = true ]; then
    echo "$(ts) [notification-hook] skipped: terminal focused" >> "$LOG"
else
    dunstify "$TITLE" "$MESSAGE" \
        -u normal -I "$ICON"
    echo "$(ts) [notification-hook] sent notification" >> "$LOG"
fi
