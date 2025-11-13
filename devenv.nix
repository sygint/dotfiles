{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "nixos-dotfiles-dev";
  
  buildInputs = with pkgs; [
    # Core development tools
    git
    git-secrets
    trufflehog
    
    # Utilities for scripts
    jq
    gnugrep
    gawk
    gnumake
    bashInteractive
    openssh
    deno  # Deno for Kanboard API scripts
    
    # NixOS-specific tools
    nixos-rebuild
    nixfmt
    nix-tree
    
    # Deployment and bootstrap tools
    deploy-rs
    nixos-anywhere
    sops
    ssh-to-age
    yq-go  # YAML processor
  ];
  
  shellHook = ''
    echo "🔧 NixOS Dotfiles Development Environment"
    echo "=========================================="
    echo
    echo "Security Tools:"
    echo "  • git-secrets: $(command -v git-secrets >/dev/null && echo 'available' || echo 'not found')"
    echo "  • trufflehog: $(trufflehog --version 2>&1 | head -1)"
    echo
    
    # Auto-configure git-secrets patterns if not already done
    if [ -d .git ] && ! git config --local --get secrets.providers >/dev/null 2>&1; then
      echo "🔐 Configuring git-secrets patterns..."
      
      # Register AWS provider patterns
      git-secrets --register-aws 2>/dev/null || true
      
      # Add custom patterns for common secrets
      git-secrets --add '[Pp]assword\s*[=:]\s*["\047][^\"\047]{8,}["\047]' 2>/dev/null || true
      git-secrets --add '[Aa]pi[-_]?[Kk]ey\s*[=:]\s*["\047][^\"\047]{16,}["\047]' 2>/dev/null || true
      git-secrets --add '[Ss]ecret\s*[=:]\s*["\047][^\"\047]{8,}["\047]' 2>/dev/null || true
      git-secrets --add '[Tt]oken\s*[=:]\s*["\047][^\"\047]{16,}["\047]' 2>/dev/null || true
      git-secrets --add 'ssh-rsa\s+AAAA[0-9A-Za-z+/]{100,}' 2>/dev/null || true
      git-secrets --add 'ssh-ed25519\s+AAAA[0-9A-Za-z+/]{68}' 2>/dev/null || true
      
      # Add patterns to allow known safe strings
      git-secrets --add --allowed 'example.*password' 2>/dev/null || true
      git-secrets --add --allowed 'placeholder.*token' 2>/dev/null || true
      git-secrets --add --allowed 'nixos@genesis' 2>/dev/null || true
      
      echo "✓ git-secrets configured"
    fi
    
    echo
    echo "Available Commands:"
    echo "  • ./scripts/deployment/fleet.sh - Fleet management"
    echo "  • nixos-rebuild - Build/test configurations"
    echo
  '';
}
