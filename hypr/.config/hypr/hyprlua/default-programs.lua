
terminal2 = "alacritty"
terminal = "foot"
fileManager = "kitty --single-instance yazi"
browser = "google-chrome"
browser2 = "brave-browser"

hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
        hl.exec_cmd("hyprpaper")
        hl.exec_cmd("kanshi")
        hl.exec_cmd("dbus-update-activation-environment --systemd --all")
        hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
        hl.exec_cmd("/usr/libexec/xdg-desktop-portal-hyprland")
        hl.exec_cmd("/usr/libexec/xdg-desktop-portal-gtk --replace &")
end)
