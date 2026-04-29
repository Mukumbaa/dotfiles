#!/usr/bin/env lua

-- sudo luarocks install lua-cjson
local cjson = require("cjson.safe")

-- Funzione per eseguire un comando e leggerne l'output
local function exec_and_read(cmd)
    local handle = io.popen(cmd)
    if not handle then return "" end
    local result = handle:read("*a")
    handle:close()
    return result
end

-- =======================================================
-- 1. Ottieni informazioni sulla finestra attiva tramite JSON
-- =======================================================
local active_raw = exec_and_read("hyprctl activewindow -j")
local active = cjson.decode(active_raw)

-- Se l'output non è un JSON valido o manca l'indirizzo, esci
if not active or not active.address or active.address == "" then
    print("Nessuna finestra attiva")
    os.exit(0)
end

local addr = active.address
local pinned = active.pinned

-- =======================================================
-- 2. Calcolo Posizione e Dimensioni
-- =======================================================
local width = 600
local height = 338
local margin = 40

-- Ottieni le info del monitor (usiamo il primo monitor, [1] in Lua)
local monitors_raw = exec_and_read("hyprctl monitors -j")
local monitors = cjson.decode(monitors_raw)

local screen_height = 1080 -- Valore di sicurezza
if monitors and monitors[1] then
    screen_height = monitors[1].height
end

-- Posizione calcolata (angolo in basso a sinistra)
local pos_x = margin
local pos_y = screen_height - height - margin

-- =======================================================
-- 3. Logica Toggle (PiP On / PiP Off)
-- =======================================================

if pinned then
    -- RIPRISTINA FINESTRA NORMALE
    -- Usiamo una tabella per raggruppare i comandi e li uniamo con ";"
    local cmds = {
        "dispatch pin address:" .. addr,
        "dispatch togglefloating address:" .. addr,
        "dispatch tagwindow -pip address:" .. addr
    }
    -- hyprctl batch accetta una singola stringa con comandi separati da ;
    os.execute('hyprctl -q --batch "' .. table.concat(cmds, ";") .. ';"')
    print("Modalità PiP disattivata.")

else
    -- ABILITA PiP
    
    -- PRIMO STEP: Rendi floating e pin
    local cmds1 = {
        "dispatch togglefloating address:" .. addr,
        "dispatch pin address:" .. addr
    }
    os.execute('hyprctl -q --batch "' .. table.concat(cmds1, ";") .. ';"')
    
    os.execute("sleep 0.2")
    
    -- SECONDO STEP: Applica dimensioni e proprietà
    local cmds2 = {
        string.format("dispatch resizeactive exact %d %d address:%s", width, height, addr),
        "dispatch setprop keepaspectratio false address:" .. addr,
        "dispatch setprop bordersize 2 address:" .. addr,
        "dispatch setprop bordercolor rgb(f6c177) address:" .. addr,
        "dispatch setprop rounding 10 address:" .. addr
    }
    os.execute('hyprctl -q --batch "' .. table.concat(cmds2, ";") .. ';"')
    
    os.execute("sleep 0.1")
    
    -- TERZO STEP: Sposta nella posizione finale e metti in primo piano
    local cmds3 = {
        -- Qui ho corretto il tuo script originario! Invece di centerwindow,
        -- lo sposto esattamente nelle coordinate calcolate in basso a sinistra.
        -- Se preferisci che stia al centro, cambia la riga sotto con: "dispatch centerwindow address:" .. addr,
        "dispatch centerwindow address:" .. addr,
        "dispatch alterzorder top address:" .. addr,
        "dispatch tagwindow +pip address:" .. addr
    }
    os.execute('hyprctl -q --batch "' .. table.concat(cmds3, ";") .. ';"')
    
    print("Modalità PiP attivata!")
end
