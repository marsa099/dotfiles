# Centralized Theme System

A unified theme management system that maintains consistent colors across all development tools through a single source of truth.

## Overview

This system uses a centralized `colors.json` file to generate theme configurations for multiple tools, ensuring visual consistency across your entire development environment.

### Supported Tools
- **Neovim** - Custom colorscheme with comprehensive syntax highlighting
- **Fish Shell** - Terminal colors and prompt styling
- **FZF** - Fuzzy finder interface colors
- **Ghostty** - Terminal emulator theme
- **Tide** - Fish prompt framework (manual configuration)

## Architecture

```
themes/
├── colors.json          # Single source of truth for all colors
├── theme-manager.sh     # Generation and application script
├── templates/           # Template files with placeholders
│   ├── fish.template
│   ├── fzf.template
│   ├── ghostty.template
│   ├── nvim-custom.template
│   └── nvim.template (Rose Pine fallback)
└── generated/           # Auto-generated theme files
    ├── fish/
    ├── fzf/
    ├── ghostty/
    ├── nvim-custom/
    └── nvim/
```

## Core Components

### 1. Colors Definition (`colors.json`)

The central configuration file containing all color definitions:

```json
{
  "themes": {
    "dark": {
      "background": {
        "primary": "#0A0A0A",      // Main background
        "secondary": "#121212",     // Secondary background
        "tertiary": "#1B1B1B",     // Lightest dark background
        "selection": "#121E42",     // Selection background
        "surface": "#121212",       // Floating surfaces
        "overlay": "#2A2F39",       // Overlays and borders
        "prompt": "#2A2F39"         // Prompt backgrounds
      },
      "foreground": {
        "primary": "#EDEDED",       // Main text
        "secondary": "#D6DDEA",     // Secondary text
        "muted": "#767676",         // Muted text
        "subtle": "#7E8193"         // Subtle text
      },
      "accent": {
        "red": "#B85B53",
        "orange": "#E9B872",
        "yellow": "#E9B872",
        "green": "#74BAA8",
        "cyan": "#74BAA8",
        "blue": "#6A8BE3",
        "purple": "#BCB6EC",
        "pink": "#A9B9EF"
      },
      "semantic": {
        "error": "#F71735",
        "warning": "#FFA630",
        "success": "#0EC256",
        "info": "#1A8C9B",
        "keyword": "#A9B9EF",
        "command": "#6A8BE3",
        "operator": "#b09884",
        "comment": "#505050",
        "string": "#74BAA8"
      },
      "cursor": "#FF570D"
    },
    "light": {
      // Light theme definitions...
    }
  }
}
```

### 2. Template System

Templates use placeholder syntax to reference colors from `colors.json`:

```bash
# Example from fzf.template
--color=bg:{{background.primary}}
--color=fg:{{foreground.primary}}
--color=pointer:{{cursor}}
```

### 3. Generation Process

The `theme-manager.sh` script processes templates by:
1. Reading color values from `colors.json`
2. Replacing placeholders with actual color values
3. Generating tool-specific configuration files
4. Applying configurations to the appropriate locations

## Commands

### Theme Manager Script

All commands should be run from the `/themes/` directory:

```bash
cd ~/.config/themes
```

#### Generate Themes
```bash
# Generate all themes for specific mode
./theme-manager.sh generate dark
./theme-manager.sh generate light

# Generate all themes for current system mode
./theme-manager.sh generate
```

#### Apply Themes
```bash
# Apply all themes for specific mode
./theme-manager.sh apply dark
./theme-manager.sh apply light

# Apply all themes for current system mode
./theme-manager.sh apply
```

#### Switch Themes
```bash
# Switch to specific theme mode
./theme-manager.sh switch dark
./theme-manager.sh switch light

# Toggle between light and dark
./theme-manager.sh toggle

# Auto-detect and apply system theme
./theme-manager.sh auto
```

#### Status and Help
```bash
# Show current theme status
./theme-manager.sh status

# Show help information
./theme-manager.sh help
```

### Fish Shell Commands

```bash
# Apply specific themes
set_dark_theme
set_light_theme

# Toggle between themes
toggle_theme

# Check current theme
echo $THEME_MODE
```

### Neovim Commands

```vim
" Reload current colorscheme
:ReloadColors

" Switch colorschemes manually
:colorscheme custom-theme
:colorscheme rose-pine
```

### Manual Theme Loading

```bash
# Load specific tool themes manually
source ~/.config/themes/generated/fish/dark.theme
source ~/.config/themes/generated/fzf/dark.theme
```

## Tool-Specific Integration

### Neovim
- **Location**: `~/.config/nvim/lua/theme/`
- **Colorscheme**: `custom-theme` (auto-loads from generated files)
- **Fallback**: Rose Pine (if custom theme fails)
- **Reload**: `<leader>rc` or `:ReloadColors`

### Fish Shell
- **Functions**: `set_dark_theme`, `set_light_theme`, `toggle_theme`
- **Auto-load**: Functions source from generated theme files
- **Integration**: Works with Tide prompt and FZF

### FZF
- **Integration**: Loaded via Fish environment variables
- **Colors**: Background, highlight, cursor/pointer colors
- **Usage**: All fuzzy finders (Ctrl+R, file search, etc.)

### Ghostty
- **Location**: `~/.config/ghostty/themes/`
- **Auto-switch**: `theme = light:light,dark:dark` in config
- **Reload**: `Cmd+S > R` or restart Ghostty

### Tide Prompt
- **Manual Configuration**: Updated via Fish universal variables
- **Background Colors**: Set to match theme tertiary background
- **Segments**: Path, git status, command duration, etc.

## Workflow Examples

### Daily Usage
```bash
# Auto-apply system theme
./theme-manager.sh auto

# Toggle between light/dark
./theme-manager.sh toggle
```

### Development Workflow
```bash
# 1. Edit colors in colors.json
vim colors.json

# 2. Regenerate all themes
./theme-manager.sh generate dark

# 3. Apply to all tools
./theme-manager.sh apply dark

# 4. Reload Neovim (if open)
# In Neovim: :ReloadColors
```

### Adding New Tools

1. **Create Template**: Add new template file in `templates/`
2. **Update Script**: Add tool handling in `theme-manager.sh`
3. **Test**: Generate and apply themes
4. **Document**: Update this README

## Color Customization

### Modifying Colors
1. Edit `colors.json` with new color values
2. Run `./theme-manager.sh generate [mode]`
3. Run `./theme-manager.sh apply [mode]`
4. Reload tools as needed

### Adding New Colors
1. Add color definition to `colors.json`
2. Update relevant templates to use new color
3. Regenerate and apply themes

### Best Practices
- **Test in both modes**: Always verify light and dark themes
- **Use semantic names**: Prefer `error` over `red` for context
- **Maintain contrast**: Ensure readability across all tools
- **Backup**: Commit changes to version control

## Troubleshooting

### Common Issues

**Themes not applying**:
```bash
# Check file permissions
ls -la generated/
# Regenerate themes
./theme-manager.sh generate dark
```

**Neovim errors**:
```vim
" Check colorscheme availability
:colorscheme <Tab>
" Reload theme manually
:ReloadColors
```

**Fish colors not updating**:
```bash
# Reload Fish configuration
source ~/.config/fish/config.fish
# Reapply theme
set_dark_theme
```

**Tide backgrounds invisible**:
```bash
# Update Tide colors manually
set -U tide_pwd_bg_color 1B1B1B
set -U tide_git_bg_color 1B1B1B
```

### Log Files
- **Theme Watcher**: `theme-watcher.log`
- **Generation**: Check script output for errors

## System Integration

### Auto-Detection
- **macOS**: Reads `AppleInterfaceStyle` for dark mode detection
- **Fish Integration**: Theme functions called automatically
- **Neovim**: `auto-dark-mode.nvim` plugin integration

### Dependencies
- **jq**: Required for JSON processing
- **Fish Shell**: For theme switching functions
- **Neovim**: For custom colorscheme integration

## Advanced Usage

### Custom Templates
Create new templates using the placeholder syntax:
```bash
# Example: custom-tool.template
background={{background.primary}}
foreground={{foreground.primary}}
accent={{accent.blue}}
```

### Scripting Integration
```bash
# Get current theme mode
CURRENT_THEME=$(./theme-manager.sh status | grep "Current Theme" | cut -d: -f2)

# Programmatic theme switching
if [[ $(date +%H) -gt 18 ]]; then
    ./theme-manager.sh switch dark
else
    ./theme-manager.sh switch light
fi
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Switch to dark | `./theme-manager.sh switch dark` |
| Switch to light | `./theme-manager.sh switch light` |
| Toggle themes | `./theme-manager.sh toggle` |
| Auto-detect | `./theme-manager.sh auto` |
| Regenerate all | `./theme-manager.sh generate` |
| Apply all | `./theme-manager.sh apply` |
| Check status | `./theme-manager.sh status` |
| Reload Neovim | `:ReloadColors` |
| Fish dark theme | `set_dark_theme` |
| Fish light theme | `set_light_theme` |

For questions or issues, check the troubleshooting section or review the generated files in `themes/generated/`.