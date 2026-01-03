
#!/bin/bash

# Interrompi lo script se un comando fallisce
set -e

# Colori per i log
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# 1. CONTROLLO PRELIMINARE
# Assicuriamoci di NON essere root (lo script deve girare come utente normale)
if [ "$EUID" -eq 0 ]; then
  echo "Per favore, non eseguire questo script come root (non usare sudo ./setup.sh)."
  echo "Lo script chiederà la password quando necessario."
  exit 1
fi

log "Inizio installazione..."

# 2. GESTIONE PACCHETTI DI SISTEMA (Richiede SUDO)
log "Aggiornamento sistema e installazione pacchetti..."

# Rimuovi bloat
sudo dnf group remove libreoffice -y || true
sudo dnf remove libreoffice* -y || true

# Aggiornamento repos
sudo dnf update -y

# Abilita repo di terze parti necessari
sudo dnf copr enable lionheartp/Hyprland -y
sudo dnf install fedora-workstation-repositories -y # Per Chrome se non presente
sudo dnf config-manager --set-enabled google-chrome

# Lista pacchetti DNF (Aggregati per velocità)
DEPENDENCIES=(
    # Core & Shell
    stow
    lsd
    fd-find
    git
    gh
    starship
    btop
    fastfetch
    
    # Hyprland & Wayland utils
    hyprland
    hyprpaper
    hyprlock
    waybar
    swaylock
    wlogout
    wofi
    flameshot
    
    # Apps & Tools
    alacritty
    foot
    dolphin
    helix
    google-chrome-stable
    blueman
    NetworkManager-tui
    qalculate-gtk
    
    # Dev & Build Deps
    gcc
    clang-tools-extra # contiene clangd
    golang
    rustup
    dbus-devel
    pkgconf
    python3-pip
    pipx
    
    # Fonts
    cascadia-code-nf-fonts
)

# Installa tutto in una volta
sudo dnf install "${DEPENDENCIES[@]}" -y

# 3. CONFIGURAZIONE UTENTE (Senza SUDO)
log "Configurazione Dotfiles con Stow..."

# Assicuriamoci di essere nella cartella dello script
cd "$(dirname "$0")"

# Lista delle cartelle da stoware
STOW_DIRS=(
    alacritty
    bash-config
    btop
    fastfetch
    helix
    hypr
    scripts
    starship
    swaylock
    waybar
    wofi
)

# Rimuovi .bashrc esistente per evitare conflitti con --adopts o stow normale
if [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
    log "Backuppo il .bashrc esistente..."
    mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
fi

# Esegui stow
for dir in "${STOW_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        stow -v -R -t "$HOME" "$dir"
    else
        echo "Attenzione: Directory $dir non trovata, salto."
    fi
done

# Gestione speciale per bashrc se necessario, o includilo nella lista sopra
stow -v -R -t "$HOME" bashrc

# 4. INSTALLAZIONE TOOL DI SVILUPPO (Utente)
log "Installazione tool di sviluppo (Rust/Go/Pipx)..."

# Rust
rustup-init -y --no-modify-path
source "$HOME/.cargo/env"

# Go Tools
export GOPATH="$HOME/go"
export PATH=$PATH:$GOPATH/bin
go install golang.org/x/tools/gopls@latest
go install github.com/nametake/golangci-lint-langserver@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/go-delve/delve/cmd/dlv@latest

# Pipx
pipx ensurepath
pipx install calcure

# Tinymist (Typst LSP)
cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli 

# 5. INSTALLAZIONI CUSTOM (nmgui)
log "Installazione nmgui..."
sudo curl -L https://github.com/s-adi-dev/nmgui/releases/download/v1.0.0/main.bin -o /usr/bin/nmgui
sudo chmod +x /usr/bin/nmgui
# Assicurati che la cartella esista
mkdir -p ~/.local/share/applications
curl -sL https://raw.githubusercontent.com/s-adi-dev/nmgui/main/nmgui.desktop -o ~/.local/share/applications/nmgui.desktop

success "Installazione completata!"
echo "IMPORTANTE: Riavvia il computer o fai logout/login per applicare tutte le modifiche (gruppi, path, wayland)."
