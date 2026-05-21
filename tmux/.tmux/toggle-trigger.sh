#!/usr/bin/env bash
trigger=$(tmux list-panes -F '#{pane_id} #{pane_title}' | grep ZEN_SIDEBAR | awk '{print $1}')
if [ -n "$trigger" ]; then
    tmux kill-pane -t "$trigger"
    tmux display-message "  Sidebar: OFF"
else
    tmux split-window -h -l 2 -d "$HOME/.tmux/zen-sidebar.sh"
    tmux display-message "  Sidebar: ON"
fi
