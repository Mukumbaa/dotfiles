local module = {}

function module.toggle_quickshell_bar(notification)
    local notify_flag = notification and "1" or "0"

    -- Usiamo flock per gestire lo spam in modo nativo e sicuro
    local bash_script = string.format([[
        sh -c '
            LOCK="/tmp/qs_toggle.lock"
            exec 200>"$LOCK"
            flock -n 200 || exit 0

            # 1. Se Quickshell non è avviato, lo avvia
            if ! pgrep -x quickshell >/dev/null 2>&1; then
                quickshell >/dev/null 2>&1 &
                if [ "%s" = "1" ]; then
                    notify-send -a "Hyprland" -r 9954 "toggle-quickshell-bar.lua" "Bar on"
                fi
                exit 0
            fi

            # 2. Toggle via IPC
            (qs ipc call bar toggle || quickshell ipc call bar toggle) >/dev/null 2>&1

            # 3. Notifica con stato reale
            if [ "%s" = "1" ]; then
                sleep 0.05
                STATE=$(qs ipc call bar isVisible 2>/dev/null || quickshell ipc call bar isVisible 2>/dev/null)
                if echo "$STATE" | grep -q "true"; then
                    notify-send -a "Hyprland" -r 9954 "toggle-quickshell-bar.lua" "Bar on"
                else
                    notify-send -a "Hyprland" -r 9954 "toggle-quickshell-bar.lua" "Bar off"
                fi
            fi
        ' &
    ]], notify_flag, notify_flag)

    hl.exec_cmd(bash_script)
end

return module
