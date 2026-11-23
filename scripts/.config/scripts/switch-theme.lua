#!/usr/bin/env lua

local home = os.getenv("HOME")
if not home then os.exit(1) end

local themes_dir = home .. "/.config/themes"
local cache_dir  = home .. "/.cache/current-theme"

local theme_name = arg[1]

-- Se chiamato senza argomenti, elenca i temi disponibili
if not theme_name then
    print("Uso: lua switch-theme.lua <nome-tema>")
    print("Temi disponibili:")
    local p = io.popen('ls -1 "' .. themes_dir .. '" 2>/dev/null')
    if p then
        for d in p:lines() do print("  - " .. d) end
        p:close()
    end
    os.exit(0)
end

local target_dir = themes_dir .. "/" .. theme_name
local check = io.open(target_dir .. "/quickshell.json", "r")
if not check then
    io.stderr:write("Errore: tema '" .. theme_name .. "' non trovato in " .. themes_dir .. "\n")
    os.exit(1)
end
check:close()

os.execute(string.format('mkdir -p "%s" "%s/.config/btop/themes" "%s/.config/superfile/theme"', cache_dir, home, home))

-- 1. Scrive quickshell.json sullo stesso inode per far scattare FileView live in 0ms
local qs_in = io.open(target_dir .. "/quickshell.json", "r")
local qs_out = io.open(cache_dir .. "/quickshell.json", "w")
if qs_in and qs_out then
    qs_out:write(qs_in:read("*a"))
end
if qs_in then qs_in:close() end
if qs_out then qs_out:close() end

-- 2. Aggiorna i link per Hyprland, Alacritty, Neovim, btop, Superfile e Wallpapers
os.execute(string.format('ln -sfn "%s/hypr.lua" "%s/hypr.lua"', target_dir, cache_dir))
os.execute(string.format('ln -sfn "%s/alacritty.toml" "%s/alacritty.toml"', target_dir, cache_dir))
os.execute(string.format('ln -sfn "%s/nvim.txt" "%s/nvim.txt"', target_dir, cache_dir))
os.execute(string.format('ln -sfn "%s/wallpapers" "%s/wallpapers"', target_dir, cache_dir))
os.execute(string.format('ln -sfn "%s/btop.theme" "%s/.config/btop/themes/current.theme"', target_dir, home))
os.execute(string.format('ln -sfn "%s/superfile.toml" "%s/.config/superfile/theme/current.toml"', target_dir, home))

-- 3. Ricarica live tutte le app attive
os.execute("hyprctl reload >/dev/null 2>&1")
os.execute("qs ipc call wallpaper reload >/dev/null 2>&1")
os.execute(string.format('touch -c "%s/.config/alacritty/alacritty.toml" 2>/dev/null', home))
os.execute("pkill -USR2 btop 2>/dev/null")

-- 4. Aggiorna live tutte le finestre Neovim già aperte
local nf = io.open(target_dir .. "/nvim.txt", "r")
local nvim_scheme = nf and nf:read("*l") or ""
if nf then nf:close() end
nvim_scheme = nvim_scheme:match("^%s*(.-)%s*$")

local runtime = os.getenv("XDG_RUNTIME_DIR")
if runtime and nvim_scheme ~= "" then
    local p = io.popen('ls "' .. runtime .. '"/nvim.*.0 2>/dev/null')
    if p then
        for sock in p:lines() do
            os.execute(string.format(
                'nvim --server "%s" --remote-expr "execute(\'colorscheme %s\')" >/dev/null 2>&1 &',
                sock, nvim_scheme
            ))
        end
        p:close()
    end
end

os.execute(string.format('notify-send -a "Theme Switcher" "Theme applied" "%s" 2>/dev/null &', theme_name))
