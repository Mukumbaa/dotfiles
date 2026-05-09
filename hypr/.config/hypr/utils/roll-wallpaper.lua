local module = {}

local function list_wallpapers(dir)
  local handle = io.popen("ls -1 " .. dir)

  if not handle then
    return
  end

  local result = handle:read("*a")
  handle:close()

  local files = {}

  for file in result:gmatch("[^\r\n]+") do
      table.insert(files, file)
  end

  return files
end

function module.roll_wallpaper()
  local home = os.getenv("HOME")
  local wallpaper_dir = home .. "/.config/hypr/wallpaper"
  local handle = io.popen("hyprctl hyprpaper listactive")

  if not handle then
    return
  end

  local result = handle:read("*a")
  handle:close()
  local filename = result:match(".*/(.-)%.[^%.]+$")

  local wallpapers = list_wallpapers(wallpaper_dir)

  if not wallpapers then
    return
  end

  local next_i = (tonumber(filename) % #wallpapers) + 1
  os.execute('hyprctl hyprpaper wallpaper ",' .. wallpaper_dir .. "/" .. wallpapers[next_i] .. '"')

  hl.notification.create({text="Wallpaper changed", duration = "2500", color = "rgb(31748f)"})
end

return module
