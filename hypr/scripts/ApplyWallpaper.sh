#!/usr/bin/env bash

set -euo pipefail

image_path="${1:-}"
monitor="${2:-}"
shift 2 || true
transition_args=("$@")

if [[ -z "$image_path" || ! -f "$image_path" ]]; then
  exit 1
fi

if [[ -z "$monitor" ]] && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' 2>/dev/null || true)"
fi

if [[ -z "$monitor" ]]; then
  monitor="eDP-1"
fi

if [[ ${#transition_args[@]} -eq 0 ]]; then
  transition_args=(
    --transition-fps 60
    --transition-type grow
    --transition-duration 1.8
    --transition-bezier .43,1.19,1,.4
    --transition-pos 0.925,0.977
  )
fi

if command -v awww >/dev/null 2>&1 && command -v awww-daemon >/dev/null 2>&1; then
  pkill swww-daemon >/dev/null 2>&1 || true
  if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
    sleep 0.25
  fi

  awww_cmd=(awww img --resize crop --filter Lanczos3)
  if [[ -n "$monitor" ]]; then
    awww_cmd+=(--outputs "$monitor")
  fi
  awww_cmd+=("${transition_args[@]}" "$image_path")
  "${awww_cmd[@]}"
  exit 0
fi

if command -v swww >/dev/null 2>&1 && command -v swww-daemon >/dev/null 2>&1; then
  pkill awww-daemon >/dev/null 2>&1 || true
  if ! swww query >/dev/null 2>&1; then
    swww-daemon --format xrgb >/dev/null 2>&1 &
    sleep 0.2
  fi

  if [[ -n "$monitor" ]]; then
    swww img -o "$monitor" "$image_path" "${transition_args[@]}"
  else
    swww img "$image_path" "${transition_args[@]}"
  fi
  exit 0
fi

if command -v mpvpaper >/dev/null 2>&1; then
  pkill mpvpaper >/dev/null 2>&1 || true
  mpvpaper -f -s -o "no-audio --loop-file=inf" '*' "$image_path" >/dev/null 2>&1 &
  exit 0
fi

if command -v swaybg >/dev/null 2>&1; then
  pkill swaybg >/dev/null 2>&1 || true
  swaybg -i "$image_path" -m fill >/dev/null 2>&1 &
  exit 0
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Wallpaper" "No wallpaper backend installed (need swww, mpvpaper, or swaybg)."
fi

exit 1
