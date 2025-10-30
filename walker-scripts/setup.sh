items="Hyprland\nMonitor\nKeybindings\nStatup\nLook and Feel\nAlacritty\nStarship\nWaybar"
output=$(echo -e $items | walker --dmenu -H)
if [[ "$output" == "Shutdown" ]]; then
    shutdown -h now
elif [[ "$output" == "Reboot" ]]; then
    reboot
elif [[ "$output" == "Lock" ]]; then
    swaylock
else
    echo "Please select a command"
fi
