local utils = require("utils")
-- =========================
-- Applicazioni base
-- =========================
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(Terminal))
hl.bind("SUPER + W", hl.dsp.window.kill())
hl.bind("SUPER + M", hl.dsp.exit())
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd(FileManager))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(Terminal .. " --class algo -e algo"))
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))

-- =========================
-- Focus
-- =========================
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))
-- =========================
-- Workspace 1-9
-- =========================
for i = 1, 9 do
    local ws = tostring(i)

    hl.bind("SUPER + " .. ws,
        hl.dsp.focus({ workspace = ws }))

    hl.bind("SUPER + SHIFT + " .. ws,
        hl.dsp.window.move({ workspace = ws }))

    hl.bind("SUPER + ALT + " .. ws,
        hl.dsp.window.move({ workspace = ws, follow = false }))
end

-- =========================
-- Workspace 10
-- =========================
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))
hl.bind("SUPER + ALT + 0", hl.dsp.window.move({ workspace = "10", follow = false }))

-- =========================
-- Mouse
-- =========================
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- =========================
-- Audio / Luminosità
-- =========================
hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })

hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })

hl.bind("XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true })

hl.bind("XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true })

hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
    { locked = true, repeating = true })

hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
    { locked = true, repeating = true })

-- =========================
-- Media
-- =========================
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- =========================
-- Lid switch
-- =========================
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprlock"), { locked = true })
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms on"), { locked = true })
hl.bind("switch:on:Lid Switch", utils.lid_down, { locked = true })
hl.bind("switch:off:Lid Switch", utils.lid_up, { locked = true })

hl.on("monitor.removed", function()
    hl.dispatch(hl.dsp.focus({monitor = "eDP-1"}))
end)

hl.bind("SUPER + O", utils.mirror_monitor)
-- =========================
-- Swap window
-- =========================
hl.bind("SUPER + SHIFT + LEFT",
    hl.dsp.window.swap({ direction = "l" }),
    { description = "Swap window left" })

hl.bind("SUPER + SHIFT + RIGHT",
    hl.dsp.window.swap({ direction = "r" }),
    { description = "Swap window right" })

hl.bind("SUPER + SHIFT + UP",
    hl.dsp.window.swap({ direction = "u" }),
    { description = "Swap window up" })

hl.bind("SUPER + SHIFT + DOWN",
    hl.dsp.window.swap({ direction = "d" }),
    { description = "Swap window down" })

-- =========================
-- Extra binds personali
-- =========================
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("ALT + TAB", hl.dsp.window.cycle_next())

hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd(Browser))
hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("wlogout"))

hl.bind("SUPER + SHIFT + ESCAPE",
    hl.dsp.exec_cmd(Terminal .. " --class algo -e algo ~/.config/algo/menus/power-profile-custom.txt"))

hl.bind("SUPER + SHIFT + SPACE",
    hl.dsp.exec_cmd(Terminal .. " --class algo -e algo ~/.config/algo/menus/setup-configs-custom.txt"))

hl.bind("SUPER + I", hl.dsp.exec_cmd("nmgui"))
hl.bind("SUPER + SHIFT + I", hl.dsp.exec_cmd(Terminal .. " -e nmtui"))

hl.bind("SUPER + B", hl.dsp.exec_cmd("blueman-manager"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("gnome-calendar"))

hl.bind("Print", function() utils.hyprshot("region")() end)
hl.bind("SHIFT + Print", function() utils.hyprshot("output")() end)
-- hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region -s"))
-- hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m output -s"))

hl.bind("SUPER + SHIFT + S", function() utils.hyprshot("region")() end)
hl.bind("SUPER + ALT + SPACE", utils.roll_wallpaper)
hl.bind("SUPER + P", utils.pip_window)
hl.bind("SUPER + T", function () utils.toggle_waybar(true) end)

hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + R", function()
    hl.exec_cmd("hyprctl reload")
    hl.notification.create({text="Reloaded config", duration = "2500", color = "rgb(31748f)"})
end)

hl.bind("SUPER + Control_L", hl.dsp.exec_cmd("hyprctl switchxkblayout all next; pkill -RTMIN+8 waybar"))

