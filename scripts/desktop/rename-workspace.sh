#!/usr/bin/env bash
name=$(rofi -dmenu -p "Workspace name" -theme-str 'listview { enabled: false; }')
niri msg action set-workspace-name "$name"
