local utils = {}

local function merge(module)
  for key, value in pairs(module) do
    utils[key] = value
  end
end

merge(require("utils.pip"))
merge(require("utils.toggle-waybar"))
merge(require("utils.roll-wallpaper"))
merge(require("utils.mirror-monitor"))
merge(require("utils.lid-down"))
merge(require("utils.lid-up"))
merge(require("utils.hyprshot"))

return utils
