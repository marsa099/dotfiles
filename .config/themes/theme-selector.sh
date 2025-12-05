#!/usr/bin/env bash
#
# Interactive theme selector using Rofi
# Usage: theme-selector.sh
#
# This script presents a visual menu for theme selection

set -euo pipefail

THEMES_DIR="${HOME}/.config/themes"
CURRENT_THEME_FILE="${THEMES_DIR}/current-theme"

# Get current theme if it exists
CURRENT_THEME=""
if [[ -f "${CURRENT_THEME_FILE}" ]]; then
  CURRENT_THEME=$(cat "${CURRENT_THEME_FILE}")
fi

# Get list of available themes
THEMES=()
while IFS= read -r theme_file; do
  theme_name=$(basename "${theme_file}" .yaml)
  if [[ "${theme_name}" == "${CURRENT_THEME}" ]]; then
    # Mark current theme
    THEMES+=("● ${theme_name}")
  else
    THEMES+=("  ${theme_name}")
  fi
done < <(find "${THEMES_DIR}/definitions" -name "*.yaml" -type f | sort)

# Check if themes exist
if [[ ${#THEMES[@]} -eq 0 ]]; then
  notify-send "Theme Selector" "No themes found in ${THEMES_DIR}/definitions" -t 3000
  exit 1
fi

# Show rofi menu
selected=$(printf '%s\n' "${THEMES[@]}" | rofi -dmenu -i -p "Select Theme" \
  -theme-str 'window {width: 30%;}' \
  -theme-str 'listview {lines: 10;}')

# Exit if nothing selected
if [[ -z "${selected}" ]]; then
  exit 0
fi

# Clean up selection (remove marker)
selected="${selected#● }"
selected="${selected#  }"

# Apply the selected theme
"${THEMES_DIR}/apply-theme.sh" "${selected}"

# Send notification
notify-send "Theme Applied" "Switched to: ${selected}" -t 2000