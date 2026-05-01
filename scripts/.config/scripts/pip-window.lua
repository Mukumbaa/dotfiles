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

-- CONTROLLIAMO SE HA IL TAG "pip"
local is_pip = false
if active.tags then
    for _, tag in ipairs(active.tags) do
        if tag == "pip" then
            is_pip = true
            break
        end
    end
end

local width = 600
local height = 338

-- =======================================================
-- 2. Logica Toggle (PiP On / PiP Off)
-- =======================================================

if is_pip then
    -- RIPRISTINA FINESTRA NORMALE
    -- Rimuoviamo il tag e togliamo il floating (senza toccare il pin)
    local cmds = {
        "dispatch togglefloating address:" .. addr,
        "dispatch tagwindow -pip address:" .. addr
    }
    os.execute('hyprctl -q --batch "' .. table.concat(cmds, ";") .. ';"')
    print("Modalità PiP disattivata.")

else
    -- ABILITA PiP
    local cmds1 = {
        "dispatch togglefloating address:" .. addr
    }
    os.execute('hyprctl -q --batch "' .. table.concat(cmds1, ";") .. ';"')
    os.execute("sleep 0.2")
    -- SECONDO STEP: Applica dimensioni e proprietà
    local cmds2 = {
        string.format("dispatch resizeactive exact %d %d address:%s", width, height, addr),
        "dispatch setprop bordersize 2 address:" .. addr,
        "dispatch setprop bordercolor rgb(f6c177) address:" .. addr,
        "dispatch setprop rounding 10 address:" .. addr
    }
    os.execute('hyprctl -q --batch "' .. table.concat(cmds2, ";") .. ';"')
    os.execute("sleep 0.1")
    -- TERZO STEP: Sposta, metti in primo piano e aggiungi il TAG pip
    local cmds3 = {
        "dispatch centerwindow address:" .. addr,
        "dispatch alterzorder top address:" .. addr,
        "dispatch tagwindow +pip address:" .. addr
    }
    os.execute('hyprctl -q --batch "' .. table.concat(cmds3, ";") .. ';"')
    print("Modalità PiP attivata!")
end
