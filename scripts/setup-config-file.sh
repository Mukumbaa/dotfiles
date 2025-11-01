#!/bin/bash

options=("Monitor" "Input" "Look and Feel" "Keybindings" "Hyprpaper" "Default Programs" "Alacritty")

choice=$(printf "%s\n" "${options[@]}" | fzf --prompt="Choise: ")

case $choice in
  "Monitor") hx ~/.config/dotfiles/hypr/monitor.conf;;
  "Input") hx ~/.config/dotfiles/hypr/input.conf;;
  "Look and Feel") hx ~/.config/dotfiles/hypr/look-and-feel.conf;;
  "Keybindings") hx ~/.config/dotfiles/hypr/keybindings.conf;;
  "Hyprpaper") hx ~/.config/dotfiles/hypr/hyprpaper.conf;;
  "Default Programs") hx ~/.config/dotfiles/hypr/default-programs.conf;;
  "Alacritty") echo "Starting Alacritty..." >> /tmp/alacritty-debug.log
  alacritty -e hx ~/.config/dotfiles/alacritty/alacritty.toml \
    >/tmp/alacritty.out 2>/tmp/alacritty.err &
  echo "Command launched" >> /tmp/alacritty-debug.log
  ;;
esac
