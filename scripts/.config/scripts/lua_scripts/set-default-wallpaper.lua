#!/usr/bin/env lua

local target_num = tonumber(arg[1])
local dir = os.getenv("HOME") .. "/.config/hypr/wallpaper"

if not target_num then
    print("Uso: " .. arg[0] .. " <numero>")
    os.exit(1)
end

local file1, fileN

-- Cerca i file interessati
local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
if handle then
    for filename in handle:lines() do
        local num_str, ext = filename:match("^(%d+)%.(%w+)$")
        if num_str and ext then
            local num = tonumber(num_str)
            if num == 1 then file1 = {name = filename, ext = ext} end
            if num == target_num then fileN = {name = filename, ext = ext} end
        end
    end
    handle:close()
end

if not fileN then
    print("Errore: nessun wallpaper trovato per il numero " .. target_num)
    os.exit(1)
end

if not file1 then
    print("Errore: nessun wallpaper 1.* trovato")
    os.exit(1)
end

-- Facciamo lo scambio usando file temporaneo per evitare conflitti
os.rename(dir .. "/" .. fileN.name, dir .. "/temp." .. fileN.ext)
os.rename(dir .. "/" .. file1.name, dir .. "/" .. target_num .. "." .. file1.ext)
os.rename(dir .. "/temp." .. fileN.ext, dir .. "/1." .. fileN.ext)

print("Wallpaper " .. target_num .. " impostato come predefinito (1)!")
