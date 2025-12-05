#!/bin/bash

# Install custom OpenCode theme with solid colors (no Rose Pine references)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"

# Ensure OpenCode config directory exists
mkdir -p "$OPENCODE_CONFIG_DIR"

# Copy the custom theme
echo "Installing custom OpenCode theme..."
cp "$SCRIPT_DIR/custom-opencode-theme.json" "$OPENCODE_CONFIG_DIR/theme.json"

# Update opencode.json to use the theme
cat > "$OPENCODE_CONFIG_DIR/opencode.json" << EOF
{
  "theme": "theme",
  "\$schema": "https://opencode.ai/config.json"
}
EOF

echo "✓ Installed custom theme to $OPENCODE_CONFIG_DIR/theme.json"
echo "✓ Updated $OPENCODE_CONFIG_DIR/opencode.json"
echo ""
echo "Theme installed successfully! Restart OpenCode to apply changes."