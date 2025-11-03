#!/usr/bin/env bash
# Security scanning script for NixOS dotfiles
# Runs git-secrets and TruffleHog to detect secrets in the repository

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}🔐 Security Scanning for NixOS Dotfiles${NC}"
echo "=========================================="
echo

# Check if we're in a git repository
if [ ! -d "$REPO_ROOT/.git" ]; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

cd "$REPO_ROOT"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
if ! command_exists git-secrets; then
    echo -e "${RED}❌ git-secrets not found${NC}"
    echo "Run: nix-shell devenv.nix"
    exit 1
fi

if ! command_exists trufflehog; then
    echo -e "${RED}❌ trufflehog not found${NC}"
    echo "Run: nix-shell devenv.nix"
    exit 1
fi

# Parse arguments
SCAN_TYPE="${1:-quick}"
SCAN_HISTORY=false

case "$SCAN_TYPE" in
    quick)
        echo -e "${BLUE}Running quick scan...${NC}"
        ;;
    full)
        echo -e "${BLUE}Running full scan with history...${NC}"
        SCAN_HISTORY=true
        ;;
    history)
        echo -e "${BLUE}Running git history scan only...${NC}"
        SCAN_HISTORY=true
        ;;
    -h|--help)
        echo "Usage: $0 [quick|full|history]"
        echo
        echo "Scan types:"
        echo "  quick    - Fast scan of current files (default)"
        echo "  full     - Comprehensive scan including git history"
        echo "  history  - Git history scan only"
        echo
        echo "Examples:"
        echo "  $0              # Quick scan"
        echo "  $0 quick        # Quick scan"
        echo "  $0 full         # Full scan with history"
        echo "  $0 history      # History only"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Unknown scan type: $SCAN_TYPE${NC}"
        echo "Use: quick, full, or history"
        exit 1
        ;;
esac

echo

# Run git-secrets scan
echo -e "${YELLOW}📝 Running git-secrets scan...${NC}"
echo "-----------------------------------"

if [ "$SCAN_HISTORY" = true ]; then
    if git secrets --scan-history; then
        echo -e "${GREEN}✅ git-secrets history scan: No secrets found${NC}"
    else
        echo -e "${RED}❌ git-secrets history scan: Secrets detected!${NC}"
        exit 1
    fi
else
    if git secrets --scan; then
        echo -e "${GREEN}✅ git-secrets scan: No secrets found${NC}"
    else
        echo -e "${RED}❌ git-secrets scan: Secrets detected!${NC}"
        exit 1
    fi
fi

echo

# Run TruffleHog scan
echo -e "${YELLOW}🐷 Running TruffleHog scan...${NC}"
echo "-----------------------------------"

# Run TruffleHog with appropriate flags
TRUFFLEHOG_ARGS="git file://. --only-verified"

if [ "$SCAN_HISTORY" = true ]; then
    echo "Scanning entire git history (this may take a while)..."
else
    echo "Scanning for verified secrets..."
fi

# Capture TruffleHog output
TRUFFLEHOG_OUTPUT=$(mktemp)
if trufflehog $TRUFFLEHOG_ARGS 2>&1 | tee "$TRUFFLEHOG_OUTPUT"; then
    # Check if any secrets were found by looking for "verified_secrets": [1-9]
    if grep -q '"verified_secrets": [1-9]' "$TRUFFLEHOG_OUTPUT" || grep -q "Found verified result" "$TRUFFLEHOG_OUTPUT"; then
        echo
        echo -e "${RED}❌ TruffleHog: Verified secrets detected!${NC}"
        rm "$TRUFFLEHOG_OUTPUT"
        exit 1
    else
        echo
        echo -e "${GREEN}✅ TruffleHog: No verified secrets found${NC}"
        
        # Extract scan statistics
        if grep -q "finished scanning" "$TRUFFLEHOG_OUTPUT"; then
            echo
            grep "finished scanning" "$TRUFFLEHOG_OUTPUT" | grep -o '"[^"]*":[^,}]*' | while IFS=':' read -r key value; do
                key=$(echo "$key" | tr -d '"')
                value=$(echo "$value" | tr -d '"' | xargs)
                echo "  • $key: $value"
            done
        fi
    fi
    rm "$TRUFFLEHOG_OUTPUT"
else
    echo -e "${RED}❌ TruffleHog scan failed${NC}"
    rm "$TRUFFLEHOG_OUTPUT"
    exit 1
fi

echo
echo -e "${GREEN}=========================================="
echo -e "✅ All security scans passed!"
echo -e "==========================================${NC}"
echo

# Provide recommendations
echo -e "${BLUE}💡 Recommendations:${NC}"
echo "  • Run 'full' scans before making the repository public"
echo "  • Rotate any secrets immediately if found"
echo "  • Use SOPS/age for encrypting sensitive data"
echo "  • See docs/SECURITY-SCANNING.md for more info"
echo

exit 0
