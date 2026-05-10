local module = {}

function module.lid_up()
    hl.exec_cmd("hyprctl reload")
    local monitors = hl.get_monitors()

    if #monitors == 1 then
        hl.dispatch(hl.dsp.dpms({action = "on", monitor = "eDP-1"}))
    end

    hl.dispatch(hl.dsp.focus({monitor = "eDP-1"}))
end

return module
