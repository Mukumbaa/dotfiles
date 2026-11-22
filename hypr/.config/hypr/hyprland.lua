require("default-programs")
require("monitor")
require("look-and-feel")
require("env")
require("input")
require("keybindings")
require("windows")

local f = io.open(os.getenv("HOME") .. "/.cache/current-theme/hypr.lua", "r")
if f then
    local raw = f:read("*a")
    f:close()
    local active = raw:match('%["col%.active_border"%]%s*=%s*"([^"]+)"')
    local inactive = raw:match('%["col%.inactive_border"%]%s*=%s*"([^"]+)"')
    if active then
        hl.config({
            general = {
                ["col.active_border"] = active,
                ["col.inactive_border"] = inactive or "0xff26233a",
            }
        })
    else
        require("themes.rose-pine")
    end
else
    require("themes.rose-pine")
end
