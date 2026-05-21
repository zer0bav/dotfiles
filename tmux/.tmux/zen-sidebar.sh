#!/usr/bin/env bash
printf '\033]2;ZEN_SIDEBAR\033\\'

G='\033[38;2;0;255;65m'
GD='\033[38;2;0;80;25m'
GDD='\033[38;2;0;40;12m'
C='\033[38;2;0;212;255m'
RST='\033[0m'

expand() {
    local total=$(tmux display-message -p '#{window_width}')
    local target=$((total * 28 / 100))
    [ $target -lt 20 ] && target=20
    tmux resize-pane -x $target
}

collapse() { tmux resize-pane -x 2 2>/dev/null; }

draw_trigger() {
    clear
    local rows=$(tput lines 2>/dev/null || echo 40)
    local mid=$((rows / 2))
    for ((i=1; i<=rows; i++)); do
        if [ $i -eq $mid ]; then
            printf "\033[${i};1H${G}◂${RST}"
        elif [ $i -eq $((mid-1)) ] || [ $i -eq $((mid+1)) ]; then
            printf "\033[${i};1H${GD}┃${RST}"
        else
            printf "\033[${i};1H${GDD}·${RST}"
        fi
    done
}

run_sidebar() {
    expand
    local SESSION=$(tmux display-message -p '#S')
    local WIN_COUNT=$(tmux list-windows | wc -l)
    local PANE_COUNT=$(tmux list-panes | wc -l)
    local UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' | head -c 20)

    local entries=()
    while IFS=$'\t' read -r idx name active cmd path; do
        local sp=$(echo "$path" | sed "s|$HOME|~|")
        if [ "$active" = "1" ]; then
            entries+=("$(printf ' ▶  %-2s │ %-15s  %s' "$idx" "${name:0:15}" "${sp:0:22}")")
        else
            entries+=("$(printf '    %-2s │ %-15s  %s' "$idx" "${name:0:15}" "${sp:0:22}")")
        fi
    done < <(tmux list-windows -F '#{window_index}	#{window_name}	#{window_active}	#{pane_current_command}	#{pane_current_path}')

    local actions=(
        "┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈"
        "    New Window"
        " 󰗼  Kill Window"
        "    Sessions"
        "    Reload Config"
    )

    local all=()
    for e in "${entries[@]}"; do all+=("$e"); done
    for a in "${actions[@]}"; do all+=("$a"); done

    local hdr=$(printf ' ⟬%s⟭ %sw %sp  ⏱%s' "$SESSION" "$WIN_COUNT" "$PANE_COUNT" "$UPTIME")

    local selected
    selected=$(printf '%s\n' "${all[@]}" | fzf \
        --ansi --no-border --no-info \
        --header="$hdr" --header-first --pointer="›" \
        --color="fg:#00ff41,bg:#0a0e14,hl:#00d4ff" \
        --color="fg+:#00ff41,bg+:#112a18,hl+:#00d4ff" \
        --color="info:#00d4ff,prompt:#00ff41,pointer:#00ff41" \
        --color="marker:#ff0,spinner:#00ff41,header:#00d4ff" \
        --prompt=" ❯ " --height=100% --no-scrollbar --margin=1,0)

    collapse
    tmux select-pane -l 2>/dev/null

    [ -z "$selected" ] && return
    [[ "$selected" == *"┈┈"* ]] && return
    if [[ "$selected" == *"New Window"* ]]; then tmux new-window
    elif [[ "$selected" == *"Kill Window"* ]]; then tmux confirm-before -p "Kill? (y/n)" kill-window
    elif [[ "$selected" == *"Sessions"* ]]; then tmux choose-session
    elif [[ "$selected" == *"Reload"* ]]; then tmux source-file ~/.tmux.conf && tmux display-message " Reloaded!"
    else
        local wn=$(echo "$selected" | grep -oP '\d+(?= │)')
        [ -n "$wn" ] && tmux select-window -t ":${wn}"
    fi
}

# First run: if already focused, open immediately
if [ "$(tmux display-message -p '#{pane_active}')" = "1" ]; then
    run_sidebar
fi

# Main loop
while true; do
    collapse
    draw_trigger
    while [ "$(tmux display-message -p '#{pane_active}')" != "1" ]; do
        sleep 0.12
    done
    run_sidebar
done
