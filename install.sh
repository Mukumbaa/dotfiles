sudo dnf copr enable solopasha/hyprland
sudo dnf install hyprland hyprpaper hyprlock hypridle waybar alacritty wofi alacritty helix btop

rm -r ~/.config/waybar
cp -r ./waybar ~/.config/waybar

rm -r ~/.config/hypr
cp -r ./hypr ~/.config/hypr

rm -r ~/.config/helix
cp -r ./helix ~/.config/helix

