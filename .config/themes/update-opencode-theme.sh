#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove ALL old theme-related files
rm -f ~/.config/opencode/opencode-dark.json
rm -f ~/.config/opencode/opencode-light.json
rm -f ~/.config/opencode/custom-theme.json
rm -f ~/.config/opencode/opencode.json
rm -f ~/.config/opencode/opencode.template
rm -f ~/.config/opencode/integrate-opencode-themes.sh
rm -f ~/.config/opencode/theme.json

# Copy the newly generated theme (which contains both light and dark)
cp "$SCRIPT_DIR/generated/opencode/light.theme" ~/.config/opencode/theme.json

echo "✓ Removed all old theme files"
echo "✓ Copied new unified theme to ~/.config/opencode/theme.json"
echo "✓ OpenCode directory now contains:"
ls -la ~/.config/opencode/
