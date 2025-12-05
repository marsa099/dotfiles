#!/bin/bash

# Theme Manager - Centralized theme management for dotfiles
# Author: Generated for custom theme system

set -e

THEMES_DIR="$HOME/.config/themes"
COLORS_FILE="$THEMES_DIR/colors.json"
TEMPLATES_DIR="$THEMES_DIR/templates"
GENERATED_DIR="$THEMES_DIR/generated"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if jq is installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
}

# Get system appearance (Linux via gsettings, macOS via defaults)
get_system_appearance() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light"
    else
        # Linux: check gsettings color-scheme
        local scheme
        scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        if [[ "$scheme" == "prefer-dark" ]]; then
            echo "Dark"
        else
            echo "Light"
        fi
    fi
}

# Get current theme mode
get_current_theme() {
    local appearance=$(get_system_appearance)
    if [[ "$appearance" == "Dark" ]]; then
        echo "dark"
    else
        echo "light"
    fi
}

# Extract color from JSON
get_color() {
    local theme=$1
    local path=$2
    jq -r ".themes.${theme}.${path}" "$COLORS_FILE"
}

# Generate theme for a specific tool
generate_tool_theme() {
    local tool=$1
    local theme_mode=$2
    
    # Try theme-specific template first, then fall back to generic
    local template_file="$TEMPLATES_DIR/${tool}-${theme_mode}.template"
    if [[ ! -f "$template_file" ]]; then
        template_file="$TEMPLATES_DIR/${tool}.template"
    fi
    
    local output_dir="$GENERATED_DIR/${tool}"
    
    if [[ ! -f "$template_file" ]]; then
        log_warning "Template for $tool not found: $template_file"
        return 1
    fi
    
    log_info "Generating $tool theme for $theme_mode mode..."
    
    # Create output directory and generate theme
    mkdir -p "$output_dir"
    local output_file="$output_dir/${theme_mode}.theme"
    python3 "$THEMES_DIR/theme-processor.py" "$template_file" "$COLORS_FILE" "$theme_mode" "$output_file"
    
    log_success "Generated $tool theme: $output_file"
}

# Generate all themes
generate_all() {
    local theme_mode=${1:-$(get_current_theme)}
    
    log_info "Generating all themes for $theme_mode mode..."
    
    # Generate themes for all available templates
    for template in "$TEMPLATES_DIR"/*.template; do
        if [[ -f "$template" ]]; then
            local tool=$(basename "$template" .template)
            generate_tool_theme "$tool" "$theme_mode"
        fi
    done
    
    log_success "All themes generated for $theme_mode mode"
}

# Apply theme for a specific tool
apply_tool_theme() {
    local tool=$1
    local theme_mode=$2
    local generated_file="$GENERATED_DIR/${tool}/${theme_mode}.theme"
    
    if [[ ! -f "$generated_file" ]]; then
        log_error "Generated theme file not found: $generated_file"
        return 1
    fi
    
    case "$tool" in
        "nvim")
            # Copy generated colors to custom theme directory
            local nvim_theme_dir="$HOME/.config/nvim/lua/theme"
            if [[ -d "$nvim_theme_dir" ]] || [[ -d "$HOME/.config/nvim" ]]; then
                mkdir -p "$nvim_theme_dir"
                cp "$generated_file" "$nvim_theme_dir/colors.lua"
                log_success "Applied Neovim theme"
            else
                log_info "Neovim config not found, skipping"
            fi
            ;;
        "mako")
            # Copy generated config to mako directory (only if mako is used)
            if [[ -d "$HOME/.config/mako" ]] || pgrep -x mako > /dev/null; then
                mkdir -p "$HOME/.config/mako"
                cp "$generated_file" "$HOME/.config/mako/config"
                # Reload mako if running
                if pgrep -x mako > /dev/null; then
                    makoctl reload
                    log_success "Applied and reloaded Mako theme"
                else
                    log_success "Applied Mako theme (not running)"
                fi
            else
                log_info "Mako not installed, skipping"
            fi
            ;;
        "waybar")
            # Copy generated style to waybar directory (waybar uses style-dark.css / style-light.css)
            cp "$generated_file" "$HOME/.config/waybar/style-${theme_mode}.css"
            cp "$generated_file" "$HOME/.config/waybar/style.css"
            # Reload waybar if running
            if pgrep -x waybar > /dev/null; then
                killall -SIGUSR2 waybar
                log_success "Applied and reloaded Waybar theme"
            else
                log_success "Applied Waybar theme (not running)"
            fi
            ;;
        "fish")
            # Fish themes are applied by Fish itself, not by bash
            # Just log success since Fish will source it when needed
            log_success "Fish theme generated (will be applied by Fish shells)"
            ;;
        "ghostty")
            # Copy generated theme to ghostty themes directory
            mkdir -p "$HOME/.config/ghostty/themes"
            cp "$generated_file" "$HOME/.config/ghostty/themes/$theme_mode"
            log_success "Generated and copied Ghostty theme"
            # Note: Ghostty auto-detects system theme changes via 'theme = light:light,dark:dark'
            # so we don't need to trigger a reload
            ;;
        "tmux")
            # Update tmux catppuccin flavor in config
            local tmux_config="$HOME/.config/tmux/tmux.conf"
            local tmux_flavor
            if [[ "$theme_mode" == "dark" ]]; then
                tmux_flavor="frappe"
            else
                tmux_flavor="latte"
            fi
            if [[ -f "$tmux_config" ]]; then
                # Update catppuccin flavor
                sed -i "s/@catppuccin_flavor '[^']*'/@catppuccin_flavor '$tmux_flavor'/" "$tmux_config"
                # Reload tmux if running
                if tmux list-sessions &> /dev/null; then
                    tmux source-file "$tmux_config" 2>/dev/null || true
                    log_success "Applied tmux theme: $tmux_flavor"
                else
                    log_success "Updated tmux config to $tmux_flavor (reload on next start)"
                fi
            else
                log_info "tmux config not found, skipping"
            fi
            ;;
        "fzf")
            # FZF themes are applied by Fish shell, not by bash
            # Just log success since Fish will source it when needed
            log_success "FZF theme generated (will be applied by Fish shells)"
            ;;
        "tide")
            # Apply Tide prompt colors by sourcing the generated file directly
            if command -v fish &> /dev/null; then
                # Source the file directly in fish for maximum performance and reliability
                fish -c "source '$generated_file'"
                log_success "Applied Tide prompt theme"
            else
                log_warning "Fish shell not found, Tide theme not applied"
            fi
            ;;
        "niri")
            # Niri colors are reference only - user needs to copy to config.kdl
            # We can't auto-apply because KDL doesn't support includes
            log_success "Niri theme generated: $generated_file (copy values to config.kdl)"
            ;;
        "dunst")
            # Copy dunst theme to config location
            local dunst_config="$HOME/.config/dunst/dunstrc"
            if [[ -f "$dunst_config" ]]; then
                # Backup and update urgency sections
                log_info "Dunst theme generated. Update $dunst_config manually or reload dunst."
                # Reload dunst if running
                if pgrep -x dunst > /dev/null; then
                    pkill -SIGUSR1 dunst 2>/dev/null || true
                fi
            fi
            log_success "Dunst theme generated: $generated_file"
            ;;
        "alacritty")
            # Alacritty auto-reloads when config changes
            mkdir -p "$HOME/.config/alacritty"
            local alacritty_colors="$HOME/.config/alacritty/colors.toml"
            cp "$generated_file" "$alacritty_colors"
            log_success "Applied Alacritty theme (auto-reloads)"
            ;;
        "rofi")
            # Copy rofi theme colors
            mkdir -p "$HOME/.config/rofi/themes"
            local rofi_colors="$HOME/.config/rofi/themes/colors.rasi"
            cp "$generated_file" "$rofi_colors"
            log_success "Applied Rofi theme colors"
            ;;
        "swayosd")
            # Copy swayosd theme and reload
            mkdir -p "$HOME/.config/swayosd"
            local swayosd_style="$HOME/.config/swayosd/style.css"
            cp "$generated_file" "$swayosd_style"
            # Restart swayosd-server if running
            if pgrep -x swayosd-server > /dev/null; then
                systemctl --user restart swayosd.service 2>/dev/null || true
            fi
            log_success "Applied SwayOSD theme"
            ;;
        "gtk")
            # Apply GTK theme via gsettings
            local gtk_theme
            if [[ "$theme_mode" == "dark" ]]; then
                gtk_theme="Adwaita-dark"
                gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
            else
                gtk_theme="Adwaita"
                gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
            fi
            gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
            log_success "Applied GTK theme: $gtk_theme"
            ;;
        "vicinae")
            # Update vicinae theme name in config
            local vicinae_config="$HOME/.config/vicinae/vicinae.json"
            local vicinae_theme
            if [[ "$theme_mode" == "dark" ]]; then
                vicinae_theme="catppuccin-frappe"
            else
                vicinae_theme="gruvbox-light"
            fi
            if [[ -f "$vicinae_config" ]] && command -v jq &> /dev/null; then
                local tmp=$(mktemp)
                jq ".theme.name = \"$vicinae_theme\"" "$vicinae_config" > "$tmp" && mv "$tmp" "$vicinae_config"
                log_success "Applied Vicinae theme: $vicinae_theme"
            else
                log_warning "Vicinae config not found or jq not installed"
            fi
            ;;
        "opencode")
            # OpenCode theme - just generate, no auto-apply
            log_success "OpenCode theme generated: $generated_file"
            ;;
        "spotify-player")
            # spotify-player theme - copy to config if exists
            local spotify_config="$HOME/.config/spotify-player"
            if [[ -d "$spotify_config" ]]; then
                cp "$generated_file" "$spotify_config/theme.toml"
                log_success "Applied spotify-player theme"
            else
                log_info "spotify-player not configured, skipping"
            fi
            ;;
        "wezterm")
            # WezTerm theme - copy to config if exists
            local wezterm_config="$HOME/.config/wezterm"
            if [[ -d "$wezterm_config" ]]; then
                cp "$generated_file" "$wezterm_config/colors.lua"
                log_success "Applied WezTerm theme"
            else
                log_info "WezTerm not configured, skipping"
            fi
            ;;
        *)
            log_warning "Unknown tool: $tool"
            return 1
            ;;
    esac
}

# Apply all themes
apply_all() {
    local theme_mode=${1:-$(get_current_theme)}
    
    log_info "Applying all themes for $theme_mode mode..."
    
    for tool_dir in "$GENERATED_DIR"/*; do
        if [[ -d "$tool_dir" ]]; then
            local tool=$(basename "$tool_dir")
            apply_tool_theme "$tool" "$theme_mode"
        fi
    done
    
    log_success "All themes applied for $theme_mode mode"
}

# Switch theme mode
switch_theme() {
    local theme_mode=$1
    
    if [[ "$theme_mode" != "dark" && "$theme_mode" != "light" ]]; then
        log_error "Invalid theme mode: $theme_mode. Use 'dark' or 'light'"
        return 1
    fi
    
    log_info "Switching to $theme_mode theme..."
    
    # Generate and apply all themes
    generate_all "$theme_mode"
    apply_all "$theme_mode"
    
    log_success "Theme switched to $theme_mode mode"
}

# Toggle between light and dark
toggle_theme() {
    local current_theme=$(get_current_theme)
    if [[ "$current_theme" == "dark" ]]; then
        switch_theme "light"
    else
        switch_theme "dark"
    fi
}

# Auto-detect and apply system theme
auto_theme() {
    local system_theme=$(get_current_theme)
    log_info "Auto-detecting system theme: $system_theme"
    switch_theme "$system_theme"
}

# Show current theme status
status() {
    local current_theme=$(get_current_theme)
    local system_appearance=$(get_system_appearance)
    
    echo "=== Theme Status ==="
    echo "System Appearance: $system_appearance"
    echo "Current Theme: $current_theme"
    echo "Themes Directory: $THEMES_DIR"
    echo "Colors File: $COLORS_FILE"
    echo ""
    echo "Available Tools:"
    for template in "$TEMPLATES_DIR"/*.template; do
        if [[ -f "$template" ]]; then
            local tool=$(basename "$template" .template)
            echo "  - $tool"
        fi
    done
}

# Watch for system theme changes
watch_theme() {
    log_info "Watching for system theme changes..."
    log_info "Press Ctrl+C to stop"

    # Apply current theme on startup
    auto_theme

    # Monitor gsettings for color-scheme changes
    gsettings monitor org.gnome.desktop.interface color-scheme 2>/dev/null | while read -r line; do
        local new_scheme
        new_scheme=$(echo "$line" | grep -oE "'[^']+'" | tr -d "'")

        if [[ "$new_scheme" == "prefer-dark" ]]; then
            log_info "System switched to dark mode"
            switch_theme "dark"
        elif [[ "$new_scheme" == "prefer-light" || "$new_scheme" == "default" ]]; then
            log_info "System switched to light mode"
            switch_theme "light"
        fi
    done
}

# Show help
show_help() {
    cat << EOF
Theme Manager - Centralized theme management for dotfiles

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    generate [MODE]     Generate themes for specified mode (dark/light)
    apply [MODE]        Apply themes for specified mode (dark/light)
    switch [MODE]       Switch to specified theme mode (dark/light)
    toggle              Toggle between light and dark themes
    auto                Auto-detect and apply system theme
    watch               Watch for system theme changes and auto-switch
    status              Show current theme status
    help                Show this help message

Options:
    MODE                Theme mode: 'dark' or 'light' (auto-detected if not specified)

Examples:
    $0 auto             # Auto-detect and apply system theme
    $0 switch dark      # Switch to dark theme
    $0 toggle           # Toggle between light and dark
    $0 watch            # Watch and auto-switch on system changes
    $0 generate light   # Generate light theme files only
    $0 status           # Show current status

EOF
}

# Main script logic
main() {
    check_dependencies
    
    case "${1:-}" in
        "generate")
            generate_all "$2"
            ;;
        "apply")
            apply_all "$2"
            ;;
        "switch")
            switch_theme "$2"
            ;;
        "toggle")
            toggle_theme
            ;;
        "auto")
            auto_theme
            ;;
        "watch")
            watch_theme
            ;;
        "status")
            status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            auto_theme
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"