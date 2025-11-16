# Claude Code Configuration

This directory contains Claude Code configuration files managed as part of the dotfiles repository.

## Directory Structure

```
~/.config/claude/
├── README.md                  # This file
├── setup.sh                   # Setup script for fresh installations
├── settings.json              # Main Claude Code settings
├── CLAUDE.md                  # Global instructions for Claude Code
├── statusline-command.sh      # Custom statusline script
└── hooks/
    └── stop-notify.sh         # Desktop notification hook
```

## Dependencies

Required packages for full functionality:

- **Claude Code CLI** - The main application
- **tmux** - Terminal multiplexer (for conversation title detection)
- **dunst** - Lightweight notification daemon
- **jq** - JSON processor (used in setup script)

### Installing Dependencies on Arch Linux

```bash
sudo pacman -S tmux dunst jq
```

## Setup Instructions

### Fresh Installation

When cloning your dotfiles on a fresh Arch system:

1. **Install dependencies:**
   ```bash
   sudo pacman -S tmux dunst jq
   ```

2. **Run the setup script:**
   ```bash
   cd ~/.config/claude
   ./setup.sh
   ```

The setup script will:
- Check that all dependencies are installed
- Create necessary symlinks from `~/.claude/` to `~/.config/claude/`
- Set executable permissions on scripts
- Test the notification system

### Manual Setup

If you prefer to set up manually:

1. **Create symlinks:**
   ```bash
   ln -s ~/.config/claude/settings.json ~/.claude/settings.json
   ln -s ~/.config/claude/hooks ~/.claude/hooks
   ```

2. **Set executable permissions:**
   ```bash
   chmod +x ~/.config/claude/statusline-command.sh
   chmod +x ~/.config/claude/hooks/stop-notify.sh
   ```

3. **Verify setup:**
   ```bash
   test -L ~/.claude/settings.json && echo "settings.json symlink OK"
   test -L ~/.claude/hooks && echo "hooks symlink OK"
   ```

## Features

### Desktop Notifications

The `Stop` hook sends a desktop notification when Claude Code finishes responding.

**How it works:**
- Triggers after every Claude Code response
- Extracts conversation title from tmux pane title
- Displays notification with conversation context

**Notification format:**
- **Title:** Conversation title (e.g., "Desktop Notifications Setup")
- **Body:** "Ready for input"
- **Icon:** robot

### Custom Statusline

The statusline script displays:
- Git branch name (if in a git repository)
- Current directory name in bold green

## File Details

### settings.json

Main configuration file containing:
- **hooks**: Event-driven automation (Stop hook for notifications)
- **statusLine**: Custom statusline command
- **alwaysThinkingEnabled**: Toggle for thinking mode display

### CLAUDE.md

Global instructions for Claude Code behavior:
- Git commit message formatting rules
- Code style preferences (no trailing whitespace)
- Solution approach guidelines

### statusline-command.sh

Bash script that generates the custom statusline:
- Shows git branch (if available)
- Shows current directory in bold green

### hooks/stop-notify.sh

Desktop notification hook that:
- Reads conversation title from tmux pane title
- Sends notification via dunstify
- Falls back to "Claude Code" if not in tmux

## Troubleshooting

### Notifications not appearing

1. **Check dunst is running:**
   ```bash
   pgrep -x dunst
   ```

2. **Test notification manually:**
   ```bash
   ~/.config/claude/hooks/stop-notify.sh
   ```

3. **Verify hook is configured:**
   ```bash
   cat ~/.claude/settings.json | jq '.hooks.Stop'
   ```

### Symlinks broken

Re-run the setup script or recreate manually:
```bash
cd ~/.config/claude
./setup.sh
```

### Statusline not working

1. **Check script is executable:**
   ```bash
   ls -l ~/.config/claude/statusline-command.sh
   ```

2. **Test script manually:**
   ```bash
   ~/.config/claude/statusline-command.sh
   ```

## Customization

### Changing Notification Appearance

Edit `hooks/stop-notify.sh` and modify the dunstify command:

```bash
# Change urgency level (-u low, normal, or critical)
dunstify "$CONVERSATION_TITLE" "Ready for input" -u critical -i robot

# Change icon (-i <icon-name>)
dunstify "$CONVERSATION_TITLE" "Ready for input" -u normal -i computer

# Add timeout in milliseconds (-t <ms>)
dunstify "$CONVERSATION_TITLE" "Ready for input" -u normal -i robot -t 5000
```

### Adding More Hooks

See [Claude Code hooks documentation](https://code.claude.com/docs) for available hook types and examples.

## Notes

- Runtime data (history, credentials, etc.) remains in `~/.claude/`
- Only configuration files are managed in dotfiles
- Symlinks ensure Claude Code finds config in both locations
