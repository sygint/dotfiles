#!/usr/bin/env bash

# Smart Development Environment Launcher
# Detects project type and provides appropriate dev tools

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default target directory is current directory
TARGET_DIR="${1:-$(pwd)}"
NIXOS_CONFIG_DIR="$HOME/.config/nixos"

# Make sure target directory exists and is absolute
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}❌ Directory '$TARGET_DIR' not found${NC}"
    exit 1
fi

# Convert to absolute path
TARGET_DIR=$(realpath "$TARGET_DIR")

echo -e "${CYAN}🚀 Starting dev environment for: ${YELLOW}$TARGET_DIR${NC}"
echo

# Function to detect project type
detect_project_type() {
    local dir="$1"
    
    # Check for various project indicators (in order of specificity)
    if [[ -f "$dir/package.json" ]]; then
        # Node.js project - check for specific frameworks
        if [[ -f "$dir/vite.config.ts" ]] || [[ -f "$dir/vite.config.js" ]]; then
            echo "vite"
        elif [[ -f "$dir/next.config.js" ]] || [[ -f "$dir/next.config.ts" ]]; then
            echo "nextjs"
        elif grep -q "react" "$dir/package.json" 2>/dev/null; then
            echo "react"
        else
            echo "nodejs"
        fi
    elif [[ -f "$dir/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$dir/go.mod" ]]; then
        echo "go"
    elif [[ -f "$dir/requirements.txt" ]] || [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/setup.py" ]]; then
        echo "python"
    elif [[ -f "$dir/flake.nix" ]]; then
        echo "nix"
    elif [[ -f "$dir/devenv.nix" ]]; then
        echo "devenv"
    else
        echo "generic"
    fi
}

# Function to get project info
get_project_info() {
    local dir="$1"
    local project_type="$2"
    
    case "$project_type" in
        "vite")
            echo -e "${PURPLE}📦 Vite Project${NC}"
            if [[ -f "$dir/package.json" ]]; then
                local name=$(jq -r '.name // "Unknown"' "$dir/package.json" 2>/dev/null || echo "Unknown")
                echo -e "   Name: ${YELLOW}$name${NC}"
                if grep -q "react" "$dir/package.json" 2>/dev/null; then
                    echo -e "   Framework: ${CYAN}React${NC}"
                elif grep -q "vue" "$dir/package.json" 2>/dev/null; then
                    echo -e "   Framework: ${GREEN}Vue${NC}"
                fi
                if grep -q "typescript" "$dir/package.json" 2>/dev/null; then
                    echo -e "   Language: ${BLUE}TypeScript${NC}"
                fi
            fi
            ;;
        "nodejs")
            echo -e "${YELLOW}📦 Node.js Project${NC}"
            if [[ -f "$dir/package.json" ]]; then
                local name=$(jq -r '.name // "Unknown"' "$dir/package.json" 2>/dev/null || echo "Unknown")
                echo -e "   Name: ${YELLOW}$name${NC}"
            fi
            ;;
        "python")
            echo -e "${GREEN}🐍 Python Project${NC}"
            ;;
        "rust")
            echo -e "${RED}🦀 Rust Project${NC}"
            ;;
        "go")
            echo -e "${CYAN}🐹 Go Project${NC}"
            ;;
        *)
            echo -e "${PURPLE}📁 $project_type Project${NC}"
            ;;
    esac
}

# Function to create nix shell expression
create_shell_nix() {
    local project_type="$1"
    local target_dir="$2"
    
    cat > "/tmp/dev-shell-$$.nix" << EOF
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "dev-env-$(basename "$target_dir")";
  
  buildInputs = with pkgs; [
    # Core utilities
    git
    curl
    wget
    jq
    
EOF

    # Add project-specific tools
    case "$project_type" in
        "vite"|"nextjs"|"nuxt"|"angular"|"vue"|"react"|"nodejs")
            cat >> "/tmp/dev-shell-$$.nix" << 'EOF'
    # Node.js ecosystem
    nodejs_20
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    
    # TypeScript and common tools
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.prettier
    
EOF
            ;;
        "python")
            cat >> "/tmp/dev-shell-$$.nix" << 'EOF'
    # Python ecosystem
    python3
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.setuptools
    
    # Python dev tools
    python3Packages.black
    python3Packages.flake8
    python3Packages.pytest
    
EOF
            ;;
        "rust")
            cat >> "/tmp/dev-shell-$$.nix" << 'EOF'
    # Rust ecosystem
    rustc
    cargo
    rustfmt
    clippy
    
EOF
            ;;
        "go")
            cat >> "/tmp/dev-shell-$$.nix" << 'EOF'
    # Go ecosystem
    go
    golangci-lint
    gopls
    
EOF
            ;;
        *)
            cat >> "/tmp/dev-shell-$$.nix" << 'EOF'
    # Generic development tools
    gnumake
    gcc
    
EOF
            ;;
    esac

    cat >> "/tmp/dev-shell-$$.nix" << EOF
  ];
  
  shellHook = ''
    echo "🔧 Development Environment Active"
    echo "=================================="
    echo "📁 Project: $(basename "$target_dir")"
    echo "📍 Location: $target_dir"
    echo "🏷️  Type: $project_type"
    echo
    
    # Change to project directory
    cd "$target_dir"
    
    # Show available commands based on project type
EOF

    case "$project_type" in
        "vite"|"nextjs"|"nuxt"|"angular"|"vue"|"react"|"nodejs")
            cat >> "/tmp/dev-shell-$$.nix" << 'EOF'
    echo "📦 Node.js Commands:"
    echo "   npm install    - Install dependencies"
    echo "   npm run dev    - Start development server"
    echo "   npm run build  - Build for production"
    echo "   npm run lint   - Run linting"
    echo
    
    # Auto install dependencies if needed
    if [[ -f package.json ]] && [[ ! -d node_modules ]]; then
        echo "🔄 Installing dependencies..."
        npm install
        echo "✅ Dependencies installed!"
        echo
    fi
EOF
            ;;
    esac

    cat >> "/tmp/dev-shell-$$.nix" << 'EOF'
    echo "💡 Type 'exit' to leave the development environment"
    echo
  '';
}
EOF
}

# Main execution
PROJECT_TYPE=$(detect_project_type "$TARGET_DIR")

echo -e "${BLUE}🔍 Project Detection:${NC}"
get_project_info "$TARGET_DIR" "$PROJECT_TYPE"
echo

echo -e "${CYAN}🛠️  Setting up development environment...${NC}"

# Create the shell.nix file
create_shell_nix "$PROJECT_TYPE" "$TARGET_DIR"

echo -e "${GREEN}✅ Environment ready!${NC}"
echo

# Launch the nix shell
echo -e "${YELLOW}🚀 Launching development shell...${NC}"
echo -e "${BLUE}   (This may take a moment to download packages)${NC}"
echo

# Change to nixos config directory to ensure nix commands work properly
cd "$NIXOS_CONFIG_DIR"

# Launch nix shell with the generated config
nix-shell "/tmp/dev-shell-$$.nix" --command "bash --init-file <(echo 'cd \"$TARGET_DIR\"; exec bash')"

# Cleanup
rm -f "/tmp/dev-shell-$$.nix"

echo -e "${GREEN}👋 Development session ended${NC}"