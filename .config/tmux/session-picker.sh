#!/usr/bin/env bash
# Custom tmux session picker. Each row is "<emoji> (N) + <name>[ (attached)]".
set -euo pipefail

EMOJI="$HOME/.config/tmux/session-emoji.sh"

mapfile -t names    < <(tmux list-sessions -F '#{session_name}')
mapfile -t attached < <(tmux list-sessions -F '#{?session_attached,1,0}')

lines=()
for i in "${!names[@]}"; do
  name="${names[$i]}"
  emoji=$("$EMOJI" "$name")
  suffix=""
  [[ "${attached[$i]}" == "1" ]] && suffix=" (attached)"
  lines+=("$(printf '%s (%d) + %s%s' "$emoji" "$i" "$name" "$suffix")")
done

selected=$(printf '%s\n' "${lines[@]}" \
  | fzf --reverse --header 'switch session' \
        --preview 'tmux capture-pane -pt $(echo {} | awk "{print \$4}")') || exit 0

[[ -z "$selected" ]] && exit 0
name=$(printf '%s' "$selected" | awk '{print $4}')
tmux switch-client -t "$name"
