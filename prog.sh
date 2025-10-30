sudo dnf update -y
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
sudo dnf install rustup -y

sudo dnf install cascadia-mono-nf-fonts -y
#LANGAUGES

#REMOVE BLOAT
sudo dnf group remove libreoffice -y
sudo dnf remove libreoffice* -y


echo "Done"
