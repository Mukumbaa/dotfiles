items="Shutdown\nReboot\nLock"
output=$(echo -e $items | walker --dmenu -H)
if [[ "$output" == "Shutdown" ]]; then
    shutdown -h now
elif [[ "$output" == "Reboot" ]]; then
    reboot
elif [[ "$output" == "Lock" ]]; then
    echo "Execute lock command"
    swaylock
else
    echo "Please select a command"
fi
