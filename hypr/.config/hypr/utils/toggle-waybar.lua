local module = {}

function module.toggle_waybar(notification)
    local running = io.popen("pidof waybar"):read("*a"):match("%d+")

    if running then
        hl.exec_cmd("pkill -9 -x waybar")
        if notification == true then
          -- hl.notification.create({text="Waybar off", duration = "2500", color = "rgb(31748f)"})
          hl.exec_cmd('notify-send -a "Hyprland" "toggle-waybar.lua" "Bar off"')
        end
    else
        hl.exec_cmd("waybar > /dev/null 2>&1 &")
        if notification == true then
            -- hl.notification.create({text="Waybar on", duration = "2500", color = "rgb(31748f)"})
            hl.exec_cmd('notify-send -a "Hyprland" "toggle-waybar.lua" "Bar on"')
        end
    end
end

return module
