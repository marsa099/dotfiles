#!/bin/bash

# PermissionRequest hook: saves tool info, state, and sends desktop notification
# This fires IMMEDIATELY when Claude requests permission, bypassing the ~8s delay
# of the Notification hook. Only ONE notification is visible at a time (the active
# one). Additional permissions update the "+N more pending" count on the active.
#
# Supports both tmux and direct terminal (non-tmux) instances.
# Requires: jq, dunstify, niri. Optional: tmux, wtype

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_DIR="/tmp/claude-permissions"
ICON="$HOME/.config/claude/icons/claude-code.png"

mkdir -p "$STATE_DIR"

# Read tool info from stdin
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Compute instance ID
if [ -n "$TMUX_PANE" ]; then
    INSTANCE_ID="${TMUX_PANE#%}"
else
    pts_num=$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' | grep -oP 'pts/\K\d+')
    [ -n "$pts_num" ] && INSTANCE_ID="d${pts_num}" || exit 0
fi

# Save tool info for navigate script
echo "$INPUT" | jq -c '{tool_name: .tool_name, tool_input: .tool_input}' \
    > "$STATE_DIR/tool-info-${INSTANCE_ID}.json" 2>/dev/null

echo "$(ts) [permission-request] tool=$TOOL_NAME id=$INSTANCE_ID" >> "$LOG"

# Determine instance type and label
if [ -n "$TMUX_PANE" ]; then
    INSTANCE_TYPE="tmux"
    PANE="$TMUX_PANE"
    SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
    WINDOW_IDX=$(tmux display-message -t "$PANE" -p '#{window_index}' 2>/dev/null)
    LABEL="${SESSION:-claude}:${WINDOW_IDX}"
else
    INSTANCE_TYPE="direct"
    PANE=""
    CWD_NAME=$(basename "$PWD" 2>/dev/null)
    LABEL="${CWD_NAME:-direct}"
fi

# Find niri window ID for this terminal
find_terminal_window() {
    local windows
    windows=$(niri msg windows 2>/dev/null)
    local pid=$$
    while [ "$pid" != "1" ] && [ -n "$pid" ] && [ "$pid" != "0" ]; do
        local wid
        wid=$(echo "$windows" | awk -v p="$pid" '
            /^Window ID/ { id = $3; sub(/:$/, "", id) }
            /PID:/ && $2 == p { print id; exit }
        ')
        if [ -n "$wid" ]; then
            echo "$wid"
            return 0
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
    return 1
}

TERMINAL_WID=""
[ "$INSTANCE_TYPE" = "direct" ] && TERMINAL_WID=$(find_terminal_window)

# Save state for respond/navigate scripts
{
    printf 'instance_type=%s\n' "$INSTANCE_TYPE"
    printf 'label=%s\n' "$LABEL"
    printf 'prompt_type=%s\n' "permission"
    [ "$INSTANCE_TYPE" = "tmux" ] && printf 'pane=%s\nsession=%s\n' "$PANE" "$SESSION"
    [ "$INSTANCE_TYPE" = "direct" ] && printf 'window_id=%s\n' "$TERMINAL_WID"
} > "$STATE_DIR/$INSTANCE_ID"
echo "$(ts) [permission-request] saved state: id=$INSTANCE_ID type=$INSTANCE_TYPE" >> "$LOG"

# Build notification body from a tool-info file
build_body() {
    local id="$1"
    local info="$STATE_DIR/tool-info-${id}.json"
    local tn="" tc="" tf="" td="" tp="" tpt="" ts=""
    if [ -f "$info" ]; then
        tn=$(jq -r '.tool_name // empty' "$info" 2>/dev/null)
        tc=$(jq -r '.tool_input.command // empty' "$info" 2>/dev/null)
        tf=$(jq -r '.tool_input.file_path // empty' "$info" 2>/dev/null)
        td=$(jq -r '.tool_input.description // empty' "$info" 2>/dev/null)
        tp=$(jq -r '.tool_input.pattern // empty' "$info" 2>/dev/null)
        tpt=$(jq -r '.tool_input.prompt // empty' "$info" 2>/dev/null)
        ts=$(jq -r '.tool_input.subagent_type // empty' "$info" 2>/dev/null)
    fi
    tc="${tc//\\/\\\\}"; tf="${tf//\\/\\\\}"; td="${td//\\/\\\\}"
    tp="${tp//\\/\\\\}"; tpt="${tpt//\\/\\\\}"
    [ -n "$tc" ] && [ ${#tc} -gt 200 ] && tc="${tc:0:200}..."
    local b
    if [ -n "$ts" ]; then b="<b>${tn:-Tool}</b> (${ts})"; else b="<b>${tn:-Tool}</b>"; fi
    [ -n "$tc" ] && b="$b\n<tt>$tc</tt>"
    [ -n "$tf" ] && b="$b\n$tf"
    [ -n "$tp" ] && b="$b\nPattern: $tp"
    [ -n "$td" ] && b="$b\n<i>$td</i>"
    if [ -n "$tpt" ]; then
        local trunc="${tpt:0:200}"
        [ ${#tpt} -gt 200 ] && trunc="${trunc}..."
        b="$b\n${trunc}"
    fi
    echo "$b"
}

# Build full notification with keybindings and pending count
build_full_notification() {
    local id="$1"
    local body
    body=$(build_body "$id")
    body="$body\n\nAllow <b>(Ctrl+Super+Y)</b>\nAlways Allow <b>(Ctrl+Super+A)</b>\nDeny <b>(Ctrl+Super+N)</b>\nNext <b>(Ctrl+Super+P)</b>\nGo to <b>(Ctrl+Super+O)</b>"
    local total
    total=$(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '*-*' ! -name '*.json' 2>/dev/null | wc -l)
    local extra=$((total - 1))
    [ "$extra" -gt 0 ] && body="$body\n\n<i>+${extra} more pending</i>"
    echo "$body"
}

echo "$(ts) [permission-request] notification: tool=$TOOL_NAME" >> "$LOG"

# Check if this terminal is focused
is_terminal_focused() {
    local focused_wid
    focused_wid=$(niri msg focused-window 2>/dev/null | awk '/^Window ID/ {print $3; exit}' | tr -d ':')
    [ -z "$focused_wid" ] && return 1
    local start_pid=$$
    [ -n "$TMUX" ] && start_pid=$(tmux display-message -p '#{client_pid}' 2>/dev/null)
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

# Check pane visibility (tmux only)
PANE_VISIBLE=false
if [ "$INSTANCE_TYPE" = "tmux" ] && [ -n "$PANE" ]; then
    CLIENT_ACTIVE_PANE=$(tmux list-clients -F '#{pane_id}' 2>/dev/null | head -1)
    [ "$CLIENT_ACTIVE_PANE" = "$PANE" ] && PANE_VISIBLE=true
else
    PANE_VISIBLE=true
fi

# Send/update notification if terminal is not focused
if is_terminal_focused && [ "$PANE_VISIBLE" = true ]; then
    echo "$(ts) [permission-request] skipped notification: terminal focused" >> "$LOG"
else
    if [ ! -f "$STATE_DIR/.last-navigate" ]; then
        # First notification: create active, show this instance
        BODY=$(build_full_notification "$INSTANCE_ID")
        REPLACE_ID_FILE="$STATE_DIR/notif-id-${INSTANCE_ID}"
        REPLACE_ARGS=()
        if [ -f "$REPLACE_ID_FILE" ]; then
            old_id=$(cat "$REPLACE_ID_FILE")
            [ -n "$old_id" ] && REPLACE_ARGS=(-r "$old_id")
        fi
        NOTIF_ID=$(dunstify "> Claude - $LABEL" "$BODY" \
            "${REPLACE_ARGS[@]}" \
            -I "$ICON" -u critical -t 0 -p 2>>"$LOG")
        echo "$INSTANCE_ID" > "$STATE_DIR/.last-navigate"
        [ -n "$NOTIF_ID" ] && echo "$NOTIF_ID" > "$REPLACE_ID_FILE"
        echo "$(ts) [permission-request] created active notification id='$NOTIF_ID'" >> "$LOG"
    else
        # Additional: update the active notification's pending count
        ACTIVE_ID=$(cat "$STATE_DIR/.last-navigate")
        ACTIVE_LABEL=$(grep '^label=' "$STATE_DIR/$ACTIVE_ID" 2>/dev/null | cut -d= -f2)
        [ -z "$ACTIVE_LABEL" ] && ACTIVE_LABEL="claude:?"
        BODY=$(build_full_notification "$ACTIVE_ID")
        REPLACE_ID_FILE="$STATE_DIR/notif-id-${ACTIVE_ID}"
        REPLACE_ARGS=()
        if [ -f "$REPLACE_ID_FILE" ]; then
            old_id=$(cat "$REPLACE_ID_FILE")
            [ -n "$old_id" ] && REPLACE_ARGS=(-r "$old_id")
        fi
        NOTIF_ID=$(dunstify "> Claude - $ACTIVE_LABEL" "$BODY" \
            "${REPLACE_ARGS[@]}" \
            -I "$ICON" -u critical -t 0 -p 2>>"$LOG")
        [ -n "$NOTIF_ID" ] && echo "$NOTIF_ID" > "$REPLACE_ID_FILE"
        echo "$(ts) [permission-request] updated active count id='$NOTIF_ID' active=$ACTIVE_ID" >> "$LOG"
    fi
fi
