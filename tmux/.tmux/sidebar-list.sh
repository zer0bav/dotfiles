#!/usr/bin/env bash
DATA="$HOME/.tmux/data"
pomo_status() {
    local state="$DATA/pomodoro.state"
    [ ! -f "$state" ] && echo "OFF" && return
    local start=$(head -1 "$state" 2>/dev/null)
    local dur=$(sed -n '2p' "$state" 2>/dev/null)
    local label=$(sed -n '3p' "$state" 2>/dev/null)
    [ -z "$start" ] && echo "OFF" && return
    local now=$(date +%s); local remain=$(( dur - (now - start) ))
    if [ $remain -le 0 ]; then echo "DONE"
    else printf "%s %02d:%02d" "$label" "$((remain/60))" "$((remain%60))"; fi
}
pomo=$(pomo_status)
task_count=$(grep -c '^ ' "$DATA/tasks.txt" 2>/dev/null || echo 0)
while IFS=$'\t' read -r idx name active cmd; do
    if [ "$active" = "1" ]; then printf '  %s  %s  %s\n' "$idx" "$name" "$cmd"
    else printf '  %s  %s  %s\n' "$idx" "$name" "$cmd"; fi
done < <(tmux list-windows -F '#{window_index}	#{window_name}	#{window_active}	#{pane_current_command}')
printf ' \n'
printf '   New Window\n'
printf ' 󰗼  Kill Window\n'
printf '   Rename Window\n'
printf ' \n'
printf '   Sessions\n'
printf '   Pane Layout\n'
printf ' \n'
printf ' 󰄉  Pomodoro  %s\n' "$pomo"
printf '   Tasks  %s pending\n' "$task_count"
printf '   Quick Links\n'
printf ' 󰏫  Scratchpad\n'
printf ' \n'
printf '   Git Status\n'
printf '   Processes\n'
printf ' 󰃰  System Info\n'
printf ' 󰈀  Network\n'
printf ' \n'
printf '   Reload Config\n'
printf '   Keybindings\n'
