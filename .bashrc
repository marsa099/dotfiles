#
# ~/.bashrc
#
echo "Reading bashrc"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\e[1m\W]\$ \e(B\e[m'

export REPOS="${HOME}/repos"
export EDITOR=nvim
export BROWSER=firefox

# Git
alias config='git --git-dir=$HOME/.git/ --work-tree=$HOME'
alias c=config
alias g=git

# Wifi
alias wifi='iwctl'
alias connect-mobile='~/.scripts/connect-wifi.sh martin'

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
