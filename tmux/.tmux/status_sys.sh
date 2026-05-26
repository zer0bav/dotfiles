#!/usr/bin/env bash

# Fetch CPU usage
cpu="$(awk -v FS=' ' '/^cpu /{printf("%.0f", 100-($5*100)/($2+$3+$4+$5+$6+$7+$8))}' /proc/stat 2>/dev/null)"
[ -z "$cpu" ] && cpu="?"

# Fetch Memory usage
mem="$(free -m 2>/dev/null | awk '/Mem:/ {printf("%d", $3*100/$2)}')"
[ -z "$mem" ] && mem="?"

# Fetch Intel GPU usage (frequency ratio)
act=$(cat /sys/class/drm/card1/gt_act_freq_mhz 2>/dev/null)
max=$(cat /sys/class/drm/card1/gt_max_freq_mhz 2>/dev/null)
if [ -n "$act" ] && [ -n "$max" ] && [ "$max" -gt 0 ]; then
  gpu=$(( act * 100 / max ))
else
  gpu="0"
fi

# Print formatted blocks for Dracula status line
# Background: Dracula dark (#282a36)
# CPU: Green (#50fa7b), MEM: Pink (#ff79c6), GPU: Cyan (#8be9fd)
printf "#[bg=#282a36]#[fg=#50fa7b]#[bold]   %s%%  #[fg=#ff79c6]  %s%%  #[fg=#8be9fd]󰢮  %s%%" "$cpu" "$mem" "$gpu"
