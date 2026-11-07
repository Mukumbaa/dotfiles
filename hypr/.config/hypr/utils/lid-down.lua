local module = {}
function module.lid_down()
  local monitors = hl.get_monitors()

  if #monitors > 1 then
      hl.monitor({ output = "eDP-1", disabled = true })
      hl.exec_cmd('notify-send -a "Hyprland" "lid-down.lua" "Only external monitor on"')
  else
      -- hl.exec_cmd("hyprlock")
      hl.exec_cmd("qs ipc call lock lock")
  end
end

return module
