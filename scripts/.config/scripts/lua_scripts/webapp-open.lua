#!/usr/bin/env lua

local num_args = #arg

-- Se non ci sono argomenti, mostriamo come si usa lo script
if num_args == 0 then
    print("Uso:")
    print("  " .. arg[0] .. " <url>")
    print("  " .. arg[0] .. " <browser> <url>")
    os.exit(1)
end

local browser = ""
local app_url = ""

if num_args == 1 then
    -- 1 Argomento: Scopriamo il browser predefinito
    local handle = io.popen("xdg-settings get default-web-browser 2>/dev/null")
    if handle then
        local output = handle:read("*a")
        handle:close()
        
        -- Rimuoviamo gli a capo e gli spazi (equivalente di chomp)
        output = output:gsub("%s+", "")
        -- Sostituiamo ".desktop" con stringa vuota (equivalente di sed 's/\.desktop//')
        -- Nota: il punto in Lua va fatto precedere dal % per indicare un punto letterale
        browser = output:gsub("%.desktop$", "")
    end
    
    app_url = arg[1]
    
elseif num_args >= 2 then
    -- 2 Argomenti: Browser specificato manualmente
    browser = arg[1]
    app_url = arg[2]
end

-- Se per qualche motivo xdg-settings fallisce
if browser == "" then
    print("Errore: Impossibile determinare il browser.")
    os.exit(1)
end

-- Costruiamo il comando. 
-- NOTA: Includo l'URL tra apici singoli ('%s') per evitare che caratteri 
-- come "&" nel link vengano interpretati dalla shell rompendolo!
local cmd = string.format("%s --app='%s'", browser, app_url)

-- Lancia il comando
-- Mettiamo una "&" finale se vogliamo che lo script si chiuda subito 
-- e lasci aperta la webapp (spesso utile nei Window Manager)
os.execute(cmd .. " &")
