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
sudo dnf intsall rustup -y

#LANGAUGES
source ~/.bashrc
sudo dnf install gcc clangd golang -y
go install golang.org/x/tools/gopls@latest && go install github.com/nametake/golangci-lint-langserver@latest && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && go install golang.org/x/tools/cmd/goimports@latest && go install github.com/go-delve/delve/cmd/dlv@latest
cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli 

#REMOVE BLOAT
sudo dnf group remove libreoffice -y
sudo dnf remove libreoffice* -y


echo "Done"
