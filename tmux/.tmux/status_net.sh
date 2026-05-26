#!/usr/bin/env bash

INTERFACE_FILE="$HOME/.tmux/active_interface"
selected_dev=""

# Check if there is a manually selected interface
if [ -f "$INTERFACE_FILE" ]; then
  selected_dev=$(cat "$INTERFACE_FILE" 2>/dev/null)
fi

vpn_ip=""
vpn_dev=""

if [ -n "$selected_dev" ]; then
  # Try to read the IP of the selected interface
  vpn_ip=$(ip -4 addr show "$selected_dev" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
  vpn_dev="$selected_dev"
fi

# Fallback to auto-detection if no selected interface, or selected interface has no IP
if [ -z "$vpn_ip" ]; then
  # Find first active VPN interface
  for dev in tun0 tun1 wg0 wg1 ppp0; do
    ip=$(ip -4 addr show "$dev" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
    if [ -n "$ip" ]; then
      vpn_ip="$ip"
      vpn_dev="$dev"
      break
    fi
  done
fi

# Fallback to local IP if still no IP
if [ -z "$vpn_ip" ]; then
  local_ip=$(ip -4 addr show wlan0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
  if [ -z "$local_ip" ]; then
    local_ip=$(ip -4 addr show | grep -vE '127.0.0.1|docker|veth|br-|lo' | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
  fi
  
  if [ -n "$local_ip" ]; then
    # Local Connected: Dracula Green (#50fa7b) text on grey background
    printf "#[fg=#44475a]#[bg=#44475a]#[fg=#50fa7b]#[bold] 󰖩 %s #[bg=default]#[fg=#44475a]" "$local_ip"
  else
    # Offline
    printf "#[fg=#44475a]#[bg=#44475a]#[fg=#ff5555]#[bold] 󰖪 Offline #[bg=default]#[fg=#44475a]"
  fi
else
  # Display selected or detected active interface
  if [[ "$vpn_dev" =~ ^(tun|wg|ppp) ]]; then
    color="#ff5555" # Dracula Red for VPNs
    icon="󰆧"
  else
    color="#50fa7b" # Dracula Green for others
    icon="󰖩"
  fi
  printf "#[fg=#44475a]#[bg=#44475a]#[fg=%s]#[bold] %s %s: %s #[bg=default]#[fg=#44475a]" "$color" "$icon" "$vpn_dev" "$vpn_ip"
fi
