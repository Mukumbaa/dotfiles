#!/usr/bin/env lua

local file_path = os.getenv("HOME") .. "/.config/hypr/current_wallpaper"

local file = io.open(file_path, "r")
if file then
    local content = file:read("*a"):gsub("%s+", "") -- Legge e toglie spazi/a capo
    print(content)
    file:close()
else
    print("0") -- Valore di fallback se il file non esiste
end
