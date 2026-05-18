local module = {}
local utils = require("utils.toggle-waybar")
function module.lid_down()
  local monitors = hl.get_monitors()

  if #monitors > 1 then
      utils.toggle_waybar(true)
      utils.toggle_waybar(true)
      hl.monitor({ output = "eDP-1", disabled = true })
  else
      hl.exec_cmd("hyprlock")
  end
end

return module
