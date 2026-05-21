#!/usr/bin/env bash

path="$(tmux display-message -p -F '#{pane_current_path}' 2>/dev/null || echo "$1")"
path="${path/#$HOME/~}"

if [ -z "$path" ]; then
  printf "~"
  exit 0
fi

if [ "$path" = "~" ] || [ "$path" = "/" ]; then
  printf "%s" "$path"
  exit 0
fi

IFS='/' read -r -a parts <<< "$path"
count=${#parts[@]}

if [ $count -ge 2 ]; then
  printf "%s/%s" "${parts[$((count-2))]}" "${parts[$((count-1))]}"
else
  printf "%s" "$path"
fi
