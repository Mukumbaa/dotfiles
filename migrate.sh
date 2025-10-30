echo "general.import = [\"~/.config/dotfiles/alacritty/alacritty.toml\"]" > ~/.config/alacritty/alacritty.toml
cat ~/.config/dotfiles/bash/bash > ~/.bashrc
cp ~/.config/dotfiles/starship/rose-pine.toml ~/.config/starship.toml

source ~/.bashrc
