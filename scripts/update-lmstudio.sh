#!/usr/bin/env bash
# Update LM Studio version in custom Nix package
set -euo pipefail

PACKAGE_FILE="$HOME/.config/nixos/packages/lmstudio.nix"

echo "📡 Fetching latest LM Studio version..."

# Get current major.minor.patch from package file (e.g., 0.4.7)
CURRENT_BASE=$(grep 'version = "' "$PACKAGE_FILE" | sed 's/.*"\(0\.[0-9]*\.[0-9]*\).*/\1/')
echo "Current base version: $CURRENT_BASE"

# Fetch latest build number from LM Studio API (returns integer, e.g., 4)
LATEST_BUILD=$(curl -s "https://versions-prod.lmstudio.ai/update/linux/x86/$CURRENT_BASE" | jq -r '.build')

if [[ "$LATEST_BUILD" == "null" || -z "$LATEST_BUILD" ]]; then
    echo "❌ Failed to fetch version from API"
    exit 1
fi

NEW_VERSION="${CURRENT_BASE}-${LATEST_BUILD}"
echo "Latest build: $NEW_VERSION (build ${LATEST_BUILD})"

# Check if update needed
CURRENT_FULL=$(grep 'version = "' "$PACKAGE_FILE" | sed 's/.*"\([^"]*\)".*/\1/')
if [[ "$CURRENT_FULL" == "$NEW_VERSION" ]]; then
    echo "✅ Already up to date: $CURRENT_FULL"
    exit 0
fi

echo "🔄 Updating package file..."
sed -i "s/version = \"[^\"]*\"/version = \"$NEW_VERSION\"/" "$PACKAGE_FILE"

# Update hash placeholder for rebuild
sed -i 's/hash = "sha256-[^"]*"/hash = lib.fakeHash/' "$PACKAGE_FILE"

echo "✅ Updated to $NEW_VERSION"
echo ""
echo "📝 Next steps:"
echo "   1. Run: nix build .\#packages.x86_64-linux.lmstudio"
echo "   2. Copy the new hash from the error message"
echo "   3. Replace lib.fakeHash with the actual hash in $PACKAGE_FILE"
echo "   4. Rebuild your system: nos"
