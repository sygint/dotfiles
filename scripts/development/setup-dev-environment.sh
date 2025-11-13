#!/usr/bin/env bash

set -euo pipefail



# Colors
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

main() {
    print_header
    check_git
    set_repo_root
    print_namespace_strategy
    check_nh
    install_git_hooks
    configure_git
    verify_nix
    test_configuration
    check_dev_tools
    print_dev_tools_summary
    print_next_steps
}

print_header() {
    echo -e "${BLUE}🔧 Setting up NixOS configuration repository...${NC}"
}

check_git() {
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC} Git is not installed. Please install git before running this script."
        exit 1
    fi
}

set_repo_root() {
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(pwd)")"
    cd "$REPO_ROOT"
    echo -e "${BLUE}Repo root:${NC} $REPO_ROOT"
}

print_namespace_strategy() {
    echo -e "\n${BLUE}ℹ️ Namespace Strategy:${NC}"
    echo -e "• Custom modules should use the 'modules.programs.<name>' namespace for options and config."
    echo -e "• Upstream Home Manager modules use the standard 'programs.<name>' namespace for configuration."
    echo -e "• See README.md and CONTRIBUTING.md for details."
}

check_nh() {
    echo -e "\n${BLUE}🔍 Checking for nh (Nix helper)...${NC}"
    if command -v nh >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} nh is available"
    else
        echo -e "${YELLOW}⚠${NC} nh is not installed (optional but recommended)"
        echo "  Purpose: Fast NixOS and Home Manager switching"
        echo "  Install with: nix profile install nixpkgs#nh"
    fi
}

install_git_hooks() {
    echo -e "\n${BLUE}📦 Installing Git hooks...${NC}"
    HOOKS_DIR=".git/hooks"
    if [ ! -d "$HOOKS_DIR" ]; then
        echo -e "${YELLOW}⚠ Not in a git repository or hooks directory missing${NC}"
        exit 2
    fi
    PRE_COMMIT="$HOOKS_DIR/pre-commit"
    if [ -L "$PRE_COMMIT" ] && [ ! -e "$PRE_COMMIT" ]; then
        echo -e "${YELLOW}⚠ Removing dangling symlink at $PRE_COMMIT${NC}"
        rm "$PRE_COMMIT"
    fi
    if [ -f "scripts/git-hooks/pre-commit" ]; then
        # create an idempotent symlink in .git/hooks to the canonical script
        if [ -L "$PRE_COMMIT" ]; then
            # if symlink exists and points to the right target, do nothing
            target=$(readlink -f "$PRE_COMMIT" || true)
            want=$(readlink -f "scripts/git-hooks/pre-commit")
            if [ "$target" = "$want" ]; then
                echo -e "${GREEN}✓${NC} Pre-commit hook symlink already in place"
            else
                rm "$PRE_COMMIT"
                ln -s "$want" "$PRE_COMMIT"
                chmod +x "scripts/git-hooks/pre-commit"
                echo -e "${GREEN}✓${NC} Updated pre-commit hook symlink"
            fi
        else
            # remove existing file if it's not the desired symlink
            if [ -e "$PRE_COMMIT" ]; then
                rm -f "$PRE_COMMIT"
            fi
            ln -s "$(readlink -f scripts/git-hooks/pre-commit)" "$PRE_COMMIT"
            chmod +x "scripts/git-hooks/pre-commit"
            echo -e "${GREEN}✓${NC} Installed pre-commit hook (symlink)"
        fi
    else
        echo -e "${YELLOW}⚠ Pre-commit hook script not found at scripts/git-hooks/pre-commit${NC}"
    fi
    PRE_PUSH="$HOOKS_DIR/pre-push"
    if [ -L "$PRE_PUSH" ] && [ ! -e "$PRE_PUSH" ]; then
        echo -e "${YELLOW}⚠ Removing dangling symlink at $PRE_PUSH${NC}"
        rm "$PRE_PUSH"
    fi
    if [ -f "scripts/git-hooks/pre-push" ]; then
        if [ -L "$PRE_PUSH" ]; then
            target=$(readlink -f "$PRE_PUSH" || true)
            want=$(readlink -f "scripts/git-hooks/pre-push")
            if [ "$target" = "$want" ]; then
                echo -e "${GREEN}✓${NC} Pre-push hook symlink already in place"
            else
                rm "$PRE_PUSH"
                ln -s "$want" "$PRE_PUSH"
                chmod +x "scripts/git-hooks/pre-push"
                echo -e "${GREEN}✓${NC} Updated pre-push hook symlink"
            fi
        else
            if [ -e "$PRE_PUSH" ]; then
                rm -f "$PRE_PUSH"
            fi
            ln -s "$(readlink -f scripts/git-hooks/pre-push)" "$PRE_PUSH"
            chmod +x "scripts/git-hooks/pre-push"
            echo -e "${GREEN}✓${NC} Installed pre-push hook (symlink)"
        fi
    fi
}

configure_git() {
    echo -e "\n${BLUE}⚙️ Configuring git settings...${NC}"
    git config core.hooksPath .git/hooks
    git config merge.ours.driver true
    echo -e "${GREEN}✓${NC} Git configuration updated"
}

verify_nix() {
    echo -e "\n${BLUE}🔍 Verifying Nix installation...${NC}"
    if command -v nix >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Nix is installed ($(nix --version))"
        NIX_VERSION=$(nix --version | awk '{print $3}')
        if [ "$(printf '%s\n' "$NIX_VERSION" "2.4" | sort -V | head -n1)" = "$NIX_VERSION" ] && [ "$NIX_VERSION" != "2.4" ]; then
            echo -e "${YELLOW}⚠${NC} Your Nix version ($NIX_VERSION) is quite old. Consider upgrading."
        fi
        if nix flake --help >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Nix flakes are available"
        else
            echo -e "${YELLOW}⚠ Nix flakes may not be enabled${NC}"
            echo "  Add 'experimental-features = nix-command flakes' to your nix.conf"
        fi
    else
        echo -e "${YELLOW}⚠ Nix is not installed${NC}"
        echo "  Install Nix from: https://nixos.org/download.html"
        exit 3
    fi
}

test_configuration() {
    echo -e "\n${BLUE}🧪 Testing configuration...${NC}"
    if nix flake check --no-build 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Configuration syntax is valid"
    else
        echo -e "${YELLOW}⚠ Configuration has syntax errors${NC}"
        echo "  Run 'nix flake check' for details"
    fi
}

check_dev_tools() {
    echo -e "\n${BLUE}🛠️ Development tools...${NC}"
    DEV_TOOLS=("jq" "nixpkgs-fmt" "alejandra" "statix" "deadnix" "nix-tree" "nvd")
    MISSING=()
    for tool in "${DEV_TOOLS[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $tool is available"
        else
            echo -e "${YELLOW}⚠${NC} $tool is not installed (optional but useful)"
            case $tool in
                "jq") echo "  Purpose: JSON parsing for hooks and tooling" ;;
                "nixpkgs-fmt"|"alejandra") echo "  Purpose: Nix code formatting" ;;
                "statix") echo "  Purpose: Nix linting and best practices" ;;
                "deadnix") echo "  Purpose: Find unused Nix code" ;;
                "nix-tree") echo "  Purpose: Explore dependency tree" ;;
                "nvd") echo "  Purpose: Compare system generations" ;;
            esac
            echo "  Install with: nix profile install nixpkgs#$tool"
            MISSING+=("$tool")
        fi
    done

    if [ ${#MISSING[@]} -ne 0 ]; then
        echo -e "\n${YELLOW}Missing dev tools:${NC} ${MISSING[*]}"
    fi
}

print_dev_tools_summary() {
    echo -e "\n${GREEN}🎉 Setup complete!${NC}"
    echo -e "\n${BLUE}Dev Tools Summary:${NC}"
    DEV_TOOLS=("nixpkgs-fmt" "alejandra" "statix" "deadnix" "nix-tree" "nvd")
    for tool in "${DEV_TOOLS[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $tool"
        else
            echo -e "${YELLOW}⚠${NC} $tool (missing)"
        fi
    done
}

print_next_steps() {
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "• The pre-commit hook will now validate your commits"
    echo "• Run 'nix flake check' to validate the configuration"
    echo "• Run 'nh os switch' to apply changes (NixOS only)"
    echo "• Use 'git commit --no-verify' to bypass hooks if needed"
    echo
    echo -e "${BLUE}Contributing:${NC}"
    echo "• All commits will be automatically validated"
    echo "• Security configurations are checked for common issues"
    echo "• Large files and potential secrets are flagged"
    echo
    echo -e "${BLUE}Development commands:${NC}"
    echo "• 'nix flake check' - Validate configuration"
    echo "• 'nix build .#nixosConfigurations.nixos.config.system.build.toplevel' - Test build"
    echo "• './scripts/security/security-scan.sh' - Run security audit"
}

main "$@"
