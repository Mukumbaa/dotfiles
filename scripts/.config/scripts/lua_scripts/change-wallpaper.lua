#!/usr/bin/env lua

local target_num = tonumber(arg[1])
local dir = os.getenv("HOME") .. "/.config/hypr/wallpaper"

if not target_num then
    print("Uso: " .. arg[0] .. " <numero>")
    os.exit(1)
end

-- Cerca i file interessati
local fileN 
local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
if handle then
    for filename in handle:lines() do
        local num_str, ext = filename:match("^(%d+)%.(%w+)$")
        if num_str and ext then
            local num = tonumber(num_str)
            if num == target_num then fileN = {name = filename, ext = ext} end
        end
    end
    handle:close()
end

if not fileN then
    print("Errore: nessun wallpaper trovato per il numero " .. target_num)
    os.exit(1)
end

os.execute('hyprctl hyprpaper wallpaper ",' .. dir .. '/' .. fileN.name .. '"')
print("Wallpaper impostato: " .. fileN.name)
