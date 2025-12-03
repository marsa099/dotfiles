#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

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


# Sets az devops PAT to env var
# Need to move. This requires auth which is very annoying as soon as you open a terminal
#export AZURE_DEVOPS_EXT_PAT=$(pass sis/devops/pat)

alias PAGER=less

alias gbc=find-and-copy-branch
alias ts='tmux-session-creator'
alias cl=clear
alias ls='ls --color=auto'
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
export BROWSER=firefox
export NOTES="${HOME}/notes"

# Path
export DOTNETTOOLS="${HOME}/.dotnet/tools"
export SCRIPTS="${HOME}/.scripts"
export XDG_CONFIG_HOME="${HOME}/.config"
export NPM_PATH="${HOME}/.npm-global/bin"

export PATH="$PATH:$DOTNETTOOLS:$SCRIPTS:$XDG_CONFIG_HOME:$NPM_PATH"

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

alias ll='ls -la'
alias n='nvim'

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
