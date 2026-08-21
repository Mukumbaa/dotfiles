local module = {}

function module.lid_up()
    -- hl.exec_cmd("hyprctl reload") 
    hl.monitor({
      output = "eDP-1",
      mode = "2880x1800@90",
      position = "0x0",
      scale = "1.8",
      vrr = 0,
      disabled = false,
    })
    local monitors = hl.get_monitors()

    if #monitors == 1 then
        hl.dispatch(hl.dsp.dpms({action = "on", monitor = "eDP-1"}))
    end

    hl.dispatch(hl.dsp.focus({monitor = "eDP-1"}))
end

return module
