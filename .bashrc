#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# tmux's long-lived server keeps a stale NIRI_SOCKET when niri restarts.
# Re-resolve the current socket and push it into tmux's global env so all
# panes (new and existing after source) get the right path.
NIRI_SOCKET=$(ls /run/user/${UID}/niri*.sock 2>/dev/null | head -1)
if [[ -n "$NIRI_SOCKET" ]]; then
    export NIRI_SOCKET
    # Push into tmux global env so new and existing panes pick it up
    command -v tmux &>/dev/null && tmux set-environment -g NIRI_SOCKET "$NIRI_SOCKET" 2>/dev/null
fi

# Make sure ^[[200~ is not a part of the paste output from the clipboard
bind 'set enable-bracketed-paste off'

# When resizing a terminal emulator, Bash may not receive the resize signal. 
# This will cause typed text to not wrap correctly and overlap the prompt. 
# The checkwinsize shell option checks the window size after each command and, 
# if necessary, updates the values of LINES and COLUMNS
shopt -s checkwinsize

# History settings
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend

# Set env var QT_QPA_PLATFORM=wayland for VLC to use Wayland
export QT_QPA_PLATFORM=wayland




alias PAGER=less

alias gbc=find-and-copy-branch
alias ts='tmux-session-creator'
alias cl=clear
# eza: modern ls with file-type icons (requires a Nerd Font, which Alacritty uses)
alias ls='eza --icons=auto --group-directories-first'
alias la='eza -a --icons=auto --group-directories-first'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
alias grep='grep --color=auto'
#PS1='[\e[1m\W]\$ \e(B\e[m'
#PS1='\[\e[32m\][\e[1m\W]\$ \e(B\e[m'
# \e[3#1m	Start color scheme (replace #1 with a digit 0-7 repreenting a 
# 		color)
# \e[1m		Bold text on
# \e(B\e[m	Reset text attributes
export PS1="\[\e[32m\e[1m\]\W $ \[\e[0m\]"

# Environment variables
export REPOS="${HOME}/repos"
export EDITOR=nvim
export BROWSER=zen-beta
export NOTES="${HOME}/notes"

# Path
export DOTNETTOOLS="${HOME}/.dotnet/tools"
export SCRIPTS="${HOME}/.scripts"
export XDG_CONFIG_HOME="${HOME}/.config"
export NPM_PATH="${HOME}/.npm-global/bin"
export LOCAL_BIN="${HOME}/.local/bin"

export PATH="$PATH:$DOTNETTOOLS:$SCRIPTS:$XDG_CONFIG_HOME:$NPM_PATH:$LOCAL_BIN"

# Clipboard
alias cb='wl-copy'

# Stay green on teams script to clipboard
alias staygreen="cat ${SCRIPTS}/stayGreenOnTeams.js | cb"

# Pacman
alias installu='sudo pacman -Syu'
alias install='sudo pacman -Sy'

set -o vi               # replace readline with vi mode

# Git
alias config='git --git-dir=$HOME/.git/ --work-tree=$HOME'
alias c=config
alias g=git

# Wifi
alias wifi='iwctl'
alias connect-wifi='~/.scripts/connect-wifi.sh'
alias connect-mobile='connect-wifi martin'

alias ll='eza -la --icons=auto --group-directories-first'
# llg = ll plus the git-status column. Kept separate because --git is slow in
# huge repos (e.g. $HOME is itself the dotfiles repo, so `ll ~` would diff the
# whole home tree on every run).
alias llg='eza -la --icons=auto --group-directories-first --git'
alias n='nvim'

# Listing colors. Start from the classic dircolors palette (images, archives,
# audio, video) and extend it with common dev file types it doesn't know about,
# grouped into a few tasteful colors so code/docs/config get distinct icon+name
# colors in eza. EZA_COLORS layers on top (eza only): gold folders + a dimmed,
# neutral access-rights column.
if command -v dircolors &>/dev/null; then
    eval "$(dircolors -b)"
    _code="38;5;77"; _conf="38;5;110"; _doc="38;5;180"; _web="38;5;209"; _office="38;5;167"; _log="38;5;244"
    for e in js mjs cjs ts tsx jsx py go rs c cc cpp cxx h hpp cs java kt rb php lua sh bash zsh fish nix vim vil pl swift dart scala clj ex exs; do LS_COLORS+=":*.$e=$_code"; done
    for e in json jsonc yaml yml toml ini conf cfg config env xml csv tsv sql properties lock; do LS_COLORS+=":*.$e=$_conf"; done
    for e in md markdown mdx rst txt org tex adoc; do LS_COLORS+=":*.$e=$_doc"; done
    for e in html htm css scss sass less vue svelte; do LS_COLORS+=":*.$e=$_web"; done
    for e in pdf doc docx odt xls xlsx ods ppt pptx epub; do LS_COLORS+=":*.$e=$_office"; done
    LS_COLORS+=":*.log=$_log"
    export LS_COLORS
    unset _code _conf _doc _web _office _log e
fi
export EZA_COLORS="di=1;38;5;178:ur=38;5;244:uw=38;5;244:ux=38;5;244:ue=38;5;244:gr=38;5;244:gw=38;5;244:gx=38;5;244:tr=38;5;244:tw=38;5;244:tx=38;5;244:xa=38;5;244"
alias rebuild='sudo nixos-rebuild switch --flake /home/martin/.config/nixos'

# Function to create directory and cd into it
mkcd () {
    mkdir -p "$1" && cd "$1"
}

# Scripts
alias dp='delete-prompt'

# .bashrc
alias rbc='source ~/.bashrc'
alias ebc='$EDITOR ~/.bashrc'


export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash

# Load ble.sh for fish-like auto-suggestions
#[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh


export MOZ_ENABLE_WAYLAND=1

# Chrome/Chromium Wayland configuration
# Previously forced XWayland to prevent crashes when moving workspaces between monitors
# Now controlled via separate desktop entries:
#   - "Chrome (Xwayland)" for stable monitor switching
#   - "Chrome" for native Wayland support

# OSC 133 shell integration for tmux
# Enables semantic prompt detection for better terminal integration
# Benefits: Jump between prompts in copy-mode with { and }
if [[ -n "$TMUX" ]]; then
    _prompt_command_osc133() {
        printf '\e]133;D;%s\e\\' "$?"  # Command finished with exit code
        printf '\e]133;A\e\\'           # Prompt start
    }
    # Append to PROMPT_COMMAND (preserving existing commands)
    PROMPT_COMMAND="_prompt_command_osc133${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    # Command execution start (emitted before command runs)
    PS0='\e]133;C\e\\'
fi


eval "$(zoxide init bash)"

# claudeck: auto-cd into the session's main repo when a new shell starts
# inside a claudeck-managed niri workspace. `claudeck cd` reads the focused
# niri workspace name, looks it up in ~/.local/state/claudeck/sessions.toml,
# and prints the main repo path (or nothing if no match).
__claudeck_dir=$(claudeck cd 2>/dev/null) && [ -n "$__claudeck_dir" ] && cd "$__claudeck_dir"
unset __claudeck_dir

# pnpm
export PNPM_HOME="/home/martin/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
