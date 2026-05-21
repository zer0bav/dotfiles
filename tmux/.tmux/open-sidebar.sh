#!/usr/bin/env bash
# Open or focus the sidebar pane
sidebar=$(tmux list-panes -F '#{pane_id} #{pane_title}' | grep ZEN_SIDEBAR | awk '{print $1}')
if [ -n "$sidebar" ]; then
    tmux select-pane -t "$sidebar"
else
    tmux split-window -h -l 2 "$HOME/.tmux/zen-sidebar.sh"
fi
