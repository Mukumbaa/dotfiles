local utils = {}

local function merge(module)
  for key, value in pairs(module) do
    utils[key] = value
  end
end

merge(require("pip"))

return utils
