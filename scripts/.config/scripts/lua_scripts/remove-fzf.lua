#!/usr/bin/env lua

-- Configurazioni e percorsi
local home = os.getenv("HOME")
local cache_dir = home .. "/.cache"
local cache_file = cache_dir .. "/dnf_list_installed.txt"

-- Stringa con le opzioni di fzf (esattamente come nel tuo script Bash)
local fzf_opts = "--preview 'pkg={}; dnf info \"${pkg%% *}\" 2>/dev/null | head -30' --preview-window=down:60%:wrap --bind '?:toggle-preview'"

-- Funzione per verificare se un file esiste
local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- ==========================================================
-- fzf_down + dnf_fzf unificate
-- ==========================================================
local function dnf_fzf()
    -- Se la cache non esiste, creiamola
    if not file_exists(cache_file) then
        os.execute('mkdir -p "' .. cache_dir .. '"')
        -- Usiamo bash per il pipe rapido come nel tuo script
        local generate_cmd = "dnf list --installed 2>/dev/null | awk '{print $1}' | tail -n +4 > " .. cache_file
        os.execute(generate_cmd)
    end

    -- Costruisci il comando che unisce cat e fzf
    local cmd = "cat " .. cache_file .. " | fzf " .. fzf_opts
    
    -- io.popen apre fzf. fzf disegna sullo schermo nativamente, ma 
    -- quando premi INVIO, l'output viene catturato dalla nostra variabile 'handle'
    local handle = io.popen(cmd)
    if not handle then return end
    
    local package = handle:read("*a"):gsub("%s+", "") -- Legge ed elimina a capo
    handle:close()

    -- Se è stato selezionato un pacchetto (e l'utente non ha premuto ESC)
    if package ~= "" then
        print("Removing: " .. package)
        os.execute("sudo dnf remove -y " .. package)
    end
end

-- ==========================================================
-- Funzione principale (dnf_fzf_remove)
-- ==========================================================
local function dnf_fzf_remove(package)
    if package and package ~= "" then
        -- Verifica se il pacchetto è installato (os.execute ritorna true se tutto va a buon fine)
        local check_cmd = "dnf list --installed " .. package .. " >/dev/null 2>&1"
        local is_installed = os.execute(check_cmd)

        if is_installed then
            os.execute("sudo dnf remove -y " .. package)
            print("Removed: " .. package)
        else
            print("Package '" .. package .. "' is not installed!")
            
            -- Chiede input all'utente
            io.write("Do you want to see installed packages? (y/N): ")
            local reply = io.read("*l") or "" -- *l legge la riga fino all'invio
            
            if reply:match("^[Yy]") then
                dnf_fzf()
            end
        end
    else
        dnf_fzf()
    end
end

-- ==========================================================
-- Esecuzione dello script
-- ==========================================================
dnf_fzf_remove(arg[1])
