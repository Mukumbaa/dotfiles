#!/usr/bin/env lua

-- Configurazione percorsi
local home = os.getenv("HOME")
local wallpaper_dir = home .. "/.config/hypr/wallpaper"
local current_wall_file = home .. "/.config/hypr/current_wallpaper"

-- Estensioni valide in un Set (Tabella Lua usata come dizionario per ricerca veloce)
local valid_exts = { jpg=true, jpeg=true, png=true, webp=true, bmp=true }

---------------------------------------------------------
-- FUNZIONI DI SUPPORTO
---------------------------------------------------------

-- Funzione per leggere l'output di un comando shell
local function exec_and_read(cmd)
    local handle = io.popen(cmd)
    if not handle then return "" end
    local result = handle:read("*a")
    handle:close()
    return result:gsub("%s+$", "") -- Rimuove spazi/a capo finali
end

-- Funzione per leggere il numero corrente dal file
local function get_current_num()
    local f = io.open(current_wall_file, "r")
    if not f then return 0 end
    local content = f:read("*a"):gsub("%s+", "")
    f:close()
    -- tonumber() converte in numero, se fallisce (es. testo a caso) restituisce nil
    return tonumber(content) or 1
end

---------------------------------------------------------
-- INIZIO LOGICA
---------------------------------------------------------

-- Assicurati che le cartelle esistano
os.execute('mkdir -p "' .. wallpaper_dir .. '"')
os.execute('mkdir -p "$(dirname "' .. current_wall_file .. '")"')

local current_num = get_current_num()

-- Leggi i file dalla cartella
-- In Lua standard usiamo 'ls' tramite io.popen per semplicità
local ls_output = exec_and_read('ls -1 "' .. wallpaper_dir .. '" 2>/dev/null')

local map = {}   -- Mappa: numero -> percorso intero
local nums = {}  -- Array dei soli numeri trovati

-- Itera su ogni riga (nome file) dell'output di ls
for filename in ls_output:gmatch("[^\r\n]+") do
    -- Estrai il nome (senza estensione) e l'estensione usando il pattern matching di Lua
    -- ^(.*) = tutto dall'inizio fino al punto
    -- %. = un punto letterale
    -- ([^%.]+)$ = tutto ciò che non è un punto fino alla fine
    local name, ext = filename:match("^(.*)%.([^%.]+)$")
    
    if name and ext then
        ext = ext:lower()
        
        -- Se l'estensione è valida E il nome contiene SOLO numeri (^%d+$)
        if valid_exts[ext] and name:match("^%d+$") then
            local num = tonumber(name)
            local filepath = wallpaper_dir .. "/" .. filename
            
            -- Evita duplicati se per caso hai "1.jpg" e "1.png"
            if not map[num] then
                table.insert(nums, num) -- Aggiunge all'array
                map[num] = filepath     -- Aggiunge al dizionario
            end
        end
    end
end

-- Se l'array è vuoto, esci
if #nums == 0 then
    print("Nessun wallpaper numerato trovato in " .. wallpaper_dir)
    os.exit(1)
end

-- Ordina l'array numericamente in ordine crescente
table.sort(nums)

-- Trova la posizione del current_num nella lista ordinata
local next_index = 1 -- Di default partiamo dal primo
for i, num in ipairs(nums) do
    if num == current_num then
        -- Matematica modulo per gli array in Lua (che partono da indice 1, non 0!)
        -- Es: se sono 3 file e siamo all'indice 3: (3 % 3) + 1 = 0 + 1 = 1 (Ritorna a capo)
        next_index = (i % #nums) + 1
        break
    end
end

-- Scegli il nuovo numero e il percorso del wallpaper
local chosen_num = nums[next_index]
local wallpaper = map[chosen_num]

-- Salva il nuovo numero corrente
local f = io.open(current_wall_file, "w")
if f then
    f:write(tostring(chosen_num) .. "\n")
    f:close()
end

-- Applica il wallpaper su Hyprland
if wallpaper then
    print(wallpaper)
    -- Esegue il comando hyprctl per cambiare lo sfondo
    os.execute('hyprctl hyprpaper wallpaper ",' .. wallpaper .. '"')
    print("Wallpaper impostato: " .. wallpaper)
else
    print("Errore: file wallpaper non trovato per il numero " .. tostring(chosen_num))
    os.exit(1)
end
