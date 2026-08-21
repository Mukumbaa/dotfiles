local module = {}
local utils = require("utils.toggle-waybar")
function module.lid_down()
  local monitors = hl.get_monitors()

  if #monitors > 1 then
      hl.monitor({ output = "eDP-1", disabled = true })
  else
      -- hl.exec_cmd("hyprlock")
      hl.exec_cmd("qs ipc call lock lock")
  end
end

return module
