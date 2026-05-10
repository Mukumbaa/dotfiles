local module = {}

function module.toggle_waybar(notification)
    local running = io.popen("pidof waybar"):read("*a"):match("%d+")

    if running then
        os.execute("pkill -9 -x waybar")
        if notification == true then
            hl.notification.create({text="Waybar off", duration = "2500", color = "rgb(31748f)"})
        end
    else
        os.execute("waybar > /dev/null 2>&1 &")
        if notification == true then
            hl.notification.create({text="Waybar on", duration = "2500", color = "rgb(31748f)"})
        end
    end
end

return module
