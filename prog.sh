#PROGRAMS
sudo dnf copr enable solopasha/hyprland -y
sudo dnf install hyprland hyprpaper swaylock waybar alacritty alacritty helix btop -y
sudo dnf copr enable atim/starship -y
sudo dnf install starship -y

sudo dnf install fd-find -y
sudo dnf install qalculate -y
sudo dnf copr enable errornointernet/walker -y
sudo dnf install walker -y
sudo dnf install elephant -y


#LANGAUGES
sudo dnf install gcc clangd golang -y
