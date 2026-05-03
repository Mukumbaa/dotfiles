
terminal = "alacritty"
terminal2 = "foot"
fileManager = "kitty --single-instance yazi"
browser = "google-chrome"
browser2 = "brave-browser"

hl.config({
    exec_once = {
        "waybar",
        "hyprpaper",
        "kanshi",
        "dbus-update-activation-environment --systemd --all",
        "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE",
        "/usr/libexec/xdg-desktop-portal-hyprland",
        "/usr/libexec/xdg-desktop-portal-gtk --replace &"
    }
})
