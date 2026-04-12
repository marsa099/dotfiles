#!/bin/bash

# PermissionRequest hook: saves tool info, state, and sends desktop notification
# This fires IMMEDIATELY when Claude requests permission, bypassing the ~8s delay
# of the Notification hook. The navigate/respond scripts read the state files.
#
# Supports both tmux and direct terminal (non-tmux) instances.
# Requires: jq, dunstify, niri. Optional: tmux, wtype

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_DIR="/tmp/claude-permissions"
ICON="$HOME/.config/claude/icons/claude-code.svg"

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

# --- Build notification ---

# Extract tool details
TOOL_CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
TOOL_FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL_DESC=$(echo "$INPUT" | jq -r '.tool_input.description // empty')
TOOL_PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // empty')
TOOL_PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // empty')
TOOL_SUBTYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# Escape backslashes so dunst doesn't interpret sequences like \0 as null
TOOL_CMD="${TOOL_CMD//\\/\\\\}"
TOOL_FILE="${TOOL_FILE//\\/\\\\}"
TOOL_DESC="${TOOL_DESC//\\/\\\\}"
TOOL_PATTERN="${TOOL_PATTERN//\\/\\\\}"
TOOL_PROMPT="${TOOL_PROMPT//\\/\\\\}"

# Truncate long commands
if [ -n "$TOOL_CMD" ] && [ ${#TOOL_CMD} -gt 200 ]; then
    TOOL_CMD="${TOOL_CMD:0:200}..."
fi

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

# Build notification body
if [ -n "$TOOL_SUBTYPE" ]; then
    BODY="<b>${TOOL_NAME:-Tool}</b> (${TOOL_SUBTYPE})"
else
    BODY="<b>${TOOL_NAME:-Tool}</b>"
fi
[ -n "$TOOL_CMD" ] && BODY="$BODY\n<tt>$TOOL_CMD</tt>"
[ -n "$TOOL_FILE" ] && BODY="$BODY\n$TOOL_FILE"
[ -n "$TOOL_PATTERN" ] && BODY="$BODY\nPattern: $TOOL_PATTERN"
[ -n "$TOOL_DESC" ] && BODY="$BODY\n<i>$TOOL_DESC</i>"
if [ -n "$TOOL_PROMPT" ]; then
    truncated="${TOOL_PROMPT:0:200}"
    [ ${#TOOL_PROMPT} -gt 200 ] && truncated="${truncated}..."
    BODY="$BODY\n${truncated}"
fi
BODY="$BODY\n\nAllow <b>(Ctrl+Super+Y)</b>\nAlways Allow <b>(Ctrl+Super+A)</b>\nDeny <b>(Ctrl+Super+N)</b>\nGo to <b>(Ctrl+Super+P)</b>"

echo "$(ts) [permission-request] notification: tool=$TOOL_NAME cmd=\"$TOOL_CMD\" file=\"$TOOL_FILE\"" >> "$LOG"

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

# Send notification if terminal is not focused
if is_terminal_focused && [ "$PANE_VISIBLE" = true ]; then
    echo "$(ts) [permission-request] skipped notification: terminal focused" >> "$LOG"
else
    REPLACE_ID_FILE="$STATE_DIR/notif-id-${INSTANCE_ID}"
    REPLACE_ARGS=()
    [ -f "$REPLACE_ID_FILE" ] && REPLACE_ARGS=(-r "$(cat "$REPLACE_ID_FILE")")
    NOTIF_ID=$(dunstify "Claude - $LABEL" "$BODY" \
        "${REPLACE_ARGS[@]}" \
        -u critical -I "$ICON" -t 0 -p)
    echo "$NOTIF_ID" > "$REPLACE_ID_FILE"
fi
