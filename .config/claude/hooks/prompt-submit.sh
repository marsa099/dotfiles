#!/bin/bash

# Claude Code UserPromptSubmit Hook - tmux Integration
# Triggers when user submits a prompt to Claude
# Updates tmux pane title to show "Processing" state

# Update tmux pane title to show "processing" state
if [ -n "$TMUX" ]; then
    printf '\033]2;Claude: Processing... 🤔\033\\'
fi
