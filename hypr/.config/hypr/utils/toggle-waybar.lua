local module = {}

function module.toggle_waybar()
    local running = io.popen("pidof waybar"):read("*a"):match("%d+")

    if running then
        os.execute("pkill -9 -x waybar")
        hl.notification.create({text="Waybar off", duration = "2500", color = "rgb(31748f)"})
    else
        os.execute("waybar > /dev/null 2>&1 &")
        hl.notification.create({text="Waybar on", duration = "2500", color = "rgb(31748f)"})
    end
end

return module
