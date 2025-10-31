#!/bin/bash

options=("Balanced" "Power Saver" "Performance")

choice=$(printf "%s\n" "${options[@]}" | fzf --prompt="Choise: ")

case $choice in
  "Balanced") tuned-adm profile balanced-battery;;
  "Power Saver") tuned-adm profile powersave;;
  "Performance") tuned-adm profile throughput-performance;;
  *) echo "Terminated";;
esac
