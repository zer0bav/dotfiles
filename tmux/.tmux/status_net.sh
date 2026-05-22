#!/usr/bin/env bash

INTERFACE_FILE="$HOME/.tmux/active_interface"
selected_dev=""

# Check if there is a manually selected interface
if [ -f "$INTERFACE_FILE" ]; then
  selected_dev=$(cat "$INTERFACE_FILE" 2>/dev/null)
fi

vpn_ip=""
vpn_dev=""

# Helper function to get IP address of a device on Linux or macOS
get_ip_of_dev() {
  local dev="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    ifconfig "$dev" 2>/dev/null | awk '/inet / {print $2}'
  else
    if command -v ip >/dev/null 2>&1; then
      ip -4 addr show "$dev" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1
    else
      ifconfig "$dev" 2>/dev/null | awk '/inet / {print $2}'
    fi
  fi
}

if [ -n "$selected_dev" ]; then
  # Try to read the IP of the selected interface
  vpn_ip=$(get_ip_of_dev "$selected_dev")
  vpn_dev="$selected_dev"
fi

# Fallback to auto-detection if no selected interface, or selected interface has no IP
if [ -z "$vpn_ip" ]; then
  # Find first active VPN interface (Linux & macOS standard devices)
  for dev in tun0 tun1 wg0 wg1 ppp0 utun0 utun1 utun2 utun3; do
    ip=$(get_ip_of_dev "$dev")
    if [ -n "$ip" ]; then
      vpn_ip="$ip"
      vpn_dev="$dev"
      break
    fi
  done
fi

# Fallback to local IP if still no IP
if [ -z "$vpn_ip" ]; then
  local_ip=""
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # On macOS, get IP of default gateway interface
    def_dev=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
    if [ -n "$def_dev" ]; then
      local_ip=$(ifconfig "$def_dev" 2>/dev/null | awk '/inet / {print $2}')
    fi
  else
    # On Linux
    if command -v ip >/dev/null 2>&1; then
      local_ip=$(ip -4 addr show wlan0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
      if [ -z "$local_ip" ]; then
        local_ip=$(ip -4 addr show | grep -vE '127.0.0.1|docker|veth|br-|lo' | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
      fi
    else
      local_ip=$(ifconfig wlan0 2>/dev/null | awk '/inet / {print $2}')
      if [ -z "$local_ip" ]; then
        local_ip=$(ifconfig | grep -vE '127.0.0.1|docker|veth|br-|lo' | awk '/inet / {print $2}' | head -n1)
      fi
    fi
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
  if [[ "$vpn_dev" =~ ^(tun|wg|ppp|utun) ]]; then
    color="#ff5555" # Dracula Red for VPNs
    icon="󰆧"
  else
    color="#50fa7b" # Dracula Green for others
    icon="󰖩"
  fi
  printf "#[fg=#44475a]#[bg=#44475a]#[fg=%s]#[bold] %s %s: %s #[bg=default]#[fg=#44475a]" "$color" "$icon" "$vpn_dev" "$vpn_ip"
fi
