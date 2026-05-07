#!/usr/bin/env bash
# Open todo.md in the current pane's directory inside an nvim popup.
# Creates the file from a small template if it doesn't exist.
set -euo pipefail

file="todo.md"

if [[ ! -e "$file" ]]; then
  cat > "$file" <<'EOF'
# Todo

- [ ]
EOF
fi

exec nvim \
  -c "lua require('todo-popup').setup_buffer()" \
  "$file"
