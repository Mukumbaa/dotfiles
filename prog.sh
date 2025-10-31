sudo dnf update -y
#PROGRAMS
sudo dnf copr enable solopasha/hyprland -y
sudo dnf install hyprland hyprpaper swaylock waybar alacritty alacritty helix btop -y
sudo dnf copr enable atim/starship -y
sudo dnf install starship -y
sudo dnf install foot dolphin -y
sudo dnf install google-chrome-stable -y

sudo dnf install fd-find -y
sudo dnf install qalculate -y
sudo dnf copr enable errornointernet/walker -y
sudo dnf install walker -y
sudo dnf install elephant -y
sudo dnf install -y dbus-devel pkgconf-pkg-config -y
sudo dnf install gh -y
sudo dnf install blueman nmtui -y
sudo dnf install flameshot -y

sudo dnf install cascadia-mono-nf-fonts -y
#LANGAUGES
sudo dnf install gcc clangd golang rustup -y

#REMOVE BLOAT
sudo dnf group remove libreoffice -y
sudo dnf remove libreoffice* -y


echo "Done"
