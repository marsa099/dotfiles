#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export REPOS="${HOME}/repos"
export EDITOR=nvim
export BROWSER=firefox

alias config='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias c=config

alias ll='ls -la'

alias rbc='source ~/.bashrc'
alias ebc='$EDITOR .bashrc'
