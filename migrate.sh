#!/bin/bash

# Exit on error and enable trace
set -e

# Function to create directory if it doesn't exist
create_dir_if_needed() {
    if [ ! -d "$1" ]; then
        echo "Creating directory: $1"
        mkdir -p "$1"
    fi
}

# Function to check if source file exists
check_source_file() {
    if [ ! -f "$1" ]; then
        echo "ERROR: Source file not found: $1"
        return 1
    fi
    return 0
}

echo "Starting configuration installation..."

# 1. Alacritty Configuration
echo "Configuring Alacritty..."
create_dir_if_needed "$HOME/.config/alacritty"
if check_source_file "$HOME/.config/dotfiles/alacritty/alacritty.toml"; then
    echo "general.import = [\"~/.config/dotfiles/alacritty/alacritty.toml\"]" > "$HOME/.config/alacritty/alacritty.toml"
    echo "✓ Alacritty configuration completed"
else
    echo "⚠ Skipping Alacritty configuration - source file not found"
fi

# 2. Helix Configuration
echo "Configuring Helix..."
create_dir_if_needed "$HOME/.config/helix"
if check_source_file "$HOME/.config/dotfiles/helix/config.toml"; then
    cp "$HOME/.config/dotfiles/helix/config.toml" "$HOME/.config/helix/config.toml"
    echo "✓ Helix configuration completed"
else
    echo "⚠ Skipping Helix configuration - source file not found"
fi

# 3. Hyprland Configuration
echo "Configuring Hyprland..."
create_dir_if_needed "$HOME/.config/hypr"
if check_source_file "$HOME/.config/dotfiles/hypr/hyprland.conf"; then
    echo "source = ~/.config/dotfiles/hypr/hyprland.conf" > "$HOME/.config/hypr/hyprland.conf"
    echo "✓ Hyprland configuration completed"
else
    echo "⚠ Skipping Hyprland configuration - source file not found"
fi

# 4. Bash Configuration
echo "Configuring Bash..."
if check_source_file "$HOME/.config/dotfiles/bash/bash"; then
    cp "$HOME/.config/dotfiles/bash/bash" "$HOME/.bashrc"
    echo "✓ Bash configuration completed"
else
    echo "⚠ Skipping Bash configuration - source file not found"
fi

# 5. Starship Configuration
echo "Configuring Starship..."
create_dir_if_needed "$HOME/.config"
if check_source_file "$HOME/.config/dotfiles/starship/rose-pine.toml"; then
    cp "$HOME/.config/dotfiles/starship/starship.toml" "$HOME/.config/starship.toml"
    echo "✓ Starship configuration completed"
else
    echo "⚠ Skipping Starship configuration - source file not found"
fi

# 6. Wofi Configuration
echo "Configuring Wofi..."
create_dir_if_needed "$HOME/.config/wofi"
if check_source_file "$HOME/.config/dotfiles/wofi/config"; then
    install -D "$HOME/.config/dotfiles/wofi/config" "$HOME/.config/wofi/config"
    echo "✓ Wofi config configuration completed"
else
    echo "⚠ Skipping Wofi config configuration - source file not found"
fi

if check_source_file "$HOME/.config/dotfiles/wofi/menu"; then
    install -D "$HOME/.config/dotfiles/wofi/menu" "$HOME/.config/wofi/menu"
    echo "✓ Wofi menu configuration completed"
else
    echo "⚠ Skipping Wofi menu configuration - source file not found"
fi

# 7. Reload Bashrc (only if it exists)
echo "Reloading Bash configuration..."
if [ -f "$HOME/.bashrc" ]; then
    # Use source only if script is run in interactive shell
    if [[ $- == *i* ]]; then
        source "$HOME/.bashrc"
        echo "✓ Bashrc reloaded"
    else
        echo "ℹ Script run in non-interactive shell, run manually: source ~/.bashrc"
    fi
else
    echo "⚠ Cannot reload bashrc - file not found"
fi

echo ""
echo "Installation completed!"
echo "Note: To fully apply changes, run manually:"
echo "source ~/.bashrc"
