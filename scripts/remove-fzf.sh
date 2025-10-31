fzf_down() {
    fzf --preview 'pkg={}; dnf info "${pkg%% *}" 2>/dev/null | head -30' \
        --preview-window=down:60%:wrap \
        --bind '?:toggle-preview' "$@"
}

dnf_fzf() {
    local cache=$HOME/.cache/dnf_list_installed.txt

    if test -f "$cache"; then
        package=$(cat "$cache" | fzf_down)
    else
        mkdir -p "$HOME/.cache"
        # Ottiene solo i pacchetti installati
        dnf list --installed | awk '{print $1}' | tail -n +4 > "$cache"
        package=$(cat "$cache" | fzf_down)
    fi

    if [[ -n "$package" ]]; then
        echo "Removing: $package"
        sudo dnf remove -y "$package"
    fi
}

dnf_fzf_remove() {
    local package="$1"

    if [[ -n "$package" ]]; then
        # Verifica se il pacchetto è installato
        if dnf list --installed "$package" &>/dev/null; then
            sudo dnf remove -y "$package"
            echo "Removed: $package"
        else
            echo "Package '$package' is not installed!"
            read -p "Do you want to see installed packages? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                dnf_fzf
            fi
        fi
    else
        dnf_fzf
    fi
}

# Esegui la funzione con l'argomento passato allo script
dnf_fzf_remove "$1"
