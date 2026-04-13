#!/bin/bash

# Claude Code Permission Navigate (multi-instance)
# Called by niri keybinding to cycle through pending permission notifications
# Only updates notification visuals and saves selection — does NOT focus terminal
#
# Usage: permission-navigate.sh

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_DIR="/tmp/claude-permissions"
ICON="$HOME/.config/claude/icons/claude-code.svg"
LAST_NAV_FILE="$STATE_DIR/.last-navigate"

# Get pending instance IDs sorted by most recent first
mapfile -t PANES < <(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '*-*' ! -name '*.json' -printf '%T@ %f\n' 2>/dev/null | sort -n | awk '{print $2}')

if [ ${#PANES[@]} -eq 0 ]; then
    dunstify "Claude Code" "No pending permissions" \
        --stack-tag claude-nav -u low -t 3000
    echo "$(ts) [navigate] no pending permissions" >> "$LOG"
    exit 0
fi

# Determine target: cycle if already navigated, otherwise most recent
LAST_NAV=$(cat "$LAST_NAV_FILE" 2>/dev/null)
TARGET="${PANES[0]}"

if [ -n "$LAST_NAV" ]; then
    for i in "${!PANES[@]}"; do
        if [ "${PANES[$i]}" = "$LAST_NAV" ]; then
            NEXT_IDX=$(( (i + 1) % ${#PANES[@]} ))
            TARGET="${PANES[$NEXT_IDX]}"
            break
        fi
    done
fi

echo "$TARGET" > "$LAST_NAV_FILE"

# Build notification body from tool-info
build_body() {
    local pane_num="$1"
    local info_file="$STATE_DIR/tool-info-${pane_num}.json"
    local tool_name="" tool_cmd="" tool_file="" tool_desc="" tool_pattern="" tool_prompt="" tool_subtype=""

    if [ -f "$info_file" ]; then
        tool_name=$(jq -r '.tool_name // empty' "$info_file" 2>/dev/null)
        tool_cmd=$(jq -r '.tool_input.command // empty' "$info_file" 2>/dev/null)
        tool_file=$(jq -r '.tool_input.file_path // empty' "$info_file" 2>/dev/null)
        tool_desc=$(jq -r '.tool_input.description // empty' "$info_file" 2>/dev/null)
        tool_pattern=$(jq -r '.tool_input.pattern // empty' "$info_file" 2>/dev/null)
        tool_prompt=$(jq -r '.tool_input.prompt // empty' "$info_file" 2>/dev/null)
        tool_subtype=$(jq -r '.tool_input.subagent_type // empty' "$info_file" 2>/dev/null)
    fi

    local body
    if [ -n "$tool_subtype" ]; then
        body="<b>${tool_name:-Tool}</b> (${tool_subtype})"
    else
        body="<b>${tool_name:-Tool}</b>"
    fi
    [ -n "$tool_cmd" ] && body="$body\n<tt>$tool_cmd</tt>"
    [ -n "$tool_file" ] && body="$body\n$tool_file"
    [ -n "$tool_pattern" ] && body="$body\nPattern: $tool_pattern"
    [ -n "$tool_desc" ] && body="$body\n<i>$tool_desc</i>"
    if [ -n "$tool_prompt" ]; then
        local truncated="${tool_prompt:0:200}"
        [ ${#tool_prompt} -gt 200 ] && truncated="${truncated}..."
        body="$body\n${truncated}"
    fi

    echo "$body"
}

# Re-render all notifications: highlight selected, dim others
for pane_num in "${PANES[@]}"; do
    local_state="$STATE_DIR/$pane_num"
    label=$(grep '^label=' "$local_state" 2>/dev/null | cut -d= -f2)
    [ -z "$label" ] && label="claude:?"
    prompt_type=$(grep '^prompt_type=' "$local_state" 2>/dev/null | cut -d= -f2)
    body=$(build_body "$pane_num")

    # Replace existing notification atomically (avoids close+create race)
    old_id_file="$STATE_DIR/notif-id-${pane_num}"
    REPLACE_ARGS=()
    if [ -f "$old_id_file" ]; then
        old_id=$(cat "$old_id_file")
        [ -n "$old_id" ] && REPLACE_ARGS=(-r "$old_id")
    fi

    if [ "$pane_num" = "$TARGET" ]; then
        # Selected: accent border, full keybindings
        if [ "$prompt_type" = "yesno" ]; then
            body="$body\n\nYes <b>(Ctrl+Super+Y)</b>\nNo <b>(Ctrl+Super+N)</b>\nNext <b>(Ctrl+Super+P)</b>"
        else
            body="$body\n\nAllow <b>(Ctrl+Super+Y)</b>\nAlways Allow <b>(Ctrl+Super+A)</b>\nDeny <b>(Ctrl+Super+N)</b>\nNext <b>(Ctrl+Super+P)</b>"
        fi
        notif_id=$(dunstify "> Claude - $label" "$body" \
            "${REPLACE_ARGS[@]}" \
            -u critical -t 0 -p 2>>"$LOG")
        echo "$(ts) [navigate] dunstify selected pane=$pane_num id='$notif_id' replace='${REPLACE_ARGS[*]}' exit=$?" >> "$LOG"
    else
        # Non-selected: muted text, gray border
        body="<span foreground='#616e88'>$body</span>"
        notif_id=$(dunstify "Claude - $label" "$body" \
            "${REPLACE_ARGS[@]}" \
            -u critical -t 0 -p 2>>"$LOG")
        echo "$(ts) [navigate] dunstify other pane=$pane_num id='$notif_id' replace='${REPLACE_ARGS[*]}' exit=$?" >> "$LOG"
    fi
    [ -n "$notif_id" ] && echo "$notif_id" > "$STATE_DIR/notif-id-${pane_num}"
done

echo "$(ts) [navigate] selected target=$TARGET (${#PANES[@]} pending)" >> "$LOG"
