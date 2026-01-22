#!/usr/bin/env bash
# NixOS Initial System Deployment
# Wrapper around nixos-anywhere for initial system provisioning
# Handles pre-deployment validation and provides user-friendly interface

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
error() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="${FLAKE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

usage() {
    cat <<EOF
NixOS Initial System Deployment

Usage: $0 <system> <target-ip> [options]

Arguments:
  system     - System name from flake (e.g., cortex, nexus)
  target-ip  - Target machine IP or hostname

Options:
  --validate-secrets  - Validate secrets before deployment
  --skip-build       - Skip local build verification
  --flake-dir PATH   - Override flake directory (default: auto-detect)

Environment Variables:
  FLAKE_DIR - Path to flake directory (default: auto-detected)

Examples:
  $0 cortex 192.168.1.7
  $0 nexus 192.168.1.22 --validate-secrets
  FLAKE_DIR=/path/to/flake $0 axon 192.168.1.11

WARNING: This will WIPE THE TARGET DISK and install NixOS from scratch!
         Only use for initial system provisioning.

For updates to existing systems, use Colmena:
  nix run .#colmena -- apply --on <system>
EOF
}

validate_secrets() {
    local system="$1"
    local secrets_manager="$FLAKE_DIR/scripts/secrets-manager.sh"
    
    if [ ! -x "$secrets_manager" ]; then
        warn "Secrets manager not found at: $secrets_manager"
        warn "Skipping secrets validation"
        return 0
    fi
    
    info "Validating secrets for $system..."
    
    if ! "$secrets_manager" validate &>/dev/null; then
        error "Secrets validation failed. Run: $secrets_manager validate"
    fi
    
    if "$secrets_manager" cat | grep -q "^$system:"; then
        success "Secrets found for $system"
    else
        warn "No secrets found for $system (may be intentional)"
    fi
}

build_config() {
    local system="$1"
    
    info "Building $system configuration locally..."
    if nix build "$FLAKE_DIR#nixosConfigurations.$system.config.system.build.toplevel" --show-trace; then
        success "Build successful for $system"
    else
        error "Build failed for $system. Fix configuration errors before deploying."
    fi
}

deploy() {
    local system="$1"
    local target_ip="$2"
    local skip_build="${3:-false}"
    local validate_secrets_flag="${4:-false}"
    
    # Validate arguments
    if [ -z "$system" ] || [ -z "$target_ip" ]; then
        error "System name and target IP are required"
    fi
    
    # Check if flake exists
    if [ ! -f "$FLAKE_DIR/flake.nix" ]; then
        error "Flake not found at: $FLAKE_DIR/flake.nix"
    fi
    
    # Check if system exists in flake
    if ! nix eval "$FLAKE_DIR#nixosConfigurations" --apply 'builtins.attrNames' --json 2>/dev/null | jq -e ".[] | select(. == \"$system\")" >/dev/null; then
        error "System '$system' not found in flake configurations"
    fi
    
    # Validate secrets if requested
    if [ "$validate_secrets_flag" = "true" ]; then
        validate_secrets "$system"
    fi
    
    # Build config locally unless skipped
    if [ "$skip_build" = "false" ]; then
        build_config "$system"
    fi
    
    # Final confirmation
    echo ""
    warn "═══════════════════════════════════════════════════════════"
    warn "  DESTRUCTIVE OPERATION - THIS WILL WIPE THE TARGET DISK!"
    warn "═══════════════════════════════════════════════════════════"
    echo ""
    info "System:     $system"
    info "Target IP:  $target_ip"
    info "Flake:      $FLAKE_DIR"
    echo ""
    warn "This will:"
    echo "  1. Connect to $target_ip as root"
    echo "  2. Partition and format the disk"
    echo "  3. Install NixOS with configuration from $system"
    echo ""
    read -r -p "Type 'yes' to continue: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        info "Cancelled"
        exit 0
    fi
    
    # Deploy with nixos-anywhere
    info "Deploying $system to $target_ip..."
    echo ""
    
    if nix run github:nix-community/nixos-anywhere -- --flake "$FLAKE_DIR#$system" "root@$target_ip"; then
        echo ""
        success "═══════════════════════════════════════"
        success "  Deployment complete!"
        success "═══════════════════════════════════════"
        echo ""
        info "Next steps:"
        echo "  1. SSH into the system: ssh <user>@$target_ip"
        echo "  2. Verify services: systemctl status"
        echo "  3. For future updates, use Colmena:"
        echo "     nix run .#colmena -- apply --on $system"
        return 0
    else
        echo ""
        error "Deployment failed!"
        info "Check logs above for errors"
        return 1
    fi
}

# Main execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
    fi
    
    system="${1:-}"
    target_ip="${2:-}"
    skip_build=false
    validate_secrets_flag=false
    
    shift 2 || { usage; exit 1; }
    
    # Parse options
    while [ $# -gt 0 ]; do
        case "$1" in
            --validate-secrets)
                validate_secrets_flag=true
                shift
                ;;
            --skip-build)
                skip_build=true
                shift
                ;;
            --flake-dir)
                FLAKE_DIR="$2"
                shift 2
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    deploy "$system" "$target_ip" "$skip_build" "$validate_secrets_flag"
fi
