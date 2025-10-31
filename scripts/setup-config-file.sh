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
  "Alacritty") hx ~/.config/dotfiles/alacritty/alacritty.toml;;
  *) echo "Terminated";;
esac
