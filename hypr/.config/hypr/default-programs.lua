local apps = {
    terminal = "alacritty",
    terminal2 = "foot",
    file_manager = "alacritty -e spf",
    browser = "google-chrome",
    browser2 = "brave-browser",
}

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
end)
return apps;
