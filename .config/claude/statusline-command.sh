#!/bin/bash

# Get the current directory
current_dir=$(pwd)

# Get the branch name (skip optional locks for git commands)
branch=$(cd "$current_dir" && git -c core.fileMode=false rev-parse --abbrev-ref HEAD 2>/dev/null)

# Get the folder name
folder=$(basename "$current_dir")

# If we have a branch name, show it on the left
if [ -n "$branch" ]; then
    printf '%s  ' "$branch"
fi

# Show the folder name in bold green on the right
printf '\e[32m\e[1m%s\e[0m' "$folder"
