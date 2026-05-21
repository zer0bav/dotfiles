#!/usr/bin/env bash

TARGET_FILE="$HOME/.tmux/target_ip"

# Set target IP if argument provided
if [ -n "$1" ]; then
  if [ "$1" = "clear" ]; then
    rm -f "$TARGET_FILE"
    tmux display-message "🎯 Target IP cleared"
  else
    echo -n "$1" > "$TARGET_FILE"
    # Copy to Wayland clipboard if wl-copy exists
    if command -v wl-copy >/dev/null 2>&1; then
      echo -n "$1" | wl-copy
      tmux display-message "🎯 Target set and copied to clipboard: $1"
    else
      tmux display-message "🎯 Target set: $1"
    fi
  fi
  tmux refresh-client -S
  exit 0
fi

# Read and print target IP if file exists
if [ -f "$TARGET_FILE" ]; then
  target=$(cat "$TARGET_FILE")
  if [ -n "$target" ]; then
    # Dracula Orange (#ffb86c) text on grey background
    printf "#[fg=#44475a]#[bg=#44475a]#[fg=#ffb86c]#[bold] 󰓾 %s #[bg=default]#[fg=#44475a]" "$target"
  fi
fi
