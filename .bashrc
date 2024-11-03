#
# ~/.bashrc
#
echo "Reading bashrc"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# If ~/.inputrc doesn't exist yet: First include the original /etc/inputrc
# so it won't get overriden
if [ ! -a ~/.inputrc ]; then echo '$include /etc/inputrc' > ~/.inputrc; fi

# Make sure ^[[200~ is not a part of the paste output from the clipboard
bind 'set enable-bracketed-paste off'

# Add shell-option to ~/.inputrc to enable case-insensitive tab completion
echo 'set completion-ignore-case On' >> ~/.inputrc

# Sets az devops PAT to env var
export AZURE_DEVOPS_EXT_PAT=$(pass sis/devops/pat)

alias PAGER=less

alias cl=clear
alias ls='ls --color=auto'
alias grep='grep --color=auto'
#PS1='[\e[1m\W]\$ \e(B\e[m'
PS1='\[\e[32m\][\e[1m\W]\$ \e(B\e[m'

# Environment variables
export REPOS="${HOME}/repos"
export EDITOR=nvim
export BROWSER=firefox

# Path
export DOTNETTOOLS='~/.dotnet/tools'
export SCRIPTS="${HOME}/.scripts"
export XDG_CONFIG_HOME="${HOME}/.config"
export NPM_PATH='~/.npm-global/bin'

export PATH="$PATH:$DOTNETTOOLS:$SCRIPTS:$XDG_CONFIG_HOME:$NPM_PATH"

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

# Scripts
alias azkv='python3 ~/.scripts/az-keyvault.py'

# .bashrc
alias rbc='source ~/.bashrc'
alias ebc='$EDITOR ~/.bashrc'

# i3/.config
alias i3conf='$EDITOR ~/.config/i3/config'

echo "Reading bashrc done"
