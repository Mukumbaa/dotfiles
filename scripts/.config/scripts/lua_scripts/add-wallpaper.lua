#!/usr/bin/env lua

local image = arg[1]
local dir = os.getenv("HOME") .. "/.config/hypr/wallpaper/"

if not image then
    print("Uso: " .. arg[0] .. " <percorso_immagine>")
    os.exit(1)
end

-- Trova il numero più alto attualmente presente nella cartella
local max_num = 0
local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
if handle then
    for filename in handle:lines() do
        -- Cerca file che iniziano con numeri
        local numStr = filename:match("^(%d+)%.%w+$")
        if numStr then
            local num = tonumber(numStr)
            if num > max_num then max_num = num end
        end
    end
    handle:close()
end

local next_num = max_num + 1

-- Estrai l'estensione dall'immagine sorgente
local ext = image:match("%.([^%.]+)$")
if not ext then ext = "jpg" end -- fallback

local new_path = dir .. next_num .. "." .. ext

-- Usiamo os.execute con 'mv' invece di os.rename di Lua perché 'mv' gestisce
-- automaticamente lo spostamento tra dischi/partizioni diverse senza dare errori
os.execute('mv "' .. image .. '" "' .. new_path .. '"')

print("Aggiunto come: " .. new_path)
