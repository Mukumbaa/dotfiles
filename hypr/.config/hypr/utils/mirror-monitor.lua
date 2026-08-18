local module = {}

local is_mirroring = false
local ext_monitor_name = ""

function module.mirror_monitor()
    if not is_mirroring then
        local monitors = hl.get_monitors()
        for _, m in ipairs(monitors) do
            if m.name and m.name:sub(1,3) ~= "eDP" and not m.is_mirror then
                ext_monitor_name = m.name
                -- hl.notification.create({text = m.name .. " mirroring eDP-1", duration = 2500, color = "rgb(31748f)"})
                hl.exec_cmd('notify-send -a "Hyprland" "Monitors" "' .. m.name .. ' mirroring eDP-1"')
                hl.monitor({ output = m.name, mode = "preferred", position = "auto", scale = "1", mirror = "eDP-1" })
                is_mirroring = true
            end
        end
    else
        if ext_monitor_name ~= "" then
            -- hl.notification.create({text = "Disabling mirror for " .. ext_monitor_name, duration = 2500, color = "rgb(31748f)"})
            hl.exec_cmd('notify-send -a "Hyprland" "Monitors" "Disabling mirror for ' .. ext_monitor_name .. '"')
            hl.exec_cmd("hyprctl reload")
            is_mirroring = false
            ext_monitor_name = ""
        end
    end
end

return module
