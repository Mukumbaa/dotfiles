# echo "general.import = [\"~/.config/dotfiles/alacritty/alacritty.toml\"]" > ~/.config/alacritty/alacritty.toml
# cat ~/.config/dotfiles/bash/bash > ~/.bashrc
# cp ~/.config/dotfiles/starship/rose-pine.toml ~/.config/starship.toml
# install -D ~/.config/dotfiles/wofi/config ~/.config/wofi/config
# install -D ~/.config/dotfiles/wofi/menu ~/.config/wofi/menu

# source ~/.bashrc
#!/bin/bash

# Exit on error and enable trace
set -e

# Function to create directory if it doesn't exist
create_dir_if_needed() {
    if [ ! -d "$1" ]; then
        echo "Creando directory: $1"
        mkdir -p "$1"
    fi
}

# Function to check if source file exists
check_source_file() {
    if [ ! -f "$1" ]; then
        echo "ERRORE: File sorgente non trovato: $1"
        return 1
    fi
    return 0
}

echo "Iniziando l'installazione della configurazione..."

# 1. Configuration Alacritty
echo "Configurando Alacritty..."
create_dir_if_needed "$HOME/.config/alacritty"
if check_source_file "$HOME/.config/dotfiles/alacritty/alacritty.toml"; then
    echo "general.import = [\"~/.config/dotfiles/alacritty/alacritty.toml\"]" > "$HOME/.config/alacritty/alacritty.toml"
    echo "✓ Configuration Alacritty completata"
else
    echo "⚠ Saltata configurazione Alacritty - file sorgente non trovato"
fi

# 1. Configuration Hyprland
echo "Configurando Hyprland..."
create_dir_if_needed "$HOME/.config/hypr"
if check_source_file "$HOME/.config/dotfiles/hypr/hyprland.conf"; then
    echo "source = ~/.config/dotfiles/hypr/hyprland.conf" > "$HOME/.config/hypr/hyprland.conf"
    echo "✓ Configuration Hyprland completata"
else
    echo "⚠ Saltata configurazione Hyprland - file sorgente non trovato"
fi

# 2. Configuration Bash
echo "Configurando Bash..."
if check_source_file "$HOME/.config/dotfiles/bash/bash"; then
    cp "$HOME/.config/dotfiles/bash/bash" "$HOME/.bashrc"
    echo "✓ Configuration Bash completata"
else
    echo "⚠ Saltata configurazione Bash - file sorgente non trovato"
fi

# 3. Configuration Starship
echo "Configurando Starship..."
create_dir_if_needed "$HOME/.config"
if check_source_file "$HOME/.config/dotfiles/starship/rose-pine.toml"; then
    cp "$HOME/.config/dotfiles/starship/rose-pine.toml" "$HOME/.config/starship.toml"
    echo "✓ Configuration Starship completata"
else
    echo "⚠ Saltata configurazione Starship - file sorgente non trovato"
fi

# 4. Configuration Wofi
echo "Configurando Wofi..."
create_dir_if_needed "$HOME/.config/wofi"
if check_source_file "$HOME/.config/dotfiles/wofi/config"; then
    install -D "$HOME/.config/dotfiles/wofi/config" "$HOME/.config/wofi/config"
    echo "✓ Configuration Wofi config completata"
else
    echo "⚠ Saltata configurazione Wofi config - file sorgente non trovato"
fi

if check_source_file "$HOME/.config/dotfiles/wofi/menu"; then
    install -D "$HOME/.config/dotfiles/wofi/menu" "$HOME/.config/wofi/menu"
    echo "✓ Configuration Wofi menu completata"
else
    echo "⚠ Saltata configurazione Wofi menu - file sorgente non trovato"
fi

#installazione dei linguaggi per helix
source ~/.bashrc
cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli 
go install golang.org/x/tools/gopls@latest && go install github.com/nametake/golangci-lint-langserver@latest && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && go install golang.org/x/tools/cmd/goimports@latest && go install github.com/go-delve/delve/cmd/dlv@latest
