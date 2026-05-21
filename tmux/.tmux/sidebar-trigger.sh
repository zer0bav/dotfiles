#!/usr/bin/env bash
# Zen Sidebar Trigger Zone - Hacker Edition
# Runs in narrow pane on right edge

# Set pane title for hook identification
printf '\033]2;ZEN_SIDEBAR\033\\'

# Hacker green
G='\033[38;2;0;255;65m'
GD='\033[38;2;0;80;25m'
GDD='\033[38;2;0;40;12m'
BG='\033[48;2;10;14;20m'
RST='\033[0m'

draw() {
    local rows=$(tput lines 2>/dev/null || echo 40)
    printf '\033[2J'
    local mid=$((rows / 2))
    for ((i=1; i<=rows; i++)); do
        if [ $i -eq $mid ]; then
            printf "\033[${i};1H${BG}${G}◂${RST}"
        elif [ $i -eq $((mid-1)) ] || [ $i -eq $((mid+1)) ]; then
            printf "\033[${i};1H${BG}${GD}┃${RST}"
        elif [ $i -eq $((mid-2)) ] || [ $i -eq $((mid+2)) ]; then
            printf "\033[${i};1H${BG}${GDD}╏${RST}"
        else
            printf "\033[${i};1H${BG}${GDD}·${RST}"
        fi
    done
}

trap 'draw' WINCH
draw
while true; do sleep 86400 & wait $!; done
