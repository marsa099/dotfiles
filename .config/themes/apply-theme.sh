#!/usr/bin/env bash
#
# Main theme switcher script
# Usage: apply-theme.sh <theme-name>
#
# This script is designed to be extensible for adding more applications

set -euo pipefail

THEMES_DIR="${HOME}/.config/themes"
THEME_NAME="${1:-}"
CURRENT_THEME_FILE="${THEMES_DIR}/current-theme"

# Extension points - add apps here as you implement them
APPS_TO_THEME=(
  "waybar"
  # Future: "hyprland"
  # Future: "tmux"
  # Future: "ghostty"
  # Future: "neovim"
)

usage() {
  echo "Usage: $0 <theme-name>"
  echo ""
  echo "Available themes:"
  ls -1 "${THEMES_DIR}/definitions" 2>/dev/null | sed 's/\.yaml$//' | sed 's/^/  - /' || echo "  No themes found"
  exit 1
}

# Function to generate Waybar theme
generate_waybar() {
  local theme_file="$1"

  echo "Generating Waybar theme..."

  # Source the parse script to load environment variables
  source "${THEMES_DIR}/scripts/parse-theme.sh" "${theme_file}"

  # Generate CSS from template
  envsubst < "${THEMES_DIR}/templates/waybar/colors.css.tpl" \
    > "${THEMES_DIR}/generated/waybar/colors.css"

  # Create symlink in Waybar config directory
  ln -sf "${THEMES_DIR}/generated/waybar/colors.css" \
    "${HOME}/.config/waybar/colors.css"

  echo "  ✓ Waybar theme generated"
}

# Function to reload Waybar
reload_waybar() {
  echo "Reloading Waybar..."

  # Check if waybar is running
  if pgrep waybar > /dev/null; then
    # Send signal to reload styles
    pkill -SIGUSR2 waybar
    echo "  ✓ Waybar reloaded"
  else
    echo "  ⓘ Waybar is not running"
  fi
}

# Future: Function to generate Hyprland theme
generate_hyprland() {
  # TODO: Convert hex to rgba format
  # TODO: Generate colors.conf
  # TODO: Link to hyprland config
  echo "  ⓘ Hyprland theming not yet implemented"
}

# Future: Function to reload Hyprland
reload_hyprland() {
  # hyprctl reload
  :
}

# Future: Function to generate tmux theme
generate_tmux() {
  # TODO: Generate tmux theme
  echo "  ⓘ tmux theming not yet implemented"
}

# Future: Function to reload tmux
reload_tmux() {
  # tmux source-file ~/.config/tmux/tmux.conf
  :
}

# Future: Function to generate ghostty theme
generate_ghostty() {
  # TODO: Generate ghostty theme
  echo "  ⓘ Ghostty theming not yet implemented"
}

# Future: Function to reload ghostty
reload_ghostty() {
  # pkill -SIGUSR1 ghostty || true
  :
}

# Future: Function to generate neovim theme
generate_neovim() {
  # TODO: Generate neovim theme
  echo "  ⓘ Neovim theming not yet implemented"
}

# Future: Function to reload neovim
reload_neovim() {
  # No automatic reload for neovim
  :
}

main() {
  # Validate input
  if [[ -z "${THEME_NAME}" ]]; then
    usage
  fi

  local theme_file="${THEMES_DIR}/definitions/${THEME_NAME}.yaml"

  if [[ ! -f "${theme_file}" ]]; then
    echo "Error: Theme '${THEME_NAME}' not found"
    usage
  fi

  echo "Applying theme: ${THEME_NAME}"
  echo ""

  # Create generated directories if they don't exist
  for app in "${APPS_TO_THEME[@]}"; do
    mkdir -p "${THEMES_DIR}/generated/${app}"
  done

  # Generate configs for each app
  for app in "${APPS_TO_THEME[@]}"; do
    if declare -f "generate_${app}" > /dev/null; then
      "generate_${app}" "${theme_file}"
    fi
  done

  echo ""

  # Reload apps
  for app in "${APPS_TO_THEME[@]}"; do
    if declare -f "reload_${app}" > /dev/null; then
      "reload_${app}"
    fi
  done

  # Save current theme
  echo "${THEME_NAME}" > "${CURRENT_THEME_FILE}"

  echo ""
  echo "✅ Theme '${THEME_NAME}' applied successfully!"

  # Show instructions for apps that need manual reload
  echo ""
  echo "Note: Some applications may need to be restarted to fully apply the theme."
}

# Run main function
main "$@"