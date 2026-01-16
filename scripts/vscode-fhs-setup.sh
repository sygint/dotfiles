#!/usr/bin/env bash
# Symlink VSCode settings and install extensions for FHS VSCode

set -euo pipefail

# Paths
DOTFILES_DIR="$HOME/.config/nixos/dotfiles"
VSCODE_USER_DIR="$HOME/.config/Code/User"
SETTINGS_SRC="$DOTFILES_DIR/.config/Code/User/settings.json"
SETTINGS_DEST="$VSCODE_USER_DIR/settings.json"
EXT_LIST="$DOTFILES_DIR/vscode-extensions.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Setup VSCode settings
setup_settings() {
  log_info "Setting up VSCode settings..."
  
  # Verify source file exists
  if [[ ! -f "$SETTINGS_SRC" ]]; then
    log_error "Settings file not found: $SETTINGS_SRC"
    return 1
  fi
  
  # Create VSCode User directory
  if ! mkdir -p "$VSCODE_USER_DIR"; then
    log_error "Failed to create directory: $VSCODE_USER_DIR"
    return 1
  fi
  
  # Warn if overwriting existing settings
  if [[ -f "$SETTINGS_DEST" && ! -L "$SETTINGS_DEST" ]]; then
    log_warn "Existing settings.json found (not a symlink). It will be replaced."
  fi
  
  # Create symlink
  if ln -sf "$SETTINGS_SRC" "$SETTINGS_DEST"; then
    log_info "Successfully symlinked settings.json"
  else
    log_error "Failed to create symlink"
    return 1
  fi
}

# Install VSCode extensions
install_extensions() {
  log_info "Installing VSCode extensions..."
  
  # Check if code command exists
  if ! command -v code &> /dev/null; then
    log_error "'code' command not found. Please ensure VSCode is installed and in PATH."
    return 1
  fi
  
  # Check if extension list exists
  if [[ ! -f "$EXT_LIST" ]]; then
    log_warn "Extension list not found: $EXT_LIST"
    log_warn "Skipping extension installation."
    return 0
  fi
  
  local installed=0
  local already_installed=0
  local failed=0
  
  # Install each extension
  while IFS= read -r ext || [[ -n "$ext" ]]; do
    # Skip empty lines and comments
    [[ -z "$ext" || "$ext" =~ ^[[:space:]]*# ]] && continue
    
    # Trim whitespace
    ext=$(echo "$ext" | xargs)
    
    # Capture output to check if already installed
    local output
    if output=$(code --install-extension "$ext" 2>&1); then
      if echo "$output" | grep -q "is already installed"; then
        log_info "Already installed: $ext"
        ((already_installed++))
      else
        log_info "Installed: $ext"
        ((installed++))
      fi
    else
      log_warn "Failed to install: $ext"
      # Show the error details
      if echo "$output" | grep -q "not found"; then
        log_warn "  → Extension not found in marketplace"
      else
        log_warn "  → $(echo "$output" | grep -i "error\|failed" | head -1)"
      fi
      ((failed++))
    fi
  done < "$EXT_LIST"
  
  log_info "Extension installation complete: $installed installed, $already_installed already installed, $failed failed"
  return 0
}

# Main execution
main() {
  log_info "Starting VSCode FHS setup..."
  
  local exit_code=0
  
  # Setup settings
  if ! setup_settings; then
    log_error "Settings setup failed"
    exit_code=1
  fi
  
  # Install extensions (continue even if settings failed)
  if ! install_extensions; then
    log_error "Extension installation failed"
    exit_code=1
  fi
  
  if [[ $exit_code -eq 0 ]]; then
    log_info "VSCode FHS setup completed successfully!"
  else
    log_error "VSCode FHS setup completed with errors"
  fi
  
  return $exit_code
}

# Run main function
main
