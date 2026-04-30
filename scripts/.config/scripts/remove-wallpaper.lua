#!/usr/bin/env lua

local target_num = tonumber(arg[1])
local dir = os.getenv("HOME") .. "/.config/hypr/wallpaper"

if not target_num then
    print("Uso: " .. arg[0] .. " <numero>")
    os.exit(1)
end

local files = {}
local file_to_delete = nil

-- Leggi tutti i file e mettili in una tabella
local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
if handle then
    for filename in handle:lines() do
        local num_str, ext = filename:match("^(%d+)%.(%w+)$")
        if num_str and ext then
            local num = tonumber(num_str)
            table.insert(files, {num = num, name = filename, ext = ext})
            
            if num == target_num then
                file_to_delete = filename
            end
        end
    end
    handle:close()
end

if not file_to_delete then
    print("File non trovato per il numero " .. target_num)
    os.exit(1)
end

-- Elimina il file (os.remove è la funzione nativa Lua per 'rm')
os.remove(dir .. "/" .. file_to_delete)
print("Rimosso: " .. file_to_delete)

-- Ordina la tabella in base al numero in ordine crescente
table.sort(files, function(a, b) return a.num < b.num end)

-- Rinomina quelli successivi
for _, f in ipairs(files) do
    if f.num > target_num then
        local new_num = f.num - 1
        local new_name = new_num .. "." .. f.ext
        
        -- os.rename è perfetto qui perché siamo all'interno della stessa cartella
        os.rename(dir .. "/" .. f.name, dir .. "/" .. new_name)
        print("Rinominato: " .. f.name .. " → " .. new_name)
    end
end
