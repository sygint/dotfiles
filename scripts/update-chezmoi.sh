#!/usr/bin/env bash

# Update chezmoi variables from Nix variables and apply
cd ~/.config/nixos

# Read variables from Nix file and create chezmoi data
TERMINAL=$(nix-instantiate --eval --expr '(import ./variables.nix).terminal' --json)
FILEBROWSER=$(nix-instantiate --eval --expr '(import ./variables.nix).fileBrowser' --json)
WEBBROWSER=$(nix-instantiate --eval --expr '(import ./variables.nix).webBrowser' --json)
MENU=$(nix-instantiate --eval --expr '(import ./variables.nix).menu' --json)
KEYBOARDLAYOUT=$(nix-instantiate --eval --expr '(import ./variables.nix).keyboardLayout' --json)

# Create chezmoi data file
cat > ~/.config/chezmoi/chezmoi.toml << EOF
sourceDir = "~/.config/nixos/dotfiles"

[data]
private_ = false
terminal = $TERMINAL
fileBrowser = $FILEBROWSER
webBrowser = $WEBBROWSER
menu = $MENU
keyboardLayout = $KEYBOARDLAYOUT
EOF

echo "Updated chezmoi variables from variables.nix"
chezmoi apply --force
