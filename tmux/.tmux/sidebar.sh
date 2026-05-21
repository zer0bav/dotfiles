#!/usr/bin/env bash
DATA="$HOME/.tmux/data"
mkdir -p "$DATA"
touch "$DATA/tasks.txt"
[ ! -s "$DATA/quicklinks.txt" ] && printf ' GitHub|https://github.com\n ChatGPT|https://chatgpt.com\n YouTube|https://youtube.com\n Reddit|https://reddit.com\n ArchWiki|https://wiki.archlinux.org\n' > "$DATA/quicklinks.txt"

THEME=$(cat "$DATA/theme.conf" 2>/dev/null || echo "dracula")
if [ "$THEME" = "blood" ]; then
    FD='--color=fg:#d0d0d0,bg:#0c0c0c,hl:#ff0000 --color=fg+:#ffffff,bg+:#1a1a1a,hl+:#ff3333 --color=info:#aa0000,prompt:#ff0000,pointer:#ff0000 --color=marker:#ff0000,spinner:#ff0000,header:#555555'
    CYAN=$'\033[38;2;200;200;200m'; GREEN=$'\033[38;2;255;50;50m'
    ORANGE=$'\033[38;2;200;50;0m'; PINK=$'\033[38;2;255;0;0m'
    PURPLE=$'\033[38;2;180;0;0m'; RED=$'\033[38;2;255;0;0m'
    YELLOW=$'\033[38;2;255;100;100m'; FG=$'\033[38;2;220;220;220m'
    CM=$'\033[38;2;80;80;80m'; RST=$'\033[0m'; B=$'\033[1m'
else
    # Dracula
    FD='--color=fg:#f8f8f2,bg:#282a36,hl:#ff79c6 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#ff79c6 --color=info:#bd93f9,prompt:#8be9fd,pointer:#ff79c6 --color=marker:#50fa7b,spinner:#bd93f9,header:#6272a4'
    CYAN=$'\033[38;2;139;233;253m'; GREEN=$'\033[38;2;80;250;123m'
    ORANGE=$'\033[38;2;255;184;108m'; PINK=$'\033[38;2;255;121;198m'
    PURPLE=$'\033[38;2;189;147;249m'; RED=$'\033[38;2;255;85;85m'
    YELLOW=$'\033[38;2;241;250;140m'; FG=$'\033[38;2;248;248;242m'
    CM=$'\033[38;2;98;114;164m'; RST=$'\033[0m'; B=$'\033[1m'
fi

title() { clear; echo; printf "  %s%s%s%s  %s%s%s\n  %s%s%s\n\n" "$PURPLE" "$B" "$1" "$RST" "$CM" "$2" "$RST" "$CM" "──────────────────────────────────────" "$RST"; }
wk() { printf "\n  %s any key = back%s" "$CM" "$RST"; read -rsn1; }
dfzf() { fzf --ansi --no-border --no-info --header-first --pointer="" $FD --prompt="  " --height=100% --no-scrollbar --margin=1,1 --history="$DATA/fzf_history.txt" "$@"; }

pomo_st() {
    [ ! -s "$DATA/pomodoro.state" ] && echo "off" && return
    local s d l r
    s=$(sed -n 1p "$DATA/pomodoro.state"); d=$(sed -n 2p "$DATA/pomodoro.state"); l=$(sed -n 3p "$DATA/pomodoro.state")
    [ -z "$s" ] && echo "off" && return
    r=$(( d - ($(date +%s) - s) ))
    [ $r -le 0 ] && echo "DONE" || printf "%s %02d:%02d" "$l" $((r/60)) $((r%60))
}

do_pomo() {
    local st items s d=0 l=""
    st=$(pomo_st); items=()
    [[ "$st" == "DONE" ]] && items+=(" Timer finished!")
    if [[ "$st" == "off" || "$st" == "DONE" ]]; then
        items+=(" Work     25 min" " Short     5 min" " Long    15 min" " Custom")
    else
        items+=(" Running  $st" " Stop timer")
    fi
    s=$(printf '%s\n' "${items[@]}" | dfzf --header=" Pomodoro")
    [ -z "$s" ] && return
    [[ "$s" == *"Work"* ]] && d=1500 && l="WORK"
    [[ "$s" == *"Short"* ]] && d=300 && l="BREAK"
    [[ "$s" == *"Long"* ]] && d=900 && l="BREAK"
    if [[ "$s" == *"Custom"* ]]; then
        title " Custom Timer" ""
        printf "  %sMinutes:%s " "$PINK" "$RST"; read -r m
        [[ "$m" =~ ^[0-9]+$ ]] && d=$((m*60)) && l="TIMER"
    fi
    [[ "$s" == *"Stop"* ]] && rm -f "$DATA/pomodoro.state" && tmux display-message " stopped" && return
    if [ $d -gt 0 ]; then
        printf '%s\n%s\n%s\n' "$(date +%s)" "$d" "$l" > "$DATA/pomodoro.state"
        tmux display-message " $l $((d/60))min started!"
    fi
}

do_tasks() {
    while true; do
        local lines=() display=() i=0
        # Read tasks
        if [ -s "$DATA/tasks.txt" ]; then
            while IFS= read -r line; do
                lines+=("$line")
                i=$((i+1))
            done < "$DATA/tasks.txt"
        fi
        # Build display
        for idx in "${!lines[@]}"; do
            display+=("${lines[$idx]}")
        done
        display+=("──────────────────────")
        display+=(" Add new task")
        display+=(" Clear completed")
        display+=(" Back to menu")

        local sel
        sel=$(printf '%s\n' "${display[@]}" | dfzf --header=" Tasks (enter = toggle)")
        [ -z "$sel" ] && return
        [[ "$sel" == *"Back"* ]] && return
        [[ "$sel" == *"──────"* ]] && continue

        if [[ "$sel" == *"Add new"* ]]; then
            title " New Task" ""
            printf "  %sTask:%s " "$PINK" "$RST"
            read -r newtask
            [ -n "$newtask" ] && echo "[ ] $newtask" >> "$DATA/tasks.txt"
        elif [[ "$sel" == *"Clear completed"* ]]; then
            local tmp="$DATA/tasks.tmp"
            grep -v '^\[x\]' "$DATA/tasks.txt" > "$tmp" 2>/dev/null
            mv "$tmp" "$DATA/tasks.txt"
            tmux display-message " cleared!"
        else
            # Toggle: find exact line and flip
            local tmpfile="$DATA/tasks.tmp"
            local found=0
            > "$tmpfile"
            while IFS= read -r line; do
                if [ "$found" -eq 0 ] && [ "$line" = "$sel" ]; then
                    found=1
                    if [[ "$line" == "[x] "* ]]; then
                        echo "${line/\[x\]/[ ]}" >> "$tmpfile"
                    elif [[ "$line" == "[ ] "* ]]; then
                        echo "${line/\[ \]/[x]}" >> "$tmpfile"
                    else
                        echo "$line" >> "$tmpfile"
                    fi
                else
                    echo "$line" >> "$tmpfile"
                fi
            done < "$DATA/tasks.txt"
            mv "$tmpfile" "$DATA/tasks.txt"
        fi
    done
}

do_links() {
    while true; do
        local items=()
        if [ -s "$DATA/quicklinks.txt" ]; then
            while IFS='|' read -r label url; do
                items+=("$label")
            done < "$DATA/quicklinks.txt"
        fi
        items+=("──────────────────────")
        items+=(" Add link")
        items+=(" Edit link")
        items+=(" Delete link")
        items+=(" Back to menu")

        local sel
        sel=$(printf '%s\n' "${items[@]}" | dfzf --header=" Quick Links  enter=open")
        [ -z "$sel" ] && return
        [[ "$sel" == *"Back"* ]] && return
        [[ "$sel" == *"──────"* ]] && continue

        if [[ "$sel" == *"Add link"* ]]; then
            title " New Link" ""
            printf "  %sName:%s " "$PINK" "$RST"; read -r lname
            printf "  %sURL:%s  " "$PINK" "$RST"; read -r lurl
            [ -n "$lname" ] && [ -n "$lurl" ] && echo "$lname|$lurl" >> "$DATA/quicklinks.txt"
        elif [[ "$sel" == *"Edit link"* ]]; then
            local pick
            pick=$(cut -d'|' -f1 "$DATA/quicklinks.txt" | dfzf --header=" Select to edit")
            [ -z "$pick" ] && continue
            local oldurl
            oldurl=$(grep "^${pick}|" "$DATA/quicklinks.txt" | head -1 | cut -d'|' -f2)
            title " Edit" "$pick"
            printf "  %sCurrent URL:%s %s\n\n" "$CM" "$RST" "$oldurl"
            printf "  %sNew name (enter=keep):%s " "$PINK" "$RST"; read -r nn
            printf "  %sNew URL  (enter=keep):%s " "$PINK" "$RST"; read -r nu
            [ -z "$nn" ] && nn="$pick"
            [ -z "$nu" ] && nu="$oldurl"
            sed -i "s|^$(printf '%s' "$pick" | sed 's|[][\/.*^$]|\\&|g')|.*|${nn}|${nu}|" "$DATA/quicklinks.txt"
        elif [[ "$sel" == *"Delete link"* ]]; then
            local pick
            pick=$(cut -d'|' -f1 "$DATA/quicklinks.txt" | dfzf --header=" Select to delete")
            [ -z "$pick" ] && continue
            local escaped
            escaped=$(printf '%s' "$pick" | sed 's|[][\/.*^$]|\\&|g')
            sed -i "/^${escaped}|/d" "$DATA/quicklinks.txt"
            tmux display-message " deleted"
        else
            local url=""
            while IFS='|' read -r label u; do
                [ "$label" = "$sel" ] && url="$u" && break
            done < "$DATA/quicklinks.txt"
            if [ -n "$url" ]; then
                nohup xdg-open "$url" >/dev/null 2>&1 &
                tmux display-message " opened $url"
                return
            fi
        fi
    done
}

do_cheat() {
    local cmdfile="$DATA/cheat_cmds.txt"
    [ ! -s "$cmdfile" ] && printf 'awk\nbash\nchmod\ncurl\ndocker\nfind\ngit\ngrep\nip\njq\nkill\nless\nnvim\npacman\npython3\nrsync\nsed\nssh\nsystemctl\ntar\ntmux\nxargs\n' > "$cmdfile"
    while true; do
        local cmds=()
        while IFS= read -r c; do [ -n "$c" ] && cmds+=("$c"); done < "$cmdfile"
        cmds+=("──────────────────────")
        cmds+=(" add command")
        cmds+=(" delete command")

        local result cmd=""
        result=$(printf '%s\n' "${cmds[@]}" | fzf --ansi --no-border --no-info --header-first \
            --pointer="" $FD --height=100% --no-scrollbar --margin=1,1 \
            --header=" Cheatsheet  type any command" \
            --prompt="  " --print-query)

        local query=$(echo "$result" | sed -n '1p')
        local selected=$(echo "$result" | sed -n '2p')

        # Handle actions
        if [ -n "$selected" ]; then
            if [[ "$selected" == *"add command"* ]]; then
                title " Add Command" ""
                printf "  %sCommand:%s " "$PINK" "$RST"; read -r newcmd
                if [ -n "$newcmd" ] && ! grep -qx "$newcmd" "$cmdfile"; then
                    echo "$newcmd" >> "$cmdfile"
                    sort -o "$cmdfile" "$cmdfile"
                    tmux display-message " added: $newcmd"
                fi
                continue
            elif [[ "$selected" == *"delete command"* ]]; then
                local del
                del=$(grep -v '^─' "$cmdfile" | grep -v '^ ' | dfzf --header=" Select to delete")
                if [ -n "$del" ]; then
                    sed -i "/^$(printf '%s' "$del" | sed 's|[][\/.*^$]|\\&|g')$/d" "$cmdfile"
                    tmux display-message " deleted: $del"
                fi
                continue
            elif [[ "$selected" == *"──────"* ]]; then
                continue
            fi
            cmd="$selected"
        elif [ -n "$query" ]; then
            cmd="$query"
        else
            return
        fi

        clear; echo
        printf "  %s%s %s%s\n  %s%s%s\n\n" "$PURPLE" "$B" "$cmd" "$RST" "$CM" "──────────────────────────────────────" "$RST"

        if /usr/bin/man -f "$cmd" >/dev/null 2>&1; then
            /usr/bin/man "$cmd" 2>/dev/null | col -bx | dfzf --header=" $cmd Manual (Search parameters)" >/dev/null
        else
            local output
            output=$($cmd --help 2>&1)
            if [ -n "$output" ]; then
                echo "$output" | dfzf --header=" $cmd Help (Search parameters)" >/dev/null
            else
                $cmd -h 2>&1 | dfzf --header=" $cmd Help (Search parameters)" >/dev/null
            fi
        fi
    done
}

do_calc() {
    local last_res=""
    while true; do
        local items=()
        if [ -n "$last_res" ]; then
            items+=("  = $last_res")
            items+=("──────────────────────")
        fi
        items+=(" Type math expression")
        items+=(" Back to menu")
        
        local result expr sel
        result=$(printf '%s\n' "${items[@]}" | dfzf --header=" Calculator" --prompt="> " --print-query --history="$DATA/calc_hist.txt")
        expr=$(echo "$result" | sed -n '1p')
        sel=$(echo "$result" | sed -n '2p')
        
        [[ "$sel" == *"Back"* ]] && return
        [[ "$expr" == "q" || -z "$expr" ]] && return
        
        if [[ -n "$sel" && "$sel" != *"Type math"* && "$sel" != *"─"* && "$sel" != *"="* ]]; then
            expr="$sel"
        fi
        
        last_res=$(echo "scale=4; $expr" | bc -l 2>&1)
    done
}

do_weather() {
    title " Weather" ""
    printf "  %sloading...%s\n" "$CM" "$RST"
    local w
    w=$(curl -s "wttr.in/?0QT" 2>/dev/null)
    if [ -n "$w" ]; then
        clear; echo
        printf "  %s%s Weather%s\n  %s%s%s\n\n" "$PURPLE" "$B" "$RST" "$CM" "──────────────────────────────────────" "$RST"
        echo "$w" | while IFS= read -r l; do printf "  %s\n" "$l"; done
    else
        printf "  %scouldn't reach wttr.in%s\n" "$RED" "$RST"
    fi
    wk
}

do_ssh() {
    local hosts=()
    if [ -f "$HOME/.ssh/config" ]; then
        while read -r h; do
            [ -n "$h" ] && hosts+=(" $h")
        done < <(grep -i "^Host " "$HOME/.ssh/config" 2>/dev/null | awk '{print $2}' | grep -v '\*')
    fi
    [ ${#hosts[@]} -eq 0 ] && hosts+=(" no hosts found")
    hosts+=("──────────────────────" " Back to menu")
    local sel
    sel=$(printf '%s\n' "${hosts[@]}" | dfzf --header=" SSH Hosts")
    [ -z "$sel" ] && return
    [[ "$sel" == *"Back"* || "$sel" == *"──────"* || "$sel" == *"no hosts"* ]] && return
    local host
    host=$(echo "$sel" | awk '{print $2}')
    tmux new-window -n "ssh:$host" "ssh $host"
}

do_git() {
    local pp
    pp=$(tmux display-message -p '#{pane_current_path}')
    title " Git" "$(echo "$pp" | sed "s|$HOME|~|")"
    if git -C "$pp" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf "  %s %s%s\n\n" "$PURPLE" "$(git -C "$pp" branch --show-current 2>/dev/null)" "$RST"
        local st
        st=$(git -C "$pp" status --short 2>/dev/null)
        if [ -n "$st" ]; then
            echo "$st" | head -15 | while read -r l; do
                case "${l:0:2}" in
                    "M "*|" M") printf "  %s%s%s\n" "$ORANGE" "$l" "$RST" ;;
                    "A "*|"??"*) printf "  %s%s%s\n" "$GREEN" "$l" "$RST" ;;
                    "D "*|" D") printf "  %s%s%s\n" "$RED" "$l" "$RST" ;;
                    *) printf "  %s%s%s\n" "$YELLOW" "$l" "$RST" ;;
                esac
            done
        else
            printf "  %s clean%s\n" "$GREEN" "$RST"
        fi
        printf "\n  %srecent commits%s\n" "$CM" "$RST"
        git -C "$pp" log --oneline -5 2>/dev/null | while read -r l; do
            printf "  %s%s%s %s%s%s\n" "$YELLOW" "${l%% *}" "$RST" "$FG" "${l#* }" "$RST"
        done
    else
        printf "  %s not a git repo%s\n" "$RED" "$RST"
    fi
    wk
}

do_procs() {
    title " Processes" ""
    printf "  %s%-7s %-5s %-5s %s%s\n" "$PURPLE" "PID" "CPU" "MEM" "CMD" "$RST"
    printf "  %s─────── ───── ───── ──────────────%s\n" "$CM" "$RST"
    ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=14 {printf "%-7s %-5s %-5s %s\n",$2,$3,$4,$11}' | while read -r l; do
        printf "  %s%s%s\n" "$CYAN" "$l" "$RST"
    done
    wk
}

do_sys() {
    title " System" "$(hostname)"
    local mem disk load
    mem=$(free -h 2>/dev/null | awk '/Mem:/{printf "%s / %s",$3,$2}')
    disk=$(df -h / 2>/dev/null | awk 'NR==2{printf "%s / %s (%s)",$3,$2,$5}')
    load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)
    printf "  %s%-12s%s %s%s%s\n" "$CYAN" "User" "$RST" "$FG" "$(whoami)" "$RST"
    printf "  %s%-12s%s %s%s%s\n" "$CYAN" "Kernel" "$RST" "$FG" "$(uname -r)" "$RST"
    printf "  %s%-12s%s %s%s%s\n" "$CYAN" "Uptime" "$RST" "$FG" "$(uptime -p 2>/dev/null | sed 's/up //')" "$RST"
    printf "  %s%-12s%s %s%s cores%s\n" "$CYAN" "CPU" "$RST" "$FG" "$(nproc 2>/dev/null)" "$RST"
    printf "  %s%-12s%s %s%s%s\n" "$CYAN" "Load" "$RST" "$FG" "$load" "$RST"
    printf "  %s%-12s%s %s%s%s\n" "$CYAN" "Memory" "$RST" "$FG" "$mem" "$RST"
    printf "  %s%-12s%s %s%s%s\n" "$CYAN" "Disk /" "$RST" "$FG" "$disk" "$RST"
    printf "  %s%-12s%s %s%s%s\n" "$CYAN" "Shell" "$RST" "$FG" "$SHELL" "$RST"
    printf "  %s%-12s%s %s%s%s\n" "$CYAN" "Tmux" "$RST" "$FG" "$(tmux -V)" "$RST"
    wk
}

do_net() {
    title " Network" ""
    ip -br addr 2>/dev/null | while read -r i s a r; do
        local c="$GREEN"; [[ "$s" == "DOWN" ]] && c="$RED"
        printf "  %s%-11s%s %s%-5s%s %s%s%s\n" "$c" "$i" "$RST" "$CM" "$s" "$RST" "$FG" "$a" "$RST"
    done
    printf "\n  %sgateway%s\n" "$CM" "$RST"
    ip route 2>/dev/null | grep default | head -1 | awk -v c="$CYAN" -v r="$RST" '{printf "  %s%s via %s%s\n",c,$5,$3,r}'
    printf "\n  %sdns%s\n" "$CM" "$RST"
    grep nameserver /etc/resolv.conf 2>/dev/null | awk -v c="$CYAN" -v r="$RST" '{printf "  %s%s%s\n",c,$2,r}'
    wk
}

do_sessions() {
    while true; do
        local items=()
        while IFS= read -r s; do
            items+=("  $s")
        done < <(tmux list-sessions -F '#S  (#{session_windows} windows)')
        items+=("──────────────────────")
        items+=("  New Session")
        items+=("  Rename Session")
        items+=("  Kill Session")
        items+=("  Back to menu")

        local sel
        sel=$(printf '%s\n' "${items[@]}" | dfzf --header=" Sessions Management")
        [ -z "$sel" ] && return
        [[ "$sel" == *"Back"* ]] && return
        [[ "$sel" == *"──────"* ]] && continue

        if [[ "$sel" == *"New Session"* ]]; then
            title " New Session" ""
            printf "  %sSession Name:%s " "$PINK" "$RST"; read -r sname
            if [ -n "$sname" ]; then
                tmux new-session -d -s "$sname" && tmux switch-client -t "$sname"
                exit 0
            fi
        elif [[ "$sel" == *"Rename Session"* ]]; then
            local target
            target=$(tmux list-sessions -F '#S' | dfzf --header=" Select Session to Rename")
            [ -z "$target" ] && continue
            title " Rename Session" "Target: $target"
            printf "  %sNew Name:%s " "$PINK" "$RST"; read -r sname
            [ -n "$sname" ] && tmux rename-session -t "$target" "$sname" && tmux display-message " Renamed $target to $sname"
        elif [[ "$sel" == *"Kill Session"* ]]; then
            local target
            target=$(tmux list-sessions -F '#S' | dfzf --header=" Select Session to Kill")
            if [ -n "$target" ]; then
                tmux kill-session -t "$target"
                tmux display-message " Session $target killed"
            fi
        else
            # Switch to selected session
            local target
            target=$(echo "$sel" | awk '{print $1}')
            if [ -n "$target" ]; then
                tmux switch-client -t "$target"
                exit 0
            fi
        fi
    done
}

do_help() {
    title " Keybindings & Shortcuts" ""
    printf "  %sTercast UI%s\n" "$PINK" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a b" "$RST" "$CM" "Open Tercast sidebar" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a g" "$RST" "$CM" "Quick Git status" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a p" "$RST" "$CM" "Quick Pomodoro" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a ?" "$RST" "$CM" "Open Keybindings" "$RST"
    
    printf "\n  %sPanes & Navigation%s\n" "$PINK" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-h/j/k/l" "$RST" "$CM" "Navigate between panes" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-M-h/l" "$RST" "$CM" "Prev/Next window" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "M-h/j/k/l" "$RST" "$CM" "Resize active pane" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a z" "$RST" "$CM" "Toggle zoom (fullscreen pane)" "$RST"
    
    printf "\n  %sWindows & Sessions%s\n" "$PINK" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a c" "$RST" "$CM" "Create new window" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a |" "$RST" "$CM" "Split pane horizontally" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a -" "$RST" "$CM" "Split pane vertically" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a ," "$RST" "$CM" "Rename current window" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a w" "$RST" "$CM" "List windows (tmux default)" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a s" "$RST" "$CM" "List sessions (tmux default)" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a d" "$RST" "$CM" "Detach from session" "$RST"
    
    printf "\n  %sCopy Mode%s\n" "$PINK" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a [" "$RST" "$CM" "Enter copy mode (scroll/select)" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-a ]" "$RST" "$CM" "Paste from tmux buffer" "$RST"
    
    printf "\n  %sInside Tercast%s\n" "$PINK" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-n" "$RST" "$CM" "New window (silent)" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-k" "$RST" "$CM" "Kill window (silent)" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "C-r" "$RST" "$CM" "Reload configuration" "$RST"
    printf "  %s%-13s%s %s%s%s\n" "$CYAN" "Esc" "$RST" "$CM" "Go back / close Tercast" "$RST"
    wk
}

do_theme() {
    local themes=(" dracula" " blood (black & red)")
    local sel=$(printf '%s\n' "${themes[@]}" | dfzf --header=" Select Theme")
    [ -z "$sel" ] && return
    if [[ "$sel" == *"blood"* ]]; then
        echo "blood" > "$DATA/theme.conf"
        tmux bind b display-popup -E -x R -w 35% -h 100% -S "fg=#ff0000" -s "bg=#0c0c0c" "~/.tmux/sidebar.sh"
        tmux display-message " Theme set to Blood! Reloading..."
    else
        echo "dracula" > "$DATA/theme.conf"
        tmux bind b display-popup -E -x R -w 35% -h 100% -S "fg=#bd93f9" -s "bg=#282a36" "~/.tmux/sidebar.sh"
        tmux display-message " Theme set to Dracula! Reloading..."
    fi
}

do_notes() {
    local notefile="$DATA/notes.txt"
    [ ! -f "$notefile" ] && touch "$notefile"
    while true; do
        local result
        result=$(tac "$notefile" | dfzf --header=" Notes (Type to search, or type new note and press Enter to save)" --print-query)
        
        local query=$(echo "$result" | sed -n '1p')
        local selected=$(echo "$result" | sed -n '2p')

        if [ -n "$selected" ]; then
            title " Note Action" "$selected"
            printf "  %s[c]opy, [d]elete, or any key to cancel:%s " "$PINK" "$RST"
            read -rsn1 act
            if [ "$act" = "c" ]; then
                echo -n "$selected" | wl-copy 2>/dev/null || echo -n "$selected" | xclip -selection clipboard 2>/dev/null
                tmux display-message " Note copied!"
            elif [ "$act" = "d" ]; then
                grep -vxF "$selected" "$notefile" > "${notefile}.tmp" && mv "${notefile}.tmp" "$notefile"
                tmux display-message " Note deleted!"
            fi
        elif [ -n "$query" ]; then
            echo "$query" >> "$notefile"
            tmux display-message " Note saved!"
        else
            return
        fi
    done
}

# ══════════════════════════════════════
#  MAIN LOOP (TERCAST)
# ══════════════════════════════════════
while true; do
    SESSION=$(tmux display-message -p '#S')
    WIN_COUNT=$(tmux list-windows | wc -l)
    PANE_COUNT=$(tmux list-panes | wc -l)
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' | head -c 22)
    pomo=$(pomo_st)
    pending=$(grep -c '^\[ \]' "$DATA/tasks.txt" 2>/dev/null || echo 0)
    total_tasks=$(wc -l < "$DATA/tasks.txt" 2>/dev/null || echo 0)

    items=()
    while IFS=$'\t' read -r idx name active cmd; do
        if [ "$active" = "1" ]; then
            items+=("W${idx}: ${idx}  ${name}  ${cmd}")
        else
            items+=("W${idx}: ${idx}  ${name}  ${cmd}")
        fi
    done < <(tmux list-windows -F '#{window_index}	#{window_name}	#{window_active}	#{pane_current_command}')

    items+=("---: ")
    items+=("kill: Kill Window")
    items+=("new: New Window")
    items+=("rename: Rename Window")
    items+=("---: ")
    items+=("panes: Pane Layout")
    items+=("sessions: Sessions")
    items+=("---: ")
    items+=("calc: Calculator")
    items+=("cheat: Cheatsheet")
    items+=("clipboard: Clipboard")
    items+=("git: Git Status")
    items+=("links: Quick Links")
    items+=("net: Network")
    if [ "$pomo" = "off" ]; then
        items+=("pomodoro: Pomodoro")
    else
        items+=("pomodoro: Pomodoro  $pomo")
    fi
    items+=("procs: Processes")
    items+=("notes: Quick Notes")
    items+=("ssh: SSH Hosts")
    items+=("sysinfo: System Info")
    if [ "$total_tasks" -gt 0 ]; then
        items+=("tasks: Tasks  ${pending}/${total_tasks}")
    else
        items+=("tasks: Tasks")
    fi
    items+=("theme: Theme Options")
    items+=("weather: Weather")
    items+=("---: ")
    items+=("help: Keybindings")
    items+=("reload: Reload Config")

    display=()
    for e in "${items[@]}"; do display+=("$(echo "$e" | cut -d: -f2-)"); done

    hdr=$(printf '  %s   %sw  %sp   %s' "TERCAST ($SESSION)" "$WIN_COUNT" "$PANE_COUNT" "$UPTIME")
    sel=$(printf '%s\n' "${display[@]}" | fzf --ansi --no-border --no-info \
        --header="$hdr" --header-first --pointer="" $FD \
        --prompt="  " --height=100% --layout=default --no-scrollbar --margin=1,1 \
        --bind="ctrl-n:execute-silent(tmux new-window)+reload(~/.tmux/sidebar-list.sh)" \
        --bind="ctrl-k:execute-silent(tmux kill-window)+reload(~/.tmux/sidebar-list.sh)" \
        --bind="ctrl-r:execute-silent(tmux source-file ~/.tmux.conf)")

    [ -z "$sel" ] && exit 0
    [[ "$sel" =~ ^[[:space:]]*$ ]] && continue

    matched=0
    for e in "${items[@]}"; do
        d=$(echo "$e" | cut -d: -f2-)
        [ "$d" != "$sel" ] && continue
        k=$(echo "$e" | cut -d: -f1)
        matched=1
        case "$k" in
            W*) tmux select-window -t ":${k#W}"; exit 0 ;;
            ---) break ;;
            new) tmux new-window; exit 0 ;;
            kill) tmux kill-window; exit 0 ;;
            rename) title " Rename" "$(tmux display-message -p '#W')"; printf "  %sName:%s " "$PINK" "$RST"; read -r n; [ -n "$n" ] && tmux rename-window "$n" ;;
            sessions) do_sessions ;;
            panes) p=$(printf ' even-horizontal\n even-vertical\n main-horizontal\n main-vertical\n tiled' | dfzf --header=" Layout"); [ -n "$p" ] && tmux select-layout "$(echo "$p" | awk '{print $2}')" ;;
            calc) do_calc ;;
            cheat) do_cheat ;;
            clipboard)
                title " Clipboard" ""
                local clip=""
                if command -v wl-paste >/dev/null 2>&1; then
                    clip=$(wl-paste -t text/plain 2>/dev/null)
                elif command -v xclip >/dev/null 2>&1; then
                    clip=$(xclip -selection clipboard -o 2>/dev/null)
                fi
                if [ -z "$clip" ]; then
                    printf "  %sClipboard is empty or contains non-text data.%s\n" "$RED" "$RST"
                    wk
                else
                    echo "$clip" | dfzf --header=" Clipboard Content" >/dev/null
                fi
                ;;
            git) do_git ;;
            links) do_links ;;
            net) do_net ;;
            pomodoro) do_pomo ;;
            procs) do_procs ;;
            notes) do_notes ;;
            ssh) do_ssh ;;
            sysinfo) do_sys ;;
            tasks) do_tasks ;;
            theme) do_theme; break ;;
            weather) do_weather ;;
            help) do_help ;;
            reload) tmux source-file ~/.tmux.conf; tmux display-message " reloaded!" ;;
        esac
        break
    done
done
