-- Valore di default per lo schermo del portatile se non specificato
local laptop_factor = "1.8"
local args_start = 1

-- Se il primo argomento è un numero (es. 1.5, 1.7), lo usa come fattore per il portatile
if arg[1] and tonumber(arg[1]) then
    laptop_factor = arg[1]
    args_start = 2
end

-- Raccoglie il comando e tutti i suoi argomenti successivi
local cmd_args = {}
for i = args_start, #arg do
    table.insert(cmd_args, arg[i])
end

if #cmd_args == 0 then
    io.stderr:write("Uso: scale-run.lua [fattore_portatile] <comando> [argomenti...]\n")
    os.exit(1)
end

-- Rileva la scala del monitor attualmente focalizzato su Hyprland
local p = io.popen("hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .scale' | head -n1")
local current_scale = p and p:read("*l") or ""
if p then p:close() end

-- Rimuove eventuali spazi bianchi o newline
current_scale = current_scale:match("^%s*(.-)%s*$")

-- Se siamo sul monitor esterno (scala 1.0) forziamo 1.0, altrimenti usiamo la scala del portatile
local target_scale = "1.0"
if current_scale == "1" or current_scale == "1.0" or current_scale == "" then
    target_scale = "1.0"
else
    target_scale = laptop_factor
end

-- Funzione per fare l'escape sicuro degli argomenti per la shell
local function escape_arg(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local quoted_args = {}
for _, a in ipairs(cmd_args) do
    table.insert(quoted_args, escape_arg(a))
end

local command_str = table.concat(quoted_args, " ")

-- Prepariamo il comando con le variabili d'ambiente ed 'exec' per rimpiazzare il processo
local full_cmd = string.format(
    'QT_SCALE_FACTOR=%s _JAVA_OPTIONS="-Dsun.java2d.uiScale=%s" GDK_SCALE=%s exec %s',
    target_scale, target_scale, target_scale, command_str
)

-- Esegue il comando
os.execute(full_cmd)
