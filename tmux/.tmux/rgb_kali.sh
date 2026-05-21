#!/usr/bin/env bash

colors=("#f38ba8" "#fab387" "#f9e2af" "#a6e3a1" "#89dceb" "#89b4fa" "#cba6f7")
sec=$(date +%S)
idx=$((10#$sec % 7))

echo "#[fg=${colors[$idx]},bold]   zer0T0 "
