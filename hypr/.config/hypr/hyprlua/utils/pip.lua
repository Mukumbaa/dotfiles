local function pip_window()
    local win = hl.get_active_window()
    if not win then return end

    local is_pip = false
    if win.tags then
        for _, t in ipairs(win.tags) do
            if t == "pip" then
                is_pip = true
            end
        end
    end

    if is_pip then
        --  DISATTIVA PiP
        hl.dispatch(hl.dsp.window.tag({ tag = "-pip", window = win }))
        hl.dispatch(hl.dsp.window.float({ action = "set", value = false, window = win }))
        hl.dispatch(hl.dsp.window.set_prop({ prop = "border_size", value = 1, window = win }))
        hl.dispatch(hl.dsp.window.set_prop({ prop = "rounding", value = 0, window = win }))

    else
        --  ATTIVA PiP
        hl.dispatch(hl.dsp.window.float({ action = "set", value = true, window = win }))
        hl.dispatch(hl.dsp.window.resize({ x = 600, y = 338, window = win }))
        hl.dispatch(hl.dsp.window.center({ window = win }))
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = win }))

        hl.dispatch(hl.dsp.window.set_prop({ prop = "border_size", value = 2, window = win }))
        hl.dispatch(hl.dsp.window.set_prop({ prop = "rounding", value = 10, window = win }))

        hl.dispatch(hl.dsp.window.tag({ tag = "+pip", window = win }))
    end
end
