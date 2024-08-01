#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\e[1m\W]\$ \e(B\e[m'

export REPOS="${HOME}/repos"
export EDITOR=nvim
export BROWSER=firefox

# Git
alias config='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias c=config
alias g=git

# Wifi
alias wifi='iwctl'

alias ll='ls -la'

alias rbc='source ~/.bashrc'
alias ebc='$EDITOR .bashrc'
