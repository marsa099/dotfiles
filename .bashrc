#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Make sure ^[[200~ is not a part of the paste output from the clipboard
bind 'set enable-bracketed-paste off'

# History settings
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend
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

# i3/.config
alias i3conf='$EDITOR ~/.config/i3/config'

