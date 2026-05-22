#!/usr/bin/env bash

# Read capacity and status dynamically
if [[ "$OSTYPE" == "darwin"* ]]; then
  batt_info=$(pmset -g batt 2>/dev/null)
  capacity=$(echo "$batt_info" | grep -oE '[0-9]+%' | head -n1 | tr -d '%')
  if echo "$batt_info" | grep -q 'charging'; then
    status="Charging"
  elif echo "$batt_info" | grep -q 'discharging'; then
    status="Discharging"
  else
    status="Full"
  fi
else
  capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
  status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
  if [ -z "$capacity" ]; then
    capacity=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
    status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)
  fi
fi

if [ -z "$capacity" ]; then
  exit 0
fi

# Determine battery icon and color based on state and percentage
color="#8be9fd" # Default Dracula Cyan
icon="󰁹"

if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
  icon="󰂄"
  color="#50fa7b" # Dracula Green for charging
else
  # Discharging icons based on percentage
  if [ "$capacity" -ge 90 ]; then
    icon="󰁹"
  elif [ "$capacity" -ge 80 ]; then
    icon="󰂂"
  elif [ "$capacity" -ge 70 ]; then
    icon="󰂁"
  elif [ "$capacity" -ge 60 ]; then
    icon="󰂀"
  elif [ "$capacity" -ge 50 ]; then
    icon="󰁿"
  elif [ "$capacity" -ge 40 ]; then
    icon="󰁾"
  elif [ "$capacity" -ge 30 ]; then
    icon="󰁽"
  elif [ "$capacity" -ge 20 ]; then
    icon="󰁼"
    color="#f1fa8c" # Dracula Yellow (warning)
  else
    icon="󰁺"
    color="#ff5555" # Dracula Red (low battery)
  fi
fi

# Output formatted pill
printf "#[fg=#44475a]#[bg=#44475a]#[fg=%s]#[bold]%s %s%% #[bg=default]#[fg=#44475a]" "$color" "$icon" "$capacity"
