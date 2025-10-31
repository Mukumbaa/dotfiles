#!/bin/bash

# Chiede all'utente il nome
read -p "Git name: " git_name

# Se l'utente ha inserito qualcosa, setta il nome
if [[ -n "${git_name//[[:space:]]/}" ]]; then
    git config --global user.name "$git_name"
    echo "Git name done: $git_name"
else
    echo "Empty name"
fi

# Chiede all'utente l'email
read -p "Git email: " git_email

# Se l'utente ha inserito qualcosa, setta l'email
if [[ -n "${git_email//[[:space:]]/}" ]]; then
    git config --global user.email "$git_email"
    echo "Git email done: $git_email"
else
    echo "Empty name"
fi


gh auth login
