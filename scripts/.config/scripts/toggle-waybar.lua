#!/usr/bin/env lua

-- Funzione di supporto per verificare se Waybar è attivo
local function is_waybar_running()
    -- 'pidof waybar' restituisce i numeri dei processi se esiste, 
    -- altrimenti non restituisce nulla.
    local handle = io.popen("pidof waybar")
    local result = handle:read("*a")
    handle:close()
    
    -- Se il risultato contiene almeno un numero (%d+), allora è in esecuzione
    return result:match("%d+") ~= nil
end

-- Logica di accensione/spegnimento
if is_waybar_running() then
    -- Se è aperto, lo uccidiamo
    os.execute("pkill waybar")
    print("Waybar chiuso.")
else
    -- Se è chiuso, lo avviamo. 
    -- Usiamo > /dev/null 2>&1 & per fargli scartare l'output nel vuoto 
    -- e mandarlo in background (equivalente del tuo '& disown')
    os.execute("waybar > /dev/null 2>&1 &")
    print("Waybar avviato.")
end
