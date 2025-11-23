#!/usr/bin/env bash
# Symlink VSCode settings and install extensions for FHS VSCode

set -euo pipefail

# Paths
DOTFILES_DIR="$HOME/.config/nixos/dotfiles"
VSCODE_USER_DIR="$HOME/.config/Code/User"
SETTINGS_SRC="$DOTFILES_DIR/.config/Code/User/settings.json"
SETTINGS_DEST="$VSCODE_USER_DIR/settings.json"
EXT_LIST="$DOTFILES_DIR/vscode-extensions.txt"

# Ensure VSCode User directory exists
mkdir -p "$VSCODE_USER_DIR"

# Symlink settings.json
ln -sf "$SETTINGS_SRC" "$SETTINGS_DEST"
echo "Symlinked $SETTINGS_SRC to $SETTINGS_DEST"

# Install extensions from list
if [[ -f "$EXT_LIST" ]]; then
  while IFS= read -r ext || [[ -n "$ext" ]]; do
    [[ -z "$ext" || "$ext" =~ ^# ]] && continue  # skip empty lines and comments
    code-fhs --install-extension "$ext"
  done < "$EXT_LIST"
  echo "Extensions installed from $EXT_LIST"
else
  echo "Extension list $EXT_LIST not found. Skipping extension install."
fi
