-- ==============================================================================
-- 1. CONFIGURAZIONE DEI DATI (Data-Driven Design)
-- ==============================================================================
local home = os.getenv("HOME")

-- Pacchetti da installare con DNF
local dnf_packages = {
    "stow",
    "hyprland",
    "hyprpaper",
    "hyprlock",
    "hyprland-guiutils",
    -- "hyprshot",
    -- "swaylock",
    "quickshell",
    "wlogout",
    "waybar",
    "alacritty",
    "kitty",
    "yazi",
    "helix",
    "nvim",
    "btop",
    "fastfetch",
    "wiremix",
    -- "kanshi",
    "google-chrome-stable",
    "lsd",
    "fd-find",
    "qalculate",
    "gnome-tweaks",
    "gnome-themes-extra",
    "dbus-devel",
    "pkgconf-pkg-config",
    "gh",
    "blueman",
    "nmtui",
    -- "flameshot",
    "pipx",
    "cascadia-mono-nf-fonts",
    "gcc",
    "clangd",
    "golang",
    "rustup",
    "grim",
    "slurp",
    "wl-clipboard",
    "brave-browser-nightly"
}

-- Pacchetti Go da installare
local go_packages = {
    "golang.org/x/tools/gopls@latest",
    "github.com/nametake/golangci-lint-langserver@latest",
    "github.com/golangci/golangci-lint/cmd/golangci-lint@latest",
    "golang.org/x/tools/cmd/goimports@latest",
    "github.com/go-delve/delve/cmd/dlv@latest"
}

-- Configurazione Stow: Mappatura "Pacchetto -> Destinazione"
local stow_configs = {
    -- Gruppo A (Cartelle in .config)
    { pkg = "alacritty",   target = home .. "/.config/alacritty" },
    { pkg = "bash-config", target = home .. "/.config/bash-config" },
    { pkg = "btop",        target = home .. "/.config/btop" },
    { pkg = "fastfetch",   target = home .. "/.config/fastfetch" },
    { pkg = "helix",       target = home .. "/.config/helix" },
    { pkg = "nvim",        target = home .. "/.config/nvim" },
    { pkg = "hypr",        target = home .. "/.config/hypr" },
    { pkg = "quickshell",  target = home .. "/.config/quickshell" },
    { pkg = "scripts",     target = home .. "/.config/scripts" },
    { pkg = "waybar",      target = home .. "/.config/waybar" },
    { pkg = "wlogout",     target = home .. "/.config/wlogout" },
    { pkg = "kanshi",      target = home .. "/.config/kanshi" },
    { pkg = "algo",        target = home .. "/.config/algo" },
    { pkg = "yazi",        target = home .. "/.config/yazi" },
    { pkg = "kitty",       target = home .. "/.config/kitty" },
    -- Gruppo B (File speciali)
    { pkg = "bashrc",      target = home .. "/.bashrc" },
    { pkg = "starship",    target = home .. "/.config/starship.toml" },
}


-- ==============================================================================
-- 2. FUNZIONI DI SUPPORTO (UI e Logica)
-- ==============================================================================
local colors = {
    blue = "\27[34m", green = "\27[32m", yellow = "\27[33m", red = "\27[31m", reset = "\27[0m", bold = "\27[1m"
}

local function print_step(msg)
    print("\n" .. colors.bold .. colors.blue .. "==> " .. colors.reset .. colors.bold .. msg .. colors.reset)
end

local function print_info(msg)
    print("  " .. colors.green .. "-> " .. colors.reset .. msg)
end

-- ==============================================================================
-- 3. LOGICA DI ESECUZIONE
-- ==============================================================================

print_step("Inizio Setup del Sistema")

---------------------------------------------------------
-- FASE 1: Gestione Pacchetti di Sistema (Sudo richiesto)
---------------------------------------------------------
print_step("Rimozione Bloatware")
os.execute("sudo dnf group remove libreoffice -y")
os.execute("sudo dnf remove libreoffice* -y")

print_step("Abilitazione Repository COPR")
os.execute("sudo dnf copr enable lionheartp/Hyprland -y")
os.execute("sudo dnf copr enable lihaohong/yazi -y")

os.execute("sudo dnf install dnf-plugins-core")
os.execute("sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo")
-- os.execute("sudo dnf install brave-browser-nightly")

print_step("Installazione Pacchetti DNF")
-- Uniamo tutta la tabella in una singola stringa separata da spazi
local dnf_cmd = "sudo dnf install -y --skip-unavailable " .. table.concat(dnf_packages, " ")
os.execute(dnf_cmd)

---------------------------------------------------------
-- FASE 2: Installazioni Esterne
---------------------------------------------------------
print_step("Installazione NMGUI (WiFi) e Starship")
-- os.execute("sudo curl -L https://github.com/s-adi-dev/nmgui/releases/download/v1.0.0/main.bin -o /usr/bin/nmgui")
-- os.execute("sudo chmod +x /usr/bin/nmgui")
-- os.execute("curl -sL https://raw.githubusercontent.com/s-adi-dev/nmgui/main/nmgui.desktop -o ~/.local/share/applications/nmgui.desktop")

-- Starship
os.execute("curl -sS https://starship.rs/install.sh | sh -s -- -y")

-- Pipx path
os.execute("pipx install ensurepath")

---------------------------------------------------------
-- FASE 3: Ambienti di Programmazione (Rust, Go)
---------------------------------------------------------
print_step("Setup Ambienti di Sviluppo")
os.execute("rustup-init -y")

-- Cargo
print_info("Installazione tinymist-cli (Cargo)")
local cargo_bin = home .. "/.cargo/bin/cargo"
os.execute(cargo_bin .. " install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli")

-- Go packages (Ciclo elegante sull'array)
print_info("Installazione Strumenti Go")
for _, pkg in ipairs(go_packages) do
    os.execute("go install " .. pkg)
end

---------------------------------------------------------
-- FASE 4: Safe Stow (Dotfiles)
---------------------------------------------------------
print_step("Ripristino Dotfiles (Safe Stow)")

-- Crea la cartella di backup con il timestamp (es. 20260501_105900)
local backup_dir = home .. "/.config/dotfiles_backup_" .. os.date("%Y%m%d_%H%M%S")
os.execute('mkdir -p "' .. backup_dir .. '"')
print_info("Eventuali conflitti verranno salvati in: " .. backup_dir)

for _, conf in ipairs(stow_configs) do
    local target = conf.target
    local pkg = conf.pkg

    -- Controllo: Se esiste (-e) E NON è un symlink (! -L)
    -- os.execute restituisce 'true' se il comando Bash ha successo (exit code 0)
    local check_cmd = string.format('[ -e "%s" ] && [ ! -L "%s" ]', target, target)

    if os.execute(check_cmd) then
        print(colors.yellow .. "  !! Trovato file/cartella reale: " .. target .. colors.reset)

        -- Calcoliamo il percorso relativo per mantenere la struttura nel backup
        -- gsub elimina il percorso della home stringa. Es: "/home/user/.bashrc" diventa ".bashrc"
        local rel_path = target:gsub(home .. "/", "")
        local dest = backup_dir .. "/" .. rel_path

        -- Ricreiamo la cartella genitore nel backup e spostiamo il file
        os.execute('mkdir -p "$(dirname "' .. dest .. '")"')
        os.execute('mv "' .. target .. '" "' .. dest .. '"')
        print_info("Spostato in backup: " .. dest)
    end

    print_info("Stowing " .. pkg)
    os.execute("stow " .. pkg)
end


-- print_step("Installazione di Algo")
--
-- local algo_repo = "https://github.com/Mukumbaa/algo"
-- local algo_dir = home .. "/algo"
--
-- -- Controllo se la cartella ~/algo esiste già
-- -- [ -d ... ] verifica se è una directory valida
-- if os.execute('[ -d "' .. algo_dir .. '" ]') then
--     print_info("La cartella ~/algo esiste già. Scarico gli ultimi aggiornamenti (git pull)...")
--     os.execute("cd " .. algo_dir .. " && git pull")
-- else
--     print_info("Clonazione della repository Algo...")
--     os.execute("git clone " .. algo_repo .. " " .. algo_dir)
-- end
--
-- print_info("Esecuzione di install.sh di Algo...")
-- -- Usiamo && per assicurarci di entrare nella cartella PRIMA di eseguire lo script.
-- -- Aggiungiamo anche un chmod +x preventivo per sicurezza!
-- os.execute("cd " .. algo_dir .. " && chmod +x install.sh && ./install.sh")


print_step("Setup Completato con Successo! Riavvia la sessione.")
