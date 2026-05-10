local module = {}

function module.monitors_on_lid()
  local monitors = hl.get_monitors()


  if #monitors > 1 then
    hl.notification.create({text="if", duration="2000"})
    hl.monitor({
      output = "eDP-1",
      disabled = true,
    })
  else
    hl.notification.create({text="else", duration="2000"})
    hl.dsp.exec_cmd("hyprlock")
  end

end

return module
