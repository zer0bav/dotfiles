#!/usr/bin/env bash

# Fetch CPU, Memory, GPU usage based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS CPU usage
  cpu=$(top -l 1 | awk '/CPU usage/ {gsub(/%/, "", $7); printf("%.0f", 100 - $7)}' 2>/dev/null)
  [ -z "$cpu" ] && cpu="?"

  # macOS Memory usage
  total_mem=$(sysctl -n hw.memsize 2>/dev/null)
  page_size=$(vm_stat | awk '/page size of/ {print $8}' 2>/dev/null | tr -d ' bytes.')
  free_pages=$(vm_stat | awk '/Pages free/ {print $3}' 2>/dev/null | tr -d '.')
  inactive_pages=$(vm_stat | awk '/Pages inactive/ {print $3}' 2>/dev/null | tr -d '.')
  speculative_pages=$(vm_stat | awk '/Pages speculative/ {print $3}' 2>/dev/null | tr -d '.')
  if [ -n "$total_mem" ] && [ -n "$page_size" ]; then
    free_mem=$(( (free_pages + inactive_pages + speculative_pages) * page_size ))
    used_mem=$(( total_mem - free_mem ))
    mem=$(( used_mem * 100 / total_mem ))
  else
    mem="?"
  fi

  # macOS GPU usage (default to 0 as powermetrics require root)
  gpu="0"
else
  # Linux CPU usage
  cpu="$(awk -v FS=' ' '/^cpu /{printf("%.0f", 100-($5*100)/($2+$3+$4+$5+$6+$7+$8))}' /proc/stat 2>/dev/null)"
  [ -z "$cpu" ] && cpu="?"

  # Linux Memory usage
  mem="$(free -m 2>/dev/null | awk '/Mem:/ {printf("%d", $3*100/$2)}')"
  [ -z "$mem" ] && mem="?"

  # Linux Intel GPU usage
  act=$(cat /sys/class/drm/card1/gt_act_freq_mhz 2>/dev/null)
  max=$(cat /sys/class/drm/card1/gt_max_freq_mhz 2>/dev/null)
  if [ -n "$act" ] && [ -n "$max" ] && [ "$max" -gt 0 ]; then
    gpu=$(( act * 100 / max ))
  else
    gpu="0"
  fi
fi

# Print formatted blocks for Dracula status line
# Background: Dracula dark (#282a36)
# CPU: Green (#50fa7b), MEM: Pink (#ff79c6), GPU: Cyan (#8be9fd)
printf "#[bg=#282a36]#[fg=#50fa7b]#[bold]   %s%%  #[fg=#ff79c6]  %s%%  #[fg=#8be9fd]󰢮  %s%%" "$cpu" "$mem" "$gpu"
