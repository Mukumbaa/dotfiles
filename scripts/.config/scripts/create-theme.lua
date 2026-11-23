#!/usr/bin/env lua

local home = os.getenv("HOME")
if not home then os.exit(1) end

local name = arg[1]
if not name or not name:match("^[a-zA-Z0-9._-]+$") then
  print("Uso:")
  print("  1. Crea scheletro: lua create-theme.lua <nome-tema>")
  print("  2. Compila ~/.config/themes/<nome-tema>/quickshell.json")
  print("  3. Genera tutto:   lua create-theme.lua <nome-tema> [nvim_scheme] [chroma_style]")
  os.exit(1)
end

local theme_dir = home .. "/.config/themes/" .. name
local qs_path   = theme_dir .. "/quickshell.json"
local nvim_arg  = arg[2] or name
local chroma_arg = arg[3] or nvim_arg

local function read_file(p)
  local f = io.open(p, "r")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

local function write_file(p, c)
  local f = assert(io.open(p, "w"))
  f:write(c)
  f:close()
end

-- Se quickshell.json non esiste ancora, crea lo scheletro pronto da compilare
local qraw = read_file(qs_path)
if not qraw then
  os.execute(string.format('mkdir -p "%s/wallpapers"', theme_dir))
  write_file(qs_path, string.format([=[
{
  "name": "%s",
  "base": "#2e3440",
  "surface": "#3b4252",
  "overlay": "#434c5e",
  "text": "#eceff4",
  "subtle": "#d8dee9",
  "accent": "#88c0d0",
  "accent2": "#81a1c1",
  "accent3": "#b48ead",
  "error": "#bf616a",
  "warning": "#ebcb8b",
  "success": "#a3be8c"
}
]=], name))
  print("Creato scheletro in: " .. theme_dir)
  print("1) Modifica i colori in: " .. qs_path)
  print("2) Metti almeno 1 sfondo in: " .. theme_dir .. "/wallpapers/")
  print(string.format("3) Rilancia: lua ~/.config/scripts/create-theme.lua %s [nvim_scheme] [chroma_style]", name))
  os.exit(0)
end

-- Estrae i colori da quickshell.json
local function col(k)
  return qraw:match('"' .. k .. '"%s*:%s*"(#%x%x%x%x%x%x)"')
end

local p = {
  base    = col("base"),
  surface = col("surface"),
  overlay = col("overlay"),
  text    = col("text"),
  subtle  = col("subtle"),
  accent  = col("accent"),
  accent2 = col("accent2"),
  accent3 = col("accent3"),
  error   = col("error"),
  warning = col("warning"),
  success = col("success"),
}

for k, v in pairs(p) do
  if not v then
    io.stderr:write("Errore: manca o non è valido il colore '" .. k .. "' in " .. qs_path .. "\n")
    os.exit(1)
  end
end

-- Calcola automaticamente le sfumature intermedie per btop e superfile
local function blend(h1, h2, t)
  local r1, g1, b1 = tonumber(h1:sub(2,3), 16), tonumber(h1:sub(4,5), 16), tonumber(h1:sub(6,7), 16)
  local r2, g2, b2 = tonumber(h2:sub(2,3), 16), tonumber(h2:sub(4,5), 16), tonumber(h2:sub(6,7), 16)
  return string.format("#%02x%02x%02x",
    math.floor(r1 * (1 - t) + r2 * t + 0.5),
    math.floor(g1 * (1 - t) + g2 * t + 0.5),
    math.floor(b1 * (1 - t) + b2 * t + 0.5)
  )
end

local hl_med  = blend(p.overlay, p.subtle, 0.22)
local hl_high = blend(p.overlay, p.subtle, 0.38)
local muted   = blend(p.overlay, p.subtle, 0.65)

os.execute(string.format('mkdir -p "%s/wallpapers"', theme_dir))

-- 1. hypr.lua (bordo attivo = accent2, inattivo = overlay)
write_file(theme_dir .. "/hypr.lua", string.format([=[
hl.config({
    general = {
        ["col.active_border"] = "0xff%s",
        ["col.inactive_border"] = "0xff%s",
    }
})
]=], p.accent2:sub(2), p.overlay:sub(2)))

-- 2. alacritty.toml
write_file(theme_dir .. "/alacritty.toml", string.format([=[
[colors.primary]
background = '%s'
foreground = '%s'

[colors.normal]
black   = '%s'
red     = '%s'
green   = '%s'
yellow  = '%s'
blue    = '%s'
magenta = '%s'
cyan    = '%s'
white   = '%s'

[colors.bright]
black   = '%s'
red     = '%s'
green   = '%s'
yellow  = '%s'
blue    = '%s'
magenta = '%s'
cyan    = '%s'
white   = '%s'

[colors.selection]
background = '%s'
]=],
  p.base, p.text,
  p.overlay, p.error, p.success, p.warning, p.accent, p.accent2, p.accent3, p.text,
  muted,     p.error, p.success, p.warning, p.accent, p.accent2, p.accent3, p.text,
  p.overlay
))

-- 3. btop.theme
write_file(theme_dir .. "/btop.theme", string.format([=[
theme[main_bg]="%s"
theme[main_fg]="%s"
theme[title]="%s"
theme[hi_fg]="%s"
theme[selected_bg]="%s"
theme[selected_fg]="%s"
theme[inactive_fg]="%s"
theme[graph_text]="%s"
theme[meter_bg]="%s"
theme[proc_misc]="%s"
theme[cpu_box]="%s"
theme[mem_box]="%s"
theme[net_box]="%s"
theme[proc_box]="%s"
theme[div_line]="%s"
theme[temp_start]="%s"
theme[temp_mid]="%s"
theme[temp_end]="%s"
theme[cpu_start]="%s"
theme[cpu_mid]="%s"
theme[cpu_end]="%s"
theme[free_start]="%s"
theme[free_mid]="%s"
theme[free_end]="%s"
theme[cached_start]="%s"
theme[cached_mid]="%s"
theme[cached_end]="%s"
theme[available_start]="%s"
theme[available_mid]="%s"
theme[available_end]="%s"
theme[used_start]="%s"
theme[used_mid]="%s"
theme[used_end]="%s"
theme[download_start]="%s"
theme[download_mid]="%s"
theme[download_end]="%s"
theme[upload_start]="%s"
theme[upload_mid]="%s"
theme[upload_end]="%s"
theme[process_start]="%s"
theme[process_mid]="%s"
theme[process_end]="%s"
]=],
  p.base, p.text, p.subtle, p.text, hl_high, p.warning, hl_med, p.accent, hl_high, p.accent2,
  p.accent3, p.success, p.accent2, p.error, muted,
  p.accent3, p.warning, p.error,
  p.warning, p.accent3, p.error,
  p.error, p.error, p.error,
  p.accent2, p.accent2, p.accent2,
  p.success, p.success, p.success,
  p.accent3, p.accent3, p.accent3,
  p.success, p.accent, p.accent,
  p.accent3, p.error, p.error,
  p.success, p.accent, p.accent
))

-- 4. superfile.toml
write_file(theme_dir .. "/superfile.toml", string.format([=[
code_syntax_highlight = "%s"

file_panel_border = "%s"
sidebar_border = "%s"
footer_border = "%s"

file_panel_border_active = "%s"
sidebar_border_active = "%s"
footer_border_active = "%s"
modal_border_active = "%s"

full_screen_bg = "%s"
file_panel_bg = "%s"
sidebar_bg = "%s"
footer_bg = "%s"
modal_bg = "%s"

full_screen_fg = "%s"
file_panel_fg = "%s"
sidebar_fg = "%s"
footer_fg = "%s"
modal_fg = "%s"

cursor = "%s"
correct = "%s"
error = "%s"
hint = "%s"
cancel = "%s"
gradient_color = ["%s", "%s"]

file_panel_top_directory_icon = "%s"
file_panel_top_path = "%s"
file_panel_item_selected_fg = "%s"
file_panel_item_selected_bg = "%s"

sidebar_title = "%s"
sidebar_item_selected_fg = "%s"
sidebar_item_selected_bg = "%s"
sidebar_divider = "%s"

modal_cancel_fg = "%s"
modal_cancel_bg = "%s"
modal_confirm_fg = "%s"
modal_confirm_bg = "%s"

help_menu_hotkey = "%s"
help_menu_title = "%s"
]=],
  chroma_arg,
  hl_med, p.base, hl_med,
  muted, p.accent2, p.warning, p.subtle,
  p.base, p.base, p.base, p.base, p.base,
  p.text, p.text, p.text, p.text, p.text,
  p.accent, p.success, p.error, p.success, muted, p.success, p.error,
  p.accent, p.accent3, p.accent2, p.base,
  muted, p.warning, p.base, p.subtle,
  p.text, hl_high, p.text, p.error,
  p.warning, p.accent
))

-- 5. nvim.txt (solo se non esiste già o se passato esplicitamente)
if arg[2] or not read_file(theme_dir .. "/nvim.txt") then
  write_file(theme_dir .. "/nvim.txt", nvim_arg .. "\n")
end

print("Tema '" .. name .. "' generato per tutte le app in: " .. theme_dir)
