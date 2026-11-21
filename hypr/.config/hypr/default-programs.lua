local apps = {
  terminal = "alacritty",
  terminal2 = "foot",
  file_manager = "alacritty -e spf",
  browser = "google-chrome",
  browser2 = "brave-browser",
}

local clip_script = os.getenv("HOME") .. "/.config/scripts/cliphist-ttl.lua"

hl.on("hyprland.start", function()
  hl.exec_cmd("quickshell")
  hl.exec_cmd([[
  sh -c '
  dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE
  systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE
  systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal-gtk 2>/dev/null || {
    /usr/libexec/xdg-desktop-portal-hyprland &
    /usr/libexec/xdg-desktop-portal-gtk --replace
  }
  '
  ]])
  -- Watcher clipboard con tracciamento scadenza (3 ore)
  hl.exec_cmd(string.format(
    [[wl-paste --type text --watch sh -c 'wl-paste --list-types | grep -qE "^(text/plain|UTF8_STRING)" && lua "%s" store']],
    clip_script
  ))
  hl.exec_cmd(string.format(
    [[wl-paste --type image --watch lua "%s" store]],
    clip_script
  ))
end)
return apps;
