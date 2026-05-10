local utils = {}

local function merge(module)
  for key, value in pairs(module) do
    utils[key] = value
  end
end

merge(require("utils.pip"))
merge(require("utils.toggle-waybar"))
merge(require("utils.roll-wallpaper"))
merge(require("utils.monitos-on-lid"))

return utils
