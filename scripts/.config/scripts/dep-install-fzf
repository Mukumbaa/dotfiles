package="$(
  dnf list --available | awk '{print $1}' |
    fzf -m --prompt="Enter Package Names: " \
      --preview "dnf info {} 2>/dev/null" \
        --preview-window=down:60%:wrap |
    tr "\n" " " | sed 's/\.[^ ]*//g'
)"

# Controlla se l'utente ha premuto ESC (variabile vuota)
if [[ -z "$package" ]]; then
    exit 0
fi

[[ $package ]] && read -n1 -p "Install ${package}? [y/N]: " install
[[ "$install" == [Yy] ]] && sudo dnf install $package
