#!/usr/bin/env lua

-- Comando per selezionare i pacchetti via fzf
local cmd = [[dnf list --available | awk '{print $1}' | fzf -m --prompt="Enter Package Names: " --preview "dnf info {}" --preview-window=down:60%:wrap | tr "\n" " " | sed 's/\.[^ ]*//g']]

local handle = io.popen(cmd)
if not handle then
    print("Errore: impossibile eseguire fzf.")
    os.exit(1)
end

local package = handle:read("*a")
handle:close()

-- Pulisce spazi e newline
package = package:match("^%s*(.-)%s*$")

if package == "" then
    os.exit(0)
end

-- Conferma installazione
io.write("Install " .. package .. "? [y/N]: ")
io.flush()   -- Assicura che il prompt appaia subito
local answer = io.read()

if answer and (answer == "y" or answer == "Y") then
    os.execute("sudo dnf install " .. package)
end
