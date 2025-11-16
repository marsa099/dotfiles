#!/bin/bash

# Claude Code Configuration Setup Script
# Sets up Claude Code configuration from dotfiles on a fresh Arch installation

set -e

echo "========================================="
echo "Claude Code Configuration Setup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any errors occurred
ERRORS=0

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status messages
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Check dependencies
echo "Checking dependencies..."
echo ""

if command_exists tmux; then
    print_status "tmux is installed"
else
    print_error "tmux is NOT installed (required for conversation title detection)"
    echo "  Install with: sudo pacman -S tmux"
fi

if command_exists dunst || command_exists dunstify; then
    print_status "dunst is installed"
else
    print_error "dunst is NOT installed (required for desktop notifications)"
    echo "  Install with: sudo pacman -S dunst"
fi

if command_exists jq; then
    print_status "jq is installed"
else
    print_warning "jq is NOT installed (optional, useful for debugging)"
    echo "  Install with: sudo pacman -S jq"
fi

echo ""

# Exit if critical dependencies are missing
if [ $ERRORS -gt 0 ]; then
    echo ""
    print_error "Missing required dependencies. Please install them and run this script again."
    exit 1
fi

# Create ~/.claude directory if it doesn't exist
if [ ! -d ~/.claude ]; then
    mkdir -p ~/.claude
    print_status "Created ~/.claude directory"
fi

# Create symlinks
echo "Creating symlinks..."
echo ""

# Remove existing files/symlinks if they exist
if [ -e ~/.claude/settings.json ] || [ -L ~/.claude/settings.json ]; then
    rm -f ~/.claude/settings.json
    print_status "Removed old settings.json"
fi

if [ -e ~/.claude/hooks ] || [ -L ~/.claude/hooks ]; then
    rm -rf ~/.claude/hooks
    print_status "Removed old hooks directory"
fi

# Create symlinks
ln -s ~/.config/claude/settings.json ~/.claude/settings.json
print_status "Created symlink: ~/.claude/settings.json -> ~/.config/claude/settings.json"

ln -s ~/.config/claude/hooks ~/.claude/hooks
print_status "Created symlink: ~/.claude/hooks -> ~/.config/claude/hooks"

echo ""

# Set executable permissions
echo "Setting executable permissions..."
echo ""

chmod +x ~/.config/claude/statusline-command.sh
print_status "Made statusline-command.sh executable"

chmod +x ~/.config/claude/hooks/stop-notify.sh
print_status "Made stop-notify.sh executable"

chmod +x ~/.config/claude/hooks/prompt-submit.sh
print_status "Made prompt-submit.sh executable"

echo ""

# Verify symlinks
echo "Verifying symlinks..."
echo ""

if [ -L ~/.claude/settings.json ] && [ -e ~/.claude/settings.json ]; then
    print_status "settings.json symlink is valid"
else
    print_error "settings.json symlink is broken or missing"
fi

if [ -L ~/.claude/hooks ] && [ -d ~/.claude/hooks ]; then
    print_status "hooks symlink is valid"
else
    print_error "hooks symlink is broken or missing"
fi

echo ""

# Test notification
echo "Testing desktop notification..."
echo ""

if command_exists dunstify; then
    dunstify "Claude Code Setup" "Configuration complete! ✓" -u normal -i emblem-default
    print_status "Test notification sent (check your desktop)"
elif command_exists notify-send; then
    notify-send "Claude Code Setup" "Configuration complete! ✓" -u normal -i emblem-default
    print_status "Test notification sent (check your desktop)"
else
    print_warning "Could not send test notification (dunst not running?)"
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Claude Code configuration is now ready to use."
echo ""
echo "What was done:"
echo "  • Verified dependencies (tmux, dunst)"
echo "  • Created symlinks from ~/.claude to ~/.config/claude"
echo "  • Set executable permissions on scripts"
echo "  • Tested desktop notifications"
echo ""
echo "You can now use Claude Code with:"
echo "  • Desktop notifications on response completion"
echo "  • tmux window highlighting (bell icon when Claude waits for input)"
echo "  • Pane title updates showing Claude's state"
echo "  • OSC 133 shell integration (jump between prompts with { and })"
echo "  • Custom statusline with git branch and directory"
echo "  • Global instructions from CLAUDE.md"
echo ""
echo "Note: OSC 133 is configured in ~/.bashrc and works automatically in tmux."
echo ""
echo "For more information, see: ~/.config/claude/README.md"
echo ""
