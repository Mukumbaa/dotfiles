local module = {}

function module.float_window()
    local win = hl.get_active_window()
    if not win then return end

    if win.floating then
        hl.dispatch(hl.dsp.window.float({ action = "set", value = false, window = win }))
        hl.notification.create({text="Float off: " .. win.title, duration = "2500", color = "rgb(31748f)"})
    else
        hl.dispatch(hl.dsp.window.float({ action = "set", value = true, window = win }))
        hl.dispatch(hl.dsp.window.resize({ x = 600, y = 338, window = win }))
        hl.dispatch(hl.dsp.window.center({ window = win }))
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = win }))
        hl.notification.create({text="Float on: " .. win.title, duration = "2500", color = "rgb(31748f)"})
    end
end


return module
