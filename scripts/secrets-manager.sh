#!/usr/bin/env bash
# NixOS Secrets Management CLI
# Wrapper around sops for easier secret management
#
# This tool can be used with any secrets repository.
# By default, it looks for a 'nixos-secrets' directory next to your nixos config.
# shellcheck disable=SC2317  # Don't warn about unreachable commands

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
error() { echo -e "${RED}✗ $*${NC}"; log_operation "ERROR" "$*"; exit 1; }

# === Logging ===

LOG_FILE="${HOME}/.nixos-secrets.log"

log_operation() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Log all operations
log_cmd() {
    local cmd="$1"
    shift
    log_operation "INFO" "Command: $cmd $*"
}

# === Security: Cleanup temporary files ===

TEMP_FILES=()

cleanup_temp_files() {
    for temp_file in "${TEMP_FILES[@]}"; do
        if [ -f "$temp_file" ]; then
            # Use shred if available (securely delete), otherwise rm
            if command -v shred &> /dev/null; then
                shred -u "$temp_file" 2>/dev/null || rm -f "$temp_file"
            else
                rm -f "$temp_file"
            fi
        fi
    done
}

trap cleanup_temp_files EXIT INT TERM

# === Configuration ===

# You can override these via environment variables or command line flags
SECRETS_REPO="${SECRETS_REPO:-}"
SECRETS_FILE="${SECRETS_FILE:-}"
AGE_KEY_FILE="${AGE_KEY_FILE:-}"
HOSTNAME="${HOSTNAME:-$(hostname)}"

# Auto-detect secrets location if not specified
if [ -z "$SECRETS_REPO" ]; then
    # Try common locations
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    NIXOS_DIR="$(dirname "$SCRIPT_DIR")"
    
    # Check for nixos-secrets next to nixos config
    if [ -d "$NIXOS_DIR/../nixos-secrets" ]; then
        SECRETS_REPO="$NIXOS_DIR/../nixos-secrets"
    elif [ -d "$HOME/.config/nixos-secrets" ]; then
        SECRETS_REPO="$HOME/.config/nixos-secrets"
    elif [ -d "$HOME/nixos-secrets" ]; then
        SECRETS_REPO="$HOME/nixos-secrets"
    else
        error "Cannot find secrets repository. Set SECRETS_REPO environment variable."
    fi
fi

SECRETS_REPO="$(cd "$SECRETS_REPO" && pwd)"  # Absolute path

# Determine secrets file
if [ -z "$SECRETS_FILE" ]; then
    SECRETS_FILE="$SECRETS_REPO/secrets.yaml"
fi

# Determine age key file (try to auto-detect based on hostname)
if [ -z "$AGE_KEY_FILE" ]; then
    # Try hostname-specific key first
    if [ -f "$SECRETS_REPO/keys/hosts/$HOSTNAME.txt" ]; then
        AGE_KEY_FILE="$SECRETS_REPO/keys/hosts/$HOSTNAME.txt"
    # Try generic age-key.txt
    elif [ -f "$SECRETS_REPO/keys/age-key.txt" ]; then
        AGE_KEY_FILE="$SECRETS_REPO/keys/age-key.txt"
    # Try orion (common control machine)
    elif [ -f "$SECRETS_REPO/keys/hosts/orion.txt" ]; then
        AGE_KEY_FILE="$SECRETS_REPO/keys/hosts/orion.txt"
    else
        error "Cannot find age key. Set AGE_KEY_FILE environment variable."
    fi
fi

# Check if age key exists
if [ ! -f "$AGE_KEY_FILE" ]; then
    error "Age key not found at: $AGE_KEY_FILE"
fi

# Check age key permissions for security
if [ -f "$AGE_KEY_FILE" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        perms=$(stat -f '%A' "$AGE_KEY_FILE" 2>/dev/null)
    else
        perms=$(stat -c '%a' "$AGE_KEY_FILE" 2>/dev/null)
    fi
    
    if [ -n "$perms" ] && [ "$perms" != "600" ] && [ "$perms" != "400" ]; then
        warn "Age key has weak permissions: $perms (should be 600)"
        warn "Fix with: chmod 600 $AGE_KEY_FILE"
    fi
fi

# Export for sops
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"

usage() {
    cat << EOF
${GREEN}NixOS Secrets Management CLI${NC}

${CYAN}Detected Configuration:${NC}
  Secrets Repo:    ${SECRETS_REPO}
  Secrets File:    ${SECRETS_FILE}
  Age Key:         ${AGE_KEY_FILE}
  Hostname:        ${HOSTNAME}

${BLUE}Usage:${NC} $0 <command> [options]

${BLUE}Commands:${NC}
  ${GREEN}edit${NC}              Edit secrets (opens in \$EDITOR)
  ${GREEN}view${NC}              View decrypted secrets (read-only)
  ${GREEN}cat${NC}               Print decrypted secrets to stdout
  ${GREEN}validate${NC}          Test decrypt/encrypt roundtrip
  ${GREEN}add-host <host>${NC}   Add password for a new host
  ${GREEN}rotate-host <host>${NC} Rotate password for existing host
  ${GREEN}status${NC}            Show secrets file status and recipients
  ${GREEN}config${NC}            Show current configuration
  ${GREEN}backup${NC}            Create timestamped backup of secrets
  ${GREEN}recipients${NC}        Show who can decrypt secrets

${BLUE}Examples:${NC}
  $0 edit                    # Edit secrets in your editor
  $0 view                    # View current secrets
  $0 config                  # Show detected configuration
  $0 add-host axon           # Add password for new host 'axon'
  $0 rotate-host nexus       # Generate new password for nexus
  $0 validate                # Test that encryption works

${BLUE}Environment Variables:${NC}
  SECRETS_REPO              Path to secrets repository (auto-detected)
  SECRETS_FILE              Path to secrets.yaml (default: \$SECRETS_REPO/secrets.yaml)
  AGE_KEY_FILE              Path to age private key (auto-detected by hostname)
  EDITOR                    Editor to use (default: nano)

${BLUE}Examples with Custom Paths:${NC}
  SECRETS_REPO=~/my-secrets $0 edit
  AGE_KEY_FILE=~/my-key.txt $0 cat
  SECRETS_REPO=/path/to/secrets AGE_KEY_FILE=/path/to/key $0 status

${BLUE}Auto-Detection:${NC}
  - Secrets repo: Looks for nixos-secrets/ next to nixos config, ~/.config/nixos-secrets, or ~/nixos-secrets
  - Age key: Looks for keys/hosts/\$(hostname).txt, keys/age-key.txt, or keys/hosts/orion.txt
EOF
}

# Check if sops is available
ensure_sops() {
    if ! command -v sops &> /dev/null; then
        info "sops not found, running via nix shell..."
        SOPS_CMD="nix shell nixpkgs#sops -c sops"
    else
        SOPS_CMD="sops"
    fi
}

# Edit secrets
cmd_edit() {
    ensure_sops
    
    # Check for uncommitted changes
    if [ -d "$SECRETS_REPO/.git" ]; then
        if ! git -C "$SECRETS_REPO" diff-index --quiet HEAD -- secrets.yaml 2>/dev/null; then
            warn "secrets.yaml has uncommitted changes"
            read -r -p "Continue editing anyway? [y/N] " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                info "Edit cancelled"
                return 0
            fi
        fi
    fi
    
    # Auto-backup before editing
    info "Creating backup before edit..."
    cmd_backup
    
    info "Opening secrets for editing..."
    $SOPS_CMD "$SECRETS_FILE"
    success "Secrets saved"
}

# View secrets (read-only)
cmd_view() {
    ensure_sops
    info "Decrypting secrets (read-only)..."
    $SOPS_CMD "$SECRETS_FILE" | ${PAGER:-less}
}

# Cat secrets to stdout
cmd_cat() {
    ensure_sops
    $SOPS_CMD --decrypt "$SECRETS_FILE"
}

# Validate encryption/decryption
cmd_validate() {
    ensure_sops
    info "Testing decrypt..."
    
    if $SOPS_CMD --decrypt "$SECRETS_FILE" > /dev/null 2>&1; then
        success "✓ Decryption works"
    else
        error "✗ Decryption failed"
    fi
    
    # Test re-encryption
    info "Testing re-encrypt..."
    TEMP_FILE=$(mktemp --suffix=.yaml)
    TEMP_FILES+=("$TEMP_FILE")
    
    $SOPS_CMD --decrypt "$SECRETS_FILE" > "$TEMP_FILE"
    
    ENCRYPTED_TEMP=$(mktemp --suffix=.yaml.enc)
    TEMP_FILES+=("$ENCRYPTED_TEMP")
    
    if (cd "$SECRETS_REPO" && $SOPS_CMD --encrypt "$TEMP_FILE") > "$ENCRYPTED_TEMP" 2>&1; then
        # Validate encrypted file is not empty
        if [ ! -s "$ENCRYPTED_TEMP" ]; then
            error "✗ Encrypted file is empty!"
        fi
        success "✓ Encryption works"
    else
        error "✗ Encryption failed"
    fi
    
    success "All checks passed!"
}

# Show who can decrypt
cmd_recipients() {
    ensure_sops
    info "Checking recipients..."
    echo
    $SOPS_CMD --decrypt "$SECRETS_FILE" 2>&1 | grep -A 20 "sops:" || true
    echo
    info "Configured in .sops.yaml:"
    if [ -f "$SECRETS_REPO/.sops.yaml" ]; then
        grep -A 10 "keys:" "$SECRETS_REPO/.sops.yaml" | grep "age1" | while read -r line; do
            key=$(echo "$line" | grep -oE "age1[a-z0-9]*")
            if echo "$line" | grep -q "orion"; then
                echo -e "  ${GREEN}✓ Orion (control):${NC} $key"
            elif echo "$line" | grep -q "cortex"; then
                echo -e "  ${BLUE}• Cortex (deploy):${NC} $key"
            elif echo "$line" | grep -q "nexus"; then
                echo -e "  ${BLUE}• Nexus (deploy):${NC} $key"
            else
                echo "  • $key"
            fi
        done
    else
        warn ".sops.yaml not found at $SECRETS_REPO/.sops.yaml"
    fi
}

# Show configuration
cmd_config() {
    info "Current Configuration"
    echo
    echo -e "  ${CYAN}Secrets Repository:${NC} $SECRETS_REPO"
    echo -e "  ${CYAN}Secrets File:${NC}       $SECRETS_FILE"
    echo -e "  ${CYAN}Age Key File:${NC}       $AGE_KEY_FILE"
    echo -e "  ${CYAN}Hostname:${NC}           $HOSTNAME"
    echo
    echo -e "  ${CYAN}Files Exist:${NC}"
    [ -d "$SECRETS_REPO" ] && echo "    ✓ Secrets repo exists" || echo "    ✗ Secrets repo NOT FOUND"
    [ -f "$SECRETS_FILE" ] && echo "    ✓ Secrets file exists" || echo "    ✗ Secrets file NOT FOUND"
    [ -f "$AGE_KEY_FILE" ] && echo "    ✓ Age key exists" || echo "    ✗ Age key NOT FOUND"
    echo
    echo -e "  ${CYAN}.sops.yaml:${NC}         $SECRETS_REPO/.sops.yaml"
    [ -f "$SECRETS_REPO/.sops.yaml" ] && echo "    ✓ Configuration exists" || echo "    ✗ Configuration NOT FOUND"
}

# Show status
cmd_status() {
    info "Secrets Status"
    echo
    echo "  File: $SECRETS_FILE"
    echo "  Size: $(du -h "$SECRETS_FILE" | cut -f1)"
    echo "  Modified: $(date -r "$SECRETS_FILE" '+%Y-%m-%d %H:%M:%S')"
    echo "  Age Key: $AGE_KEY_FILE"
    echo
    cmd_recipients
}

# Add new host
cmd_add_host() {
    local host="${1:-}"
    if [ -z "$host" ]; then
        error "Usage: $0 add-host <hostname>"
    fi
    
    # Validate hostname
    if [[ ! "$host" =~ ^[a-zA-Z0-9-]+$ ]]; then
        error "Invalid hostname: $host (only alphanumeric and hyphens allowed)"
    fi
    
    ensure_sops
    
    info "Generating password for $host..."
    
    # Generate password
    if command -v mkpasswd &> /dev/null; then
        read -r -p "Enter password for $host (or press Enter to generate): " -s password
        echo  # New line after hidden input
        
        if [ -z "$password" ]; then
            password=$(openssl rand -base64 16)
            warn "Password generated. Press Enter to reveal it briefly (5 seconds)..."
            read -r
            echo -e "${GREEN}Password: $password${NC}"
            sleep 5
            clear
            info "Password cleared from screen. Make sure you saved it!"
        fi
        hash=$(echo "$password" | mkpasswd -m sha-512 -s)
    else
        read -r -p "Enter password for $host: " -s password
        echo  # New line after hidden input
        hash=$(echo "$password" | nix shell nixpkgs#mkpasswd -c mkpasswd -m sha-512 -s)
    fi
    
    info "Adding $host to secrets..."
    
    # Create temp file with new entry
    TEMP_FILE=$(mktemp)
    TEMP_FILES+=("$TEMP_FILE")
    $SOPS_CMD --decrypt "$SECRETS_FILE" > "$TEMP_FILE"
    
    # Add new host
    {
        echo ""
        echo "$host:"
        echo "  maintenance_password_hash: \"$hash\""
    } >> "$TEMP_FILE"
    
    # Re-encrypt with validation
    ENCRYPTED_TEMP=$(mktemp)
    TEMP_FILES+=("$ENCRYPTED_TEMP")
    
    if (cd "$SECRETS_REPO" && $SOPS_CMD --encrypt "$TEMP_FILE") > "$ENCRYPTED_TEMP" 2>&1; then
        # Validate encrypted file is not empty
        if [ ! -s "$ENCRYPTED_TEMP" ]; then
            error "Encrypted file is empty! Not overwriting secrets."
        fi
        
        # Create backup before overwriting
        cp "$SECRETS_FILE" "$SECRETS_FILE.pre-add-$host"
        
        # Atomic move
        mv "$ENCRYPTED_TEMP" "$SECRETS_FILE"
        
        success "Added $host to secrets"
        warn "Remember to commit: cd $SECRETS_REPO && git add secrets.yaml && git commit -m 'add: $host secrets'"
    else
        error "Failed to re-encrypt secrets"
    fi
}

# Rotate host password
cmd_rotate_host() {
    local host="${1:-}"
    if [ -z "$host" ]; then
        error "Usage: $0 rotate-host <hostname>"
    fi
    
    # Validate hostname
    if [[ ! "$host" =~ ^[a-zA-Z0-9-]+$ ]]; then
        error "Invalid hostname: $host (only alphanumeric and hyphens allowed)"
    fi
    
    ensure_sops
    
    info "Rotating password for $host..."
    
    # Check if host exists
    if ! $SOPS_CMD --decrypt "$SECRETS_FILE" | grep -q "^$host:"; then
        error "Host '$host' not found in secrets. Use 'add-host' instead."
    fi
    
    # Generate new password
    read -r -p "Enter new password for $host (or press Enter to generate): " -s password
    echo  # New line after hidden input
    
    if [ -z "$password" ]; then
        password=$(openssl rand -base64 16)
        warn "Password generated. Press Enter to reveal it briefly (5 seconds)..."
        read -r
        echo -e "${GREEN}Password: $password${NC}"
        sleep 5
        clear
        info "Password cleared from screen. Make sure you saved it!"
    fi
    
    if command -v mkpasswd &> /dev/null; then
        hash=$(echo "$password" | mkpasswd -m sha-512 -s)
    else
        hash=$(echo "$password" | nix shell nixpkgs#mkpasswd -c mkpasswd -m sha-512 -s)
    fi
    
    # Update secrets
    TEMP_FILE=$(mktemp)
    TEMP_FILES+=("$TEMP_FILE")
    $SOPS_CMD --decrypt "$SECRETS_FILE" > "$TEMP_FILE"
    
    # Replace password (simple sed approach)
    sed -i "/^$host:/,/maintenance_password_hash:/ s|maintenance_password_hash:.*|maintenance_password_hash: \"$hash\"|" "$TEMP_FILE"
    
    # Re-encrypt with validation
    ENCRYPTED_TEMP=$(mktemp)
    TEMP_FILES+=("$ENCRYPTED_TEMP")
    
    if (cd "$SECRETS_REPO" && $SOPS_CMD --encrypt "$TEMP_FILE") > "$ENCRYPTED_TEMP" 2>&1; then
        # Validate encrypted file is not empty
        if [ ! -s "$ENCRYPTED_TEMP" ]; then
            error "Encrypted file is empty! Not overwriting secrets."
        fi
        
        # Create backup before overwriting
        cp "$SECRETS_FILE" "$SECRETS_FILE.pre-rotate-$host"
        
        # Atomic move
        mv "$ENCRYPTED_TEMP" "$SECRETS_FILE"
        
        success "Rotated password for $host"
        warn "Deploy to apply: cd $SECRETS_REPO/../nixos && ./scripts/deployment/fleet.sh update $host"
    else
        error "Failed to re-encrypt secrets"
    fi
}

# Create backup
cmd_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$SECRETS_REPO/secrets.yaml.backup.$timestamp"
    cp "$SECRETS_FILE" "$backup_file"
    success "Backup created: $backup_file"
}

# Main
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    cmd="$1"
    shift
    
    # Log the command
    log_cmd "$cmd" "$@"
    
    case "$cmd" in
        edit)
            cmd_edit "$@"
            ;;
        view)
            cmd_view "$@"
            ;;
        cat)
            cmd_cat "$@"
            ;;
        validate)
            cmd_validate "$@"
            ;;
        add-host)
            cmd_add_host "$@"
            ;;
        rotate-host)
            cmd_rotate_host "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        config)
            cmd_config "$@"
            ;;
        backup)
            cmd_backup "$@"
            ;;
        recipients)
            cmd_recipients "$@"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: $cmd"
            usage
            ;;
    esac
}

main "$@"
