#!/usr/bin/env bash

# Definisci un file con voci + comandi
# Ogni linea: “Nome della voce|comando da eseguire”
MENU_FILE="$HOME/.config/dotfiles/wofi/custom-menus/setup-config-menu.txt"

# ad esempio:
# Apri browser|firefox
# Terminale|alacritty
# Editor|nvim

CONFIG_WOFI="--conf ~/.config/dotfiles/wofi/config2 --style ~/.config/dotfiles/wofi/style2.css"

choice=$(cut -d '|' -f1 "$MENU_FILE" | wofi --conf ~/.config/dotfiles/wofi/config2 --style ~/.config/dotfiles/wofi/style2.css --show dmenu)
if [ -n "$choice" ]; then
  cmd=$(grep "^${choice}|" "$MENU_FILE" | cut -d '|' -f2-)
  eval $cmd
fi
