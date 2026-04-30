#!/usr/bin/env lua

local num_args = #arg


if num_args < 2 then
  print("Error: wrong number of params.")
  print("Usage: mirror <source_monitor> <mirror_monitor>")
  print("Usage: mirror stop <mirror_monitor>")
  print("Example: mirror eDP-1 HDMI-A-1")
end

local source = arg[1]
local mirror = arg[2]


if source == "stop" then
  local exit_code = os.execute("hyprctl keyword monitor " .. mirror .. ",preferred,auto,1")
  if exit_code ~= 0 then
    print("Error while stopping mirroring on monitor: " .. mirror)
    print("Verify that the monitor names are correct. Check them with hyprctl monitors")
    os.exit(0)
  end
end


print("Setting " .. mirror .. " as a mirror of " .. source)

local exit_code = os.execute("hyprctl keyword monitor \"" .. mirror .. "\",preferred,0x0,1,mirror,\"" .. source .. "\"")

if exit_code == 0 then
  print("Mirroring acrivated: " .. mirror .. " shows the same content as " .. source)
else
  print("Error while setting mirroring.")
  print("Verify that the monitor names are correct. Check them with hyprctl monitors")
  os.exit(1)
end
