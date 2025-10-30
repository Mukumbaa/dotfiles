#PROGRAMS
sudo dnf copr enable solopasha/hyprland -y
sudo dnf install hyprland hyprpaper swaylock waybar alacritty alacritty helix btop -y
sudo dnf copr enable atim/starship -y
sudo dnf install starship -y

#LANGAUGES
sudo dnf install gcc clangd golang -y

#DOCKER
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo systemctl start --now docker
sudo usermod -aG docker $USER

./migrate.sh
