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
    
    # NixOS-specific tools
    nixos-rebuild
    nixfmt
    nix-tree
    
    # Deployment tools
    # deploy-rs  # Uncomment when you set up deploy-rs
  ];
  
  shellHook = ''
    echo "🔧 NixOS Dotfiles Development Environment"
    echo "=========================================="
    echo
    echo "Security Tools:"
    echo "  • git-secrets: $(command -v git-secrets >/dev/null && echo 'available' || echo 'not found')"
    echo "  • trufflehog: $(trufflehog --version 2>&1 | head -1)"
    echo
    echo "Available Commands:"
    echo "  • ./scripts/fleet.sh - Fleet management"
    echo "  • ./scripts/setup-security-tools.sh - Configure git hooks"
    echo "  • nixos-rebuild - Build/test configurations"
    echo
    
    # Configure git-secrets if not already done
    if [ -d .git ] && ! git config --local --get secrets.providers >/dev/null 2>&1; then
      echo "⚠️  git-secrets not configured. Run ./scripts/setup-security-tools.sh"
    fi
  '';
}
