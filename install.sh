sudo dnf copr enable solopasha/hyprland
sudo dnf install hyprland hyprpaper swaylock hypridle waybar alacritty wofi alacritty helix btop

rm -r ~/.config/waybar
cp -r ./waybar ~/.config/waybar

rm -r ~/.config/hypr
cp -r ./hypr ~/.config/hypr

rm -r ~/.config/helix
cp -r ./helix ~/.config/helix

rm -r ~/.config/btop
cp -r ./btop ~/.config/btop

rm -r ~/.config/alacritty
cp -r ./alacritty ~/.config/alacritty





