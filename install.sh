#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    sudo -E bash prog.sh
fi
echo "Done Installing"
echo "System things..."
elephant service enable
systemctl --user start elephant.service

./migrate.sh
source ~/.bashrc
rustup-init -y
go install golang.org/x/tools/gopls@latest && go install github.com/nametake/golangci-lint-langserver@latest && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && go install golang.org/x/tools/cmd/goimports@latest && go install github.com/go-delve/delve/cmd/dlv@latest
cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli 

#PROGRAMS
# sudo dnf copr enable solopasha/hyprland -y
# sudo dnf install hyprland hyprpaper swaylock waybar alacritty alacritty helix btop -y
# sudo dnf copr enable atim/starship -y
# sudo dnf install starship -y

# sudo dnf install fd-find -y
# sudo dnf install qalculate -y
# sudo dnf copr enable errornointernet/walker -y
# sudo dnf install walker -y
# sudo dnf install elephant -y


#LANGAUGES
# sudo dnf install gcc clangd golang -y

#DOCKER
# sudo dnf install dnf-plugins-core -y
# sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo -y
# sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
# sudo systemctl enable --now docker
# sudo systemctl start --now docker
# sudo usermod -aG docker $USER

# ./migrate.sh
