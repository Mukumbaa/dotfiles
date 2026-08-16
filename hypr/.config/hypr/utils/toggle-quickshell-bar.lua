local module = {}

function module.toggle_quickshell_bar(notification)
    -- 1. Se Quickshell non è avviato nel sistema, lo avviamo per la prima volta
    local is_running = io.popen("pidof quickshell 2>/dev/null"):read("*a"):match("%d+")
    if not is_running then
        os.execute("quickshell > /dev/null 2>&1 &")
        if notification == true then
            hl.notification.create({text = "Bar on", duration = "2500", color = "rgb(31748f)"})
        end
        return
    end

    -- 2. Se è già avviato, facciamo il toggle istantaneo della visibilità via IPC
    os.execute("qs ipc call bar toggle 2>/dev/null || quickshell ipc call bar toggle 2>/dev/null")

    -- 3. Notifica con stato reale (on/off)
    if notification == true then
        local check = io.popen("qs ipc call bar isVisible 2>/dev/null || quickshell ipc call bar isVisible 2>/dev/null")
        local result = check and check:read("*a") or ""
        if check then check:close() end

        local is_visible = result:match("true") ~= nil
        local status_text = is_visible and "Bar on" or "Bar off"
        hl.notification.create({text = status_text, duration = "2500", color = "rgb(31748f)"})
    end
end

return module
