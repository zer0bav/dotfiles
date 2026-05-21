#!/usr/bin/env bash
if ! tmux list-panes -F '#{pane_title}' 2>/dev/null | grep -q 'ZEN_SIDEBAR'; then
    tmux split-window -h -l 2 -d "$HOME/.tmux/zen-sidebar.sh"
fi
