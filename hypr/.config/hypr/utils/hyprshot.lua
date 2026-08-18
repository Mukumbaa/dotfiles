local module = {}

function module.hyprshot(mode)
    return function()
        -- Imposta direttamente la cartella e il nome del file
        local dir =  os.getenv("HOME") .. "/Pictures/Screenshots"
        local fn = os.date("%Y-%m-%d-%H%M%S_hyprshot.png")
        local path = dir .. "/" .. fn
        local slurp = ""

        -- Sceglie cosa fotografare in base alla modalità
        if mode == "active" then
            local win = hl.get_active_window()
            if not win then return end
            slurp = string.format('echo "%d,%d %dx%d"', win.at.x, win.at.y, win.size.x, win.size.y)

        elseif mode == "region" then
            slurp = "slurp -d"

        elseif mode == "window" then
            local boxes = ""
            for _, c in ipairs(hl.get_windows()) do
                boxes = boxes .. string.format("%d,%d %dx%d\n", c.at.x, c.at.y, c.size.x, c.size.y)
            end
            slurp = string.format("echo '%s' | slurp -r", boxes)

        elseif mode == "output" then
            local target = hl.get_active_monitor()
            slurp = target and string.format(
              'echo "%d,%d %dx%d"',
              math.floor(target.x / target.scale),
              math.floor(target.y / target.scale),
              math.floor(target.width / target.scale),
              math.floor(target.height / target.scale)
            ) or "slurp -or"
        end

        -- local notification = 'hyprctl notify -1 3500 "rgb(31748f)" "Screenshot copied and saved in Pictures/Screenshots/' .. fn .. '"'
        local notification = 'notify-send -a "Hyprland" "Screenshot" "Screenshot copied and saved in Pictures/Screenshots/' .. fn .. '"'
        -- local cmd = string.format(
        --     "sh -c 'mkdir -p \"%s\" && %s | grim -g - \"%s\" && wl-copy --type image/png < \"%s\"; %s'",
        --     dir,
        --     slurp,
        --     path,
        --     path,
        --     notification
        -- )

        local cmd = string.format([[
        sh -c '
        set -e
        mkdir -p "%s"
        %s | grim -g - "%s"
        wl-copy --type image/png < "%s"
        %s
        '
        ]],
            dir,
            slurp,
            path,
            path,
            notification
        )
        hl.exec_cmd(cmd)
    end
end

return module
