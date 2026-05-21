#!/usr/bin/env bash
# Collapse sidebar if it's expanded (called by hook when clicking away)
info=$(tmux list-panes -F '#{pane_id} #{pane_title} #{pane_width}' | grep ZEN_SIDEBAR)
[ -z "$info" ] && exit 0
width=$(echo "$info" | awk '{print $3}')
if [ "$width" -gt 5 ]; then
    id=$(echo "$info" | awk '{print $1}')
    tmux resize-pane -t "$id" -x 2
    tmux send-keys -t "$id" C-c 2>/dev/null
fi
