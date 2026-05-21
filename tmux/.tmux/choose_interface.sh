#!/usr/bin/env bash

# Fetch all interfaces with their IPv4 address (excluding loopback)
interfaces=$(ip -4 -o addr show | awk '{print $2, $4}' | cut -d/ -f1 | grep -v 'lo')

# Construct tmux display-menu command
cmd="tmux display-menu -T 'Select Network Interface' -x C -y C"

# Add Auto-detect option
cmd="$cmd 'Auto-Detect (Default)' 'a' 'run-shell \"rm -f \$HOME/.tmux/active_interface && tmux refresh-client -S\"'"

# Index for shortcuts (1, 2, 3...)
idx=1

# Loop through interfaces and add them to the menu
while read -r line; do
  if [ -z "$line" ]; then continue; fi
  dev=$(echo "$line" | awk '{print $1}')
  ip=$(echo "$line" | awk '{print $2}')
  
  # Limit to 9 items for simple hotkeys 1-9
  if [ $idx -le 9 ]; then
    cmd="$cmd '$dev: $ip' '$idx' 'run-shell \"echo -n $dev > \$HOME/.tmux/active_interface && tmux refresh-client -S\"'"
    idx=$((idx + 1))
  fi
done <<< "$interfaces"

# Execute the dynamic tmux menu
eval "$cmd"
