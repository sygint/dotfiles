#!/usr/bin/env bash
# Unified NixOS Fleet Management Script
# Auto-discovers systems from flake.nix, supports deploy/update/build/check/list

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
error() { echo -e "${RED}✗ $*${NC}"; exit 1; }

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Auto-discover systems from flake.nix

get_systems() {
    nix eval "$FLAKE_DIR#nixosConfigurations" --apply 'builtins.attrNames' --json 2>/dev/null | jq -r '.[]'
}

# Load host variables from Nix config

get_host_vars() {
    local system="$1"
    # Try to load from Nix config first, fallback to reading variables.nix directly
    if nix eval --json "$FLAKE_DIR#nixosConfigurations.$system.config.variables" 2>/dev/null; then
        return 0
    fi
    
    # Fallback: read variables.nix directly and convert to JSON
    local vars_file="$FLAKE_DIR/systems/$system/variables.nix"
    if [[ -f "$vars_file" ]]; then
        nix-instantiate --eval --strict --json -E "import $vars_file" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

usage() {
    echo -e "${GREEN}Fleet Management Tool${NC}"
    echo "Usage: $0 <command> <system> [options]"
    echo "Commands:"
    echo "  list                List all systems"
    echo "  build <system>      Build system config locally"
    echo "  check <system> <hostname> [user]  Check connection and health"
    echo "  deploy <system> <ip> [user]       Initial deployment (nixos-anywhere)"
    echo "  update <system>     Update system (deploy-rs)"
    echo "Options:"
    echo "  --remote-build      Build on target (if supported)"
    echo "  --local             Force local deployment (nh)"
    echo "  --skip-checks       Skip health checks"
}

list_systems() {
    info "Available systems:"
    get_systems | awk '{print "  - "$1}'
}

build_system() {
    local system="${1:-}"
    if [ -z "$system" ]; then
        error "Usage: $0 build <system>"
    fi
    info "Building $system configuration..."
    nix build "$FLAKE_DIR#nixosConfigurations.$system.config.system.build.toplevel" --show-trace && success "Build successful for $system"
}

check_system() {
    local system="${1:-}"
    local timeout=10

    if [ -z "$system" ]; then
        error "Usage: $0 check <system>"
    fi

    # Load host variables
    local VARS
    VARS=$(get_host_vars "$system")
    local hostname
    local ssh_user
    hostname=$(echo "$VARS" | jq -r '.network.ip // .network.hostname // ""')
    ssh_user=$(echo "$VARS" | jq -r '.network.ssh.user // .user.username // "root"')

    if [ -z "$hostname" ]; then
        error "Could not determine hostname or IP for $system from config"
    fi

    info "Checking $system ($hostname) as $ssh_user..."

    # Step 1: SSH key check
    info "Step 1: Checking SSH keys..."
    if ssh-add -l &>/dev/null; then
        LOADED_KEYS=$(ssh-add -l | wc -l)
        success "SSH agent has $LOADED_KEYS key(s) loaded"
    else
        warn "SSH agent not running or no keys loaded"
        info "Try: ssh-add ~/.ssh/id_ed25519"
    fi

    # Step 2: Ping
    info "Step 2: Testing network connectivity to $hostname..."
    if ping -c 1 -W "$timeout" "$hostname" &>/dev/null; then
        success "Host $hostname is reachable"
    else
        error "Cannot reach $hostname"
        return 1
    fi

    # Step 3: SSH port
    info "Step 3: Checking if SSH port is open..."
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$hostname/22" 2>/dev/null; then
        success "SSH port (22) is open on $hostname"
    else
        error "SSH port (22) is not accessible"
        return 1
    fi

    # Step 4: SSH connection
    info "Step 4: Testing SSH connection..."
    if ssh -o ConnectTimeout="$timeout" -o BatchMode=yes "$ssh_user@$hostname" "echo 'SSH connection successful'" &>/dev/null; then
        success "SSH connection successful!"
    else
        warn "SSH connection failed"
        info "Trying verbose SSH connection for debugging..."
        ssh -v -o ConnectTimeout="$timeout" "$ssh_user@$hostname" "exit" 2>&1 | tail -20
        return 1
    fi

    # Step 5: System info
    info "Step 5: Gathering system info..."
    ssh "$ssh_user@$hostname" "uname -a && uptime"

    # Step 6: Hostname/user verification
    info "Step 6: Verifying system identity..."
    HOSTNAME=$(ssh -o ConnectTimeout="$timeout" "$ssh_user@$hostname" "hostname" 2>/dev/null || echo "unknown")
    if [ "$HOSTNAME" = "$system" ]; then
        success "Hostname confirmed: $system"
    else
        warn "Hostname is '$HOSTNAME' (expected '$system')"
    fi
    USER_CHECK=$(ssh -o ConnectTimeout="$timeout" "$ssh_user@$hostname" "whoami" 2>/dev/null || echo "unknown")
    if [ "$USER_CHECK" = "$ssh_user" ]; then
        success "User confirmed: $ssh_user"
    else
        warn "User is '$USER_CHECK' (expected '$ssh_user')"
    fi

    # Step 7: Security service checks
    info "Step 7: Checking security services..."
    for service in fail2ban auditd sshd; do
        if ssh "$ssh_user@$hostname" "sudo systemctl is-active $service" &>/dev/null; then
            success "$service is running"
        else
            warn "$service is not running or not accessible"
        fi
    done

    # Step 8: Config file validation
    info "Step 8: Checking config files..."
    if ssh "$ssh_user@$hostname" "sudo test -f /etc/fail2ban/jail.local"; then
        success "fail2ban jail.local exists"
        ssh "$ssh_user@$hostname" "sudo fail2ban-client -t" &>/dev/null && success "fail2ban configuration is valid" || warn "fail2ban configuration has errors"
    else
        warn "fail2ban jail.local not found"
    fi
    if ssh "$ssh_user@$hostname" "sudo test -f /etc/audit/auditd.conf"; then
        success "auditd.conf exists"
    else
        warn "auditd.conf not found"
    fi

    # Step 9: Binary/package presence
    info "Step 9: Checking security binaries..."
    for binary in fail2ban-server fail2ban-client auditd auditctl; do
        if ssh "$ssh_user@$hostname" "which $binary" &>/dev/null; then
            success "$binary is available"
        else
            warn "$binary is not available"
        fi
    done

    # Step 10: Recommendations
    info "Step 10: Recommendations"
    if ssh "$ssh_user@$hostname" "sudo systemctl is-active fail2ban auditd" &>/dev/null; then
        success "All security services appear to be running correctly!"
    else
        warn "Some services are not running. Recommended actions:"
        echo "1. Redeploy the configuration: ./fleet.sh update $system"
        echo "2. Check NixOS configuration syntax: nix build .#nixosConfigurations.$system.config.system.build.toplevel"
        echo "3. Manually rebuild on the target: ssh $ssh_user@$hostname 'sudo nixos-rebuild switch --flake /etc/nixos#$system'"
        echo "4. Check the full system logs: ssh $ssh_user@$hostname 'sudo journalctl -b'"
    fi
}

deploy_system() {
    local system="${1:-}"

    if [ -z "$system" ]; then
        error "Usage: $0 deploy <system>"
    fi

    # Load host variables
    local VARS
    VARS=$(get_host_vars "$system")
    local ip
    local user
    ip=$(echo "$VARS" | jq -r '.network.ip // .network.hostname // ""')
    user=$(echo "$VARS" | jq -r '.network.ssh.user // .user.username // "root"')

    if [ -z "$ip" ]; then
        error "Could not determine IP/hostname for $system from config"
    fi

    warn "DESTRUCTIVE OPERATION - THIS WILL WIPE THE DISK!"
    read -p "Type 'yes' to continue: " confirm
    [[ "$confirm" == "yes" ]] || { info "Cancelled"; exit 0; }
    build_system "$system"
    info "Deploying $system to $ip..."
    nix run github:nix-community/nixos-anywhere -- --flake "$FLAKE_DIR#$system" "$user@$ip" && success "Deployment complete!"
}

update_system() {
    local system="${1:-}"

    if [ -z "$system" ]; then
        error "Usage: $0 update <system>"
    fi

    info "Updating $system using deploy-rs..."
    nix run github:serokell/deploy-rs -- ".#$system" --skip-checks && success "Update complete!"
}

main() {
    if [ $# -eq 0 ]; then 
        usage
        exit 1
    fi

    cmd="$1"
    shift

    case "$cmd" in
        list) 
            list_systems 
            ;;
        build) 
            build_system "${1:-}" 
            ;;
        check) 
            check_system "${1:-}"
            ;;
        deploy) 
            deploy_system "${1:-}"
            ;;
        update) 
            update_system "${1:-}"
            ;;
        *) 
            error "Unknown command: $cmd"
            usage
            ;;
    esac
}

main "$@"
