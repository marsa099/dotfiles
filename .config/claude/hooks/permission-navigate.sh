#!/bin/bash

# Claude Code Permission Navigate (multi-instance)
# Called by niri keybinding to cycle through pending permission prompts
# Only ONE notification is visible at a time — cycles which one is shown
#
# Usage: permission-navigate.sh

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_DIR="/tmp/claude-permissions"
ICON="$HOME/.config/claude/icons/claude-code.png"
LAST_NAV_FILE="$STATE_DIR/.last-navigate"

# Get pending instance IDs sorted oldest first
mapfile -t PANES < <(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '*-*' ! -name '*.json' -printf '%T@ %f\n' 2>/dev/null | sort -n | awk '{print $2}')

if [ ${#PANES[@]} -eq 0 ]; then
    dunstify "Claude Code" "No pending permissions" \
        --stack-tag claude-nav -I "$ICON" -u low -t 3000
    echo "$(ts) [navigate] no pending permissions" >> "$LOG"
    exit 0
fi

# Determine target: cycle from current selection
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

# Close ALL existing notifications
for pane_num in "${PANES[@]}"; do
    old_id_file="$STATE_DIR/notif-id-${pane_num}"
    if [ -f "$old_id_file" ]; then
        old_id=$(cat "$old_id_file")
        [ -n "$old_id" ] && dunstify -C "$old_id" 2>/dev/null
        rm -f "$old_id_file"
    fi
done

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
    _esc() { local s="${1//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"; echo "$s"; }
    tool_cmd=$(_esc "$tool_cmd"); tool_file=$(_esc "$tool_file")
    tool_desc=$(_esc "$tool_desc"); tool_pattern=$(_esc "$tool_pattern")
    tool_prompt=$(_esc "$tool_prompt")
    [ -n "$tool_cmd" ] && [ ${#tool_cmd} -gt 200 ] && tool_cmd="${tool_cmd:0:200}..."
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

# Show only the target notification
local_state="$STATE_DIR/$TARGET"
label=$(grep '^label=' "$local_state" 2>/dev/null | cut -d= -f2)
[ -z "$label" ] && label="claude:?"
prompt_type=$(grep '^prompt_type=' "$local_state" 2>/dev/null | cut -d= -f2)

body=$(build_body "$TARGET")
if [ "$prompt_type" = "yesno" ]; then
    body="$body\n\nYes <b>(Ctrl+Super+Y)</b>\nNo <b>(Ctrl+Super+N)</b>\nNext <b>(Ctrl+Super+P)</b>\nGo to <b>(Ctrl+Super+O)</b>"
else
    body="$body\n\nAllow <b>(Ctrl+Super+Y)</b>\nAlways Allow <b>(Ctrl+Super+A)</b>\nDeny <b>(Ctrl+Super+N)</b>\nNext <b>(Ctrl+Super+P)</b>\nGo to <b>(Ctrl+Super+O)</b>"
fi

# Add pending count
EXTRA=$(( ${#PANES[@]} - 1 ))
[ "$EXTRA" -gt 0 ] && body="$body\n\n<i>+${EXTRA} more pending</i>"

notif_id=$(dunstify "> Claude - $label" "$body" \
    -I "$ICON" -u critical -t 0 -p 2>>"$LOG")
[ -n "$notif_id" ] && echo "$notif_id" > "$STATE_DIR/notif-id-${TARGET}"

echo "$(ts) [navigate] selected target=$TARGET (${#PANES[@]} pending) id='$notif_id'" >> "$LOG"
