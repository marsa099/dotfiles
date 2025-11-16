#!/bin/bash

# vicinae-theme-switcher.sh
# Monitors gsettings color-scheme and switches vicinae theme accordingly

CONFIG_FILE="$HOME/.config/vicinae/vicinae.json"

# Function to update vicinae theme
update_theme() {
    local color_scheme="$1"
    local theme_name

    # Map gsettings color-scheme to vicinae theme
    case "$color_scheme" in
        "'prefer-dark'")
            theme_name="catppuccin-frappe"
            ;;
        "'prefer-light'"|"'default'")
            theme_name="catppuccin-latte"
            ;;
        *)
            # Default to dark theme for unknown values
            theme_name="catppuccin-frappe"
            ;;
    esac

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Switching vicinae theme to: $theme_name (system: $color_scheme)"

    # Update the config file using jq
    if command -v jq &> /dev/null; then
        jq --arg theme "$theme_name" '.theme.name = $theme' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && \
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    else
        echo "Error: jq is not installed. Please install jq to use this script."
        exit 1
    fi
}

# Set initial theme based on current gsettings
initial_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
echo "Initial color scheme: $initial_scheme"
update_theme "$initial_scheme"

# Monitor for changes
echo "Monitoring gsettings color-scheme changes..."
gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
    # Extract the new value from the monitor output
    # Format is: "color-scheme: 'prefer-dark'" or similar
    if [[ "$line" =~ color-scheme:\ (.+) ]]; then
        new_scheme="${BASH_REMATCH[1]}"
        update_theme "$new_scheme"
    fi
done