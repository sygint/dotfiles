#!/usr/bin/env bash
# bootstrap-nixos.sh - Fully Automated NixOS Bootstrap with Secrets
# 
# This script automates the complete bootstrap process:
# 1. Validates prerequisites
# 2. Installs NixOS via nixos-anywhere
# 3. Extracts age key from SSH host key
# 4. Updates secrets configuration automatically
# 5. Rekeys all secrets
# 6. Deploys full configuration with secrets
# 7. Validates the deployment
#
# Usage: ./bootstrap-nixos.sh <hostname> <ip-address>
# Example: ./bootstrap-nixos.sh cortex 192.168.1.7
#
# Requirements:
# - nixos-anywhere
# - sops
# - ssh-to-age
# - deploy-rs
# - jq, yq (for YAML manipulation)

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIXOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SECRETS_DIR="$NIXOS_DIR/../nixos-secrets"

# Parse arguments
HOST=${1:-}
TARGET_IP=${2:-}

# Logging functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }
log_step() { echo -e "${CYAN}→${NC} $*"; }

# Error handler
error_exit() {
    log_error "$1"
    echo ""
    echo "Bootstrap failed. See error above for details."
    exit 1
}

# Validate arguments
if [[ -z "$HOST" ]] || [[ -z "$TARGET_IP" ]]; then
    log_error "Missing required arguments"
    echo ""
    echo "Usage: $0 <hostname> <ip-address>"
    echo ""
    echo "Example: $0 cortex 192.168.1.7"
    echo ""
    echo "Available hosts:"
    for host_dir in "$NIXOS_DIR"/systems/*/; do
        host=$(basename "$host_dir")
        [[ "$host" == "custom-live-iso" ]] && continue
        echo "  - $host"
    done
    exit 1
fi

# ============================================================================
# PHASE 0: Validation & Prerequisites
# ============================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   NixOS Automated Bootstrap with Secrets          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

log_step "Validating prerequisites..."

# Check required tools
REQUIRED_TOOLS=("nixos-anywhere" "sops" "ssh-to-age" "deploy" "jq" "yq")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        error_exit "Required tool not found: $tool"
    fi
done
log_success "All required tools available"

# Check host configuration exists
if [[ ! -d "$NIXOS_DIR/systems/$HOST" ]]; then
    error_exit "Configuration for '$HOST' not found at $NIXOS_DIR/systems/$HOST"
fi
log_success "Host configuration found"

# Check secrets directory
if [[ ! -d "$SECRETS_DIR" ]]; then
    error_exit "Secrets directory not found at $SECRETS_DIR"
fi
log_success "Secrets directory found"

# Check liveiso key
LIVEISO_KEY="$SECRETS_DIR/keys/liveiso"
if [[ ! -f "$LIVEISO_KEY" ]]; then
    error_exit "LiveISO key not found at $LIVEISO_KEY"
fi
log_success "LiveISO key found"

# Load host variables
log_step "Loading host configuration..."
VARS=$(nix eval --json "$NIXOS_DIR#nixosConfigurations.$HOST.config.variables" 2>/dev/null || echo "{}")
if [[ "$VARS" == "{}" ]]; then
    log_warning "Could not load variables from Nix config, using defaults"
    SSH_USER="root"
    NEEDS_SECRETS=true
else
    SSH_USER=$(echo "$VARS" | jq -r '.ssh.user // "root"')
    NEEDS_SECRETS=$(echo "$VARS" | jq -r '.secrets.required // true')
fi

# Display configuration
echo ""
echo -e "${BLUE}Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}Host:${NC}           $HOST"
echo -e "${CYAN}Target IP:${NC}      $TARGET_IP"
echo -e "${CYAN}SSH User:${NC}       $SSH_USER"
echo -e "${CYAN}Needs Secrets:${NC}  $NEEDS_SECRETS"
echo -e "${CYAN}Config Path:${NC}    $NIXOS_DIR/systems/$HOST"
echo -e "${CYAN}Secrets Path:${NC}   $SECRETS_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if this is a re-bootstrap
AGE_KEY_FILE="$SECRETS_DIR/keys/hosts/$HOST.txt"
if [[ -f "$AGE_KEY_FILE" ]]; then
    EXISTING_AGE_KEY=$(cat "$AGE_KEY_FILE")
    log_warning "Age key already exists for this host"
    echo "         Existing key: ${EXISTING_AGE_KEY:0:30}..."
    echo ""
    log_warning "This appears to be a RE-BOOTSTRAP"
    echo "         The existing age key will be used"
    echo "         Secrets should work immediately after bootstrap"
    IS_REBOOTSTRAP=true
else
    log_info "No existing age key found - this is a NEW HOST"
    echo "       Age key will be generated and added to secrets"
    IS_REBOOTSTRAP=false
fi

echo ""
read -p "$(echo -e ${YELLOW}Continue with bootstrap? [y/N]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Bootstrap cancelled."
    exit 0
fi

# ============================================================================
# PHASE 1: Bootstrap Installation
# ============================================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}PHASE 1: Installing NixOS${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_step "Installing base system via nixos-anywhere..."
if nixos-anywhere \
    --flake "$NIXOS_DIR#$HOST" \
    --ssh-option "IdentityFile=$LIVEISO_KEY" \
    --ssh-option "StrictHostKeyChecking=no" \
    --ssh-option "UserKnownHostsFile=/dev/null" \
    "root@$TARGET_IP"; then
    log_success "Base installation complete"
else
    error_exit "nixos-anywhere installation failed"
fi

# Wait for system to stabilize
log_step "Waiting for system to stabilize..."
sleep 15

# Verify SSH connectivity
log_step "Verifying SSH connectivity..."
MAX_RETRIES=12
RETRY_COUNT=0
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    if ssh -o ConnectTimeout=5 \
           -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           "root@$TARGET_IP" "echo 'SSH OK'" &>/dev/null; then
        log_success "SSH connectivity verified"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [[ $RETRY_COUNT -eq $MAX_RETRIES ]]; then
        error_exit "Failed to establish SSH connection after installation"
    fi
    echo -n "."
    sleep 5
done

# ============================================================================
# PHASE 2: Extract and Configure Age Key
# ============================================================================
if [[ "$NEEDS_SECRETS" == "true" ]]; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}PHASE 2: Configuring Secrets${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Extract age key
    log_step "Extracting age key from SSH host key..."
    NEW_AGE_KEY=$(ssh-keyscan -t ed25519 "$TARGET_IP" 2>/dev/null | ssh-to-age)
    
    if [[ -z "$NEW_AGE_KEY" ]]; then
        error_exit "Failed to extract age key from host"
    fi
    
    log_success "Age key extracted: ${NEW_AGE_KEY:0:30}..."
    
    # Check if key changed (re-bootstrap scenario)
    if [[ "$IS_REBOOTSTRAP" == "true" ]]; then
        if [[ "$NEW_AGE_KEY" != "$EXISTING_AGE_KEY" ]]; then
            log_error "AGE KEY MISMATCH!"
            echo ""
            echo "The new age key does NOT match the existing one in secrets!"
            echo ""
            echo "Existing: $EXISTING_AGE_KEY"
            echo "New:      $NEW_AGE_KEY"
            echo ""
            log_warning "This likely means:"
            echo "  1. The SSH host key was regenerated (unexpected)"
            echo "  2. You're bootstrapping a different machine with the same name"
            echo ""
            echo "Options:"
            echo "  a) Update secrets with new key (will need to re-encrypt)"
            echo "  b) Restore old SSH host key to this machine"
            echo "  c) Cancel and investigate"
            echo ""
            read -p "Update secrets with new key? [y/N]: " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                error_exit "Bootstrap cancelled due to key mismatch"
            fi
        else
            log_success "Age key matches existing key (re-bootstrap successful)"
        fi
    fi
    
    # Save age key
    log_step "Saving age key to secrets repository..."
    mkdir -p "$(dirname "$AGE_KEY_FILE")"
    echo "$NEW_AGE_KEY" > "$AGE_KEY_FILE"
    log_success "Age key saved to $AGE_KEY_FILE"
    
    # Update .sops.yaml if needed
    cd "$SECRETS_DIR"
    
    log_step "Updating .sops.yaml..."
    SOPS_YAML=".sops.yaml"
    
    # Backup .sops.yaml
    cp "$SOPS_YAML" "${SOPS_YAML}.backup"
    log_info "Backed up .sops.yaml to ${SOPS_YAML}.backup"
    
    # Check if host already in .sops.yaml
    if grep -q "&$HOST " "$SOPS_YAML"; then
        log_info "Host '$HOST' already in .sops.yaml"
        
        # Update the key value
        # Using yq to update YAML safely
        yq eval "(.keys[] | select(. == \"*$HOST\")) |= \"$NEW_AGE_KEY\"" -i "$SOPS_YAML" || {
            log_warning "Failed to update key automatically, manual update may be needed"
        }
    else
        log_step "Adding host '$HOST' to .sops.yaml..."
        
        # Add new key anchor
        # Insert before creation_rules section
        yq eval ".keys += [\"&$HOST $NEW_AGE_KEY\"]" -i "$SOPS_YAML"
        
        # Add to creation_rules
        yq eval "(.creation_rules[0].key_groups[0].age) += [\"*$HOST\"]" -i "$SOPS_YAML"
        
        log_success "Added $HOST to .sops.yaml"
    fi
    
    # Rekey secrets
    log_step "Rekeying secrets for all hosts..."
    if sops updatekeys secrets.yaml; then
        log_success "Secrets rekeyed successfully"
    else
        error_exit "Failed to rekey secrets"
    fi
    
    cd "$NIXOS_DIR"
fi

# ============================================================================
# PHASE 3: Deploy Full Configuration with Secrets
# ============================================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}PHASE 3: Deploying Full Configuration${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_step "Deploying with deploy-rs..."
if deploy --targets ".#$HOST"; then
    log_success "Deployment successful"
else
    log_error "Deployment failed"
    echo ""
    log_warning "The base system is installed and secrets are configured,"
    echo "         but the full deployment encountered an error."
    echo ""
    echo "You can retry with: just deploy-$HOST"
    exit 1
fi

# ============================================================================
# PHASE 4: Validation
# ============================================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}PHASE 4: Validation${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_step "Testing SSH connectivity with deployed user..."
if ssh -o ConnectTimeout=10 \
       -o StrictHostKeyChecking=no \
       "$SSH_USER@$TARGET_IP" "echo 'Connection OK'" &>/dev/null; then
    log_success "SSH connectivity verified"
else
    log_warning "Could not connect as $SSH_USER (this may be expected initially)"
fi

if [[ "$NEEDS_SECRETS" == "true" ]]; then
    log_step "Verifying secrets decryption..."
    if ssh -o ConnectTimeout=10 \
           -o StrictHostKeyChecking=no \
           "$SSH_USER@$TARGET_IP" \
           "systemctl is-active sops-nix.service" &>/dev/null; then
        log_success "Secrets service is active"
    else
        log_warning "Secrets service status could not be verified"
        echo "         Check manually: ssh $SSH_USER@$TARGET_IP 'systemctl status sops-nix'"
    fi
fi

# ============================================================================
# COMPLETION
# ============================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Bootstrap Complete! 🎉                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Host Details:${NC}"
echo "  Name:        $HOST"
echo "  IP:          $TARGET_IP"
echo "  SSH User:    $SSH_USER"
if [[ "$NEEDS_SECRETS" == "true" ]]; then
    echo "  Age Key:     ${NEW_AGE_KEY:0:40}..."
    echo "  Key File:    $AGE_KEY_FILE"
fi
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Test SSH:        ssh $SSH_USER@$TARGET_IP"
echo "  2. Deploy updates:  just deploy-$HOST"
echo "  3. Wake on LAN:     just wake-$HOST (if configured)"
echo ""
if [[ "$NEEDS_SECRETS" == "true" ]] && [[ "$IS_REBOOTSTRAP" == "false" ]]; then
    echo -e "${YELLOW}Important:${NC}"
    echo "  • Commit the new age key to your secrets repository:"
    echo "    cd $SECRETS_DIR"
    echo "    git add keys/hosts/$HOST.txt .sops.yaml"
    echo "    git commit -m 'feat: add age key for $HOST'"
    echo ""
fi
log_success "Bootstrap automation complete!"
echo ""
