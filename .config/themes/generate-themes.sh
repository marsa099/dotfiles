#!/bin/bash

# Simple script to generate both light and dark themes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎨 Generating and applying themes..."
echo ""

# Generate and apply dark theme
echo "🌙 Generating dark theme..."
"$SCRIPT_DIR/theme-manager.sh" generate dark
echo "🌙 Applying dark theme..."
"$SCRIPT_DIR/theme-manager.sh" apply dark
echo ""

# Generate and apply light theme  
echo "☀️  Generating light theme..."
"$SCRIPT_DIR/theme-manager.sh" generate light
echo "☀️  Applying light theme..."
"$SCRIPT_DIR/theme-manager.sh" apply light
echo ""

echo "✅ Both themes generated and applied successfully!"
echo ""
echo "Use 'toggle_theme' to switch between them."