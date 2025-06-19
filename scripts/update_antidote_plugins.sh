#!/usr/bin/env zsh

# Update antidote plugins by regenerating plugins.zsh
# This script uses the system-installed antidote to generate the plugins file

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
NIXOS_CONFIG_DIR="${SCRIPT_DIR:h}"
PLUGINS_TXT="$NIXOS_CONFIG_DIR/dotfiles/dot_config/zsh/plugins.txt"
PLUGINS_ZSH="$NIXOS_CONFIG_DIR/dotfiles/dot_config/zsh/plugins.zsh"

echo "🔄 Updating antidote plugins..."

# Try to find system antidote installation
ANTIDOTE_PATH=""

# Method 1: Try nix-locate (if database exists)
if command -v nix-locate >/dev/null 2>&1; then
    # Get the full path, not just the package name
    ANTIDOTE_PATH=$(nix-locate --regex '/share/antidote/antidote\.zsh$' 2>/dev/null | grep -o '/nix/store/[^[:space:]]*antidote\.zsh' | head -1 || true)
fi

# Method 2: Fallback to find in /nix/store
if [[ -z "$ANTIDOTE_PATH" ]]; then
    echo "⚠️  nix-locate not available or database not built, searching /nix/store..."
    ANTIDOTE_PATH=$(find /nix/store -name "antidote.zsh" -path "*/share/antidote/antidote.zsh" 2>/dev/null | head -1)
fi

# Method 3: Try common system paths
if [[ -z "$ANTIDOTE_PATH" ]]; then
    for path in /nix/store/*/share/antidote/antidote.zsh; do
        if [[ -f "$path" ]]; then
            ANTIDOTE_PATH="$path"
            break
        fi
    done
fi

if [[ -z "$ANTIDOTE_PATH" ]]; then
    echo "❌ Error: antidote not found in system"
    echo "💡 Make sure antidote is installed in your NixOS configuration"
    echo "💡 You may also need to update your nix-locate database: nix-locate --update"
    exit 1
fi

echo "📍 Using system antidote: $ANTIDOTE_PATH"

# Generate plugins.zsh using system antidote
echo "🔧 Generating plugins.zsh..."
source "$ANTIDOTE_PATH"
antidote bundle < "$PLUGINS_TXT" > "$PLUGINS_ZSH"

echo "✅ Plugins updated successfully!"
echo "📁 Generated: $PLUGINS_ZSH"
