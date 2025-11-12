#!/usr/bin/env bash

# Bootstrap a devenv.nix file for any project with smart detection
# Supports: Node.js/TypeScript, Python, Rust, Go, and generic projects

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0")"
VERSION="2.0.0"

# Flags
FORCE_OVERWRITE=false
DRY_RUN=false
QUIET=false
SPECIFIED_TYPE=""
TARGET_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [DIRECTORY]

Bootstrap a devenv.nix file for any project with smart detection.

OPTIONS:
    -h, --help          Show this help message
    -f, --force         Overwrite existing devenv.nix without prompting
    -d, --dry-run       Show what would be generated without creating files
    -q, --quiet         Minimal output (for automation/CI)
    -t, --type TYPE     Force project type (nodejs, python, rust, go, generic)
    -v, --version       Show version information

DIRECTORY:
    Target directory (default: current directory)

EXAMPLES:
    $SCRIPT_NAME                    # Bootstrap current directory
    $SCRIPT_NAME ~/projects/myapp   # Bootstrap specific directory
    $SCRIPT_NAME --type python .    # Force Python template
    $SCRIPT_NAME --dry-run          # Preview without creating files

SUPPORTED PROJECT TYPES:
    • Node.js/TypeScript (vite, nextjs, react, generic nodejs)
    • Python (with poetry/pip support)
    • Rust (with cargo integration)
    • Go (with go modules)
    • Generic (shell scripts, C/C++, etc.)

For more information: https://devenv.sh
EOF
    exit 0
}

# Version information
version() {
    echo "$SCRIPT_NAME version $VERSION"
    exit 0
}

# Logging functions
log_info() {
    [[ "$QUIET" == true ]] && return
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    [[ "$QUIET" == true ]] && return
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -v|--version)
                version
                ;;
            -f|--force)
                FORCE_OVERWRITE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -t|--type)
                SPECIFIED_TYPE="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                TARGET_DIR="$1"
                shift
                ;;
        esac
    done
}

# Initialize
TARGET_DIR="${TARGET_DIR:-$(pwd)}"
parse_args "$@"

# Validate target directory
if [[ ! -d "$TARGET_DIR" ]]; then
    log_error "Directory '$TARGET_DIR' not found"
    exit 1
fi

TARGET_DIR=$(realpath "$TARGET_DIR")

[[ "$DRY_RUN" == true ]] && log_info "DRY RUN MODE - No files will be created"
log_info "Bootstrapping devenv for: $TARGET_DIR"

# Function to detect project type
detect_project_type() {
    local dir="$1"
    
    # Use specified type if provided
    if [[ -n "$SPECIFIED_TYPE" ]]; then
        case "$SPECIFIED_TYPE" in
            nodejs|python|rust|go|generic)
                echo "$SPECIFIED_TYPE"
                return
                ;;
            *)
                log_error "Invalid project type: $SPECIFIED_TYPE"
                log_error "Valid types: nodejs, python, rust, go, generic"
                exit 1
                ;;
        esac
    fi
    
    # Auto-detect project type
    if [[ -f "$dir/package.json" ]]; then
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
    elif [[ -f "$dir/requirements.txt" ]] || [[ -f "$dir/pyproject.toml" ]]; then
        echo "python"
    else
        echo "generic"
    fi
}

# Detect Python entry point
detect_python_entrypoint() {
    local dir="$1"
    
    # Check for common entry points
    if [[ -f "$dir/main.py" ]]; then
        echo "main.py"
    elif [[ -f "$dir/app.py" ]]; then
        echo "app.py"
    elif [[ -f "$dir/run.py" ]]; then
        echo "run.py"
    elif [[ -f "$dir/__main__.py" ]]; then
        echo "__main__.py"
    else
        echo "main.py"  # Default fallback
    fi
}

# Function to detect Node.js version from project files
detect_node_version() {
    local dir="$1"
    local node_version="20"
    local node_package="nodejs_20"
    local version_source="default"
    
    # Check volta section in package.json first
    if [[ -f "$dir/package.json" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e '.volta.node' "$dir/package.json" >/dev/null 2>&1; then
            local volta_version
            volta_version=$(jq -r '.volta.node' "$dir/package.json" 2>/dev/null)
            if [[ "$volta_version" =~ ^([0-9]+) ]]; then
                node_version="${BASH_REMATCH[1]}"
                version_source="package.json volta.node"
            fi
        fi
    fi
    
    # Check .nvmrc file if no volta config
    if [[ "$version_source" == "default" && -f "$dir/.nvmrc" ]]; then
        local nvmrc_version
        nvmrc_version=$(cat "$dir/.nvmrc" 2>/dev/null | tr -d 'v' | cut -d. -f1)
        if [[ "$nvmrc_version" =~ ^[0-9]+$ ]]; then
            node_version="$nvmrc_version"
            version_source=".nvmrc"
        fi
    fi
    
    # Map to nixpkgs package name
    case "$node_version" in
        16) node_package="nodejs_16" ;;
        18) node_package="nodejs_18" ;;
        20) node_package="nodejs_20" ;;
        22) node_package="nodejs_22" ;;
        *) node_package="nodejs_20" ;; # Default fallback
    esac
    
    echo "$node_version:$node_package:$version_source"
}

PROJECT_TYPE=$(detect_project_type "$TARGET_DIR")
log_info "Detected project type: $PROJECT_TYPE"

# Check if files already exist
check_existing_files() {
    local has_devenv=false
    local has_envrc=false
    
    [[ -f "$TARGET_DIR/devenv.nix" ]] && has_devenv=true
    [[ -f "$TARGET_DIR/.envrc" ]] && has_envrc=true
    
    if [[ "$has_devenv" == true ]] || [[ "$has_envrc" == true ]]; then
        if [[ "$FORCE_OVERWRITE" == false && "$DRY_RUN" == false ]]; then
            log_warn "The following files already exist:"
            [[ "$has_devenv" == true ]] && echo "  • devenv.nix"
            [[ "$has_envrc" == true ]] && echo "  • .envrc"
            echo ""
            read -p "Overwrite? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Aborted. Use --force to skip this prompt."
                exit 0
            fi
        elif [[ "$FORCE_OVERWRITE" == true ]]; then
            log_warn "Overwriting existing files (--force)"
        fi
    fi
}

check_existing_files

# Template generation functions
generate_nodejs_template() {
    local node_version="$1"
    local node_package="$2"
    local version_source="$3"
    
    cat << EOF
{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = with pkgs; [ 
    git
    curl
    jq
    nodePackages.pnpm
  ];

  # https://devenv.sh/languages/
  languages.javascript = {
    enable = true;
    package = pkgs.$node_package;
    pnpm = {
      enable = true;
      install.enable = true;  # Auto pnpm install on shell enter
    };
  };

  languages.typescript.enable = true;

  # https://devenv.sh/scripts/
  scripts.dev.exec = "pnpm run dev";
  scripts.build.exec = "pnpm run build";
  scripts.lint.exec = "pnpm run lint";
  scripts.test.exec = "pnpm test";

  enterShell = ''
    echo "🔧 Node.js Development Environment"
    echo "=================================="
    echo "📁 Project: \\\$(basename \\\$(pwd))"
    echo "📦 Node.js: \\\$(node --version) (nixpkgs: $node_package)"
    echo "📦 pnpm: \\\$(pnpm --version)"
    echo ""
    
    # Show version detection info
    echo "📍 Version source: $version_source"
    if [[ -f package.json ]] && command -v jq >/dev/null && jq -e '.volta.node' package.json >/dev/null 2>&1; then
      echo "   └─ package.json volta.node = \\\$(jq -r '.volta.node' package.json)"
    elif [[ -f .nvmrc ]]; then
      echo "   └─ .nvmrc = \\\$(cat .nvmrc)"
    else
      echo "   └─ using default Node.js $node_version"
    fi
    echo ""
    
    echo "🚀 Available scripts:"
    echo "  dev   - Start development server (pnpm run dev)"
    echo "  build - Build for production (pnpm run build)"
    echo "  lint  - Run linting (pnpm run lint)"
    echo "  test  - Run tests (pnpm test)"
    echo ""
    echo "💡 Using pnpm as package manager"
    echo ""
  '';

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/pre-commit-hooks/
  # Uncomment to enable additional pre-commit hooks:
  # git-hooks.hooks.prettier.enable = true;
  # git-hooks.hooks.eslint.enable = true;
  # git-hooks.hooks.typos.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
EOF
}

generate_python_template() {
    local entrypoint="$1"
    
    cat << EOF
{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  packages = with pkgs; [ 
    git
    curl
    jq
  ];

  languages.python = {
    enable = true;
    package = pkgs.python3;
    poetry.enable = true;
    pip.install.enable = true;
  };

  scripts.dev.exec = "python $entrypoint";
  scripts.test.exec = "pytest";
  scripts.lint.exec = "black . && flake8";

  enterShell = ''
    echo "🐍 Python Development Environment"
    echo "================================="
    echo "📁 Project: \\\$(basename \\\$(pwd))"
    echo "🐍 Python: \\\$(python --version)"
    echo ""
    echo "🚀 Available scripts:"
    echo "  dev   - Run $entrypoint"
    echo "  test  - Run pytest"
    echo "  lint  - Run black and flake8"
    echo ""
  '';

  # https://devenv.sh/pre-commit-hooks/
  git-hooks.hooks.black.enable = true;
  git-hooks.hooks.flake8.enable = true;
  # Uncomment to enable additional pre-commit hooks:
  # git-hooks.hooks.isort.enable = true;
  # git-hooks.hooks.mypy.enable = true;
  # git-hooks.hooks.ruff.enable = true;
}
EOF
}

generate_rust_template() {
    cat << 'EOF'
{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  packages = with pkgs; [ 
    git
    curl
    jq
  ];

  languages.rust = {
    enable = true;
    channel = "stable";
  };

  scripts.dev.exec = "cargo run";
  scripts.build.exec = "cargo build";
  scripts.test.exec = "cargo test";
  scripts.fmt.exec = "cargo fmt";

  enterShell = ''
    echo "🦀 Rust Development Environment"
    echo "==============================="
    echo "📁 Project: $(basename $(pwd))"
    echo "🦀 Rust: $(rustc --version)"
    echo ""
    echo "🚀 Available scripts:"
    echo "  dev   - Run with cargo run"
    echo "  build - Build with cargo build"
    echo "  test  - Run cargo test"
    echo "  fmt   - Format with cargo fmt"
    echo ""
  '';

  # https://devenv.sh/pre-commit-hooks/
  git-hooks.hooks.rustfmt.enable = true;
  git-hooks.hooks.clippy.enable = true;
  # Uncomment to enable additional pre-commit hooks:
  # git-hooks.hooks.cargo-check.enable = true;
}
EOF
}

generate_go_template() {
    cat << 'EOF'
{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  packages = with pkgs; [ 
    git
    curl
    jq
  ];

  languages.go = {
    enable = true;
    package = pkgs.go;
  };

  scripts.dev.exec = "go run .";
  scripts.build.exec = "go build";
  scripts.test.exec = "go test ./...";
  scripts.fmt.exec = "gofmt -w .";

  enterShell = ''
    echo "🐹 Go Development Environment"
    echo "============================="
    echo "📁 Project: $(basename $(pwd))"
    echo "🐹 Go: $(go version)"
    echo ""
    echo "🚀 Available scripts:"
    echo "  dev   - Run with go run"
    echo "  build - Build binary"
    echo "  test  - Run all tests"
    echo "  fmt   - Format code"
    echo ""
  '';

  # https://devenv.sh/pre-commit-hooks/
  # Uncomment to enable pre-commit hooks:
  # git-hooks.hooks.gofmt.enable = true;
  # git-hooks.hooks.golangci-lint.enable = true;
  # git-hooks.hooks.govet.enable = true;
}
EOF
}

generate_generic_template() {
    cat << 'EOF'
{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  packages = with pkgs; [ 
    git
    curl
    jq
    gnumake
    gcc
  ];

  enterShell = ''
    echo "🔧 Generic Development Environment"
    echo "=================================="
    echo "📁 Project: $(basename $(pwd))"
    echo ""
  '';

  # https://devenv.sh/pre-commit-hooks/
  git-hooks.hooks.shellcheck.enable = true;
  # Uncomment to enable additional pre-commit hooks:
  # git-hooks.hooks.shfmt.enable = true;
}
EOF
}

# Generate devenv.nix based on project type
cd "$TARGET_DIR"

generate_devenv_nix() {
    case "$PROJECT_TYPE" in
        "vite"|"nextjs"|"react"|"nodejs")
            IFS=':' read -r node_version node_package version_source <<< "$(detect_node_version "$TARGET_DIR")"
            log_info "Using Node.js $node_version ($node_package) from $version_source"
            generate_nodejs_template "$node_version" "$node_package" "$version_source"
            ;;
        
        "python")
            local entrypoint
            entrypoint=$(detect_python_entrypoint "$TARGET_DIR")
            log_info "Using Python entry point: $entrypoint"
            generate_python_template "$entrypoint"
            ;;
        
        "rust")
            generate_rust_template
            ;;
        
        "go")
            generate_go_template
            ;;
        
        *)
            generate_generic_template
            ;;
    esac
}

generate_envrc() {
    cat << 'EOF'
# Use devenv - requires nix-direnv for proper integration
# For now, using nix-shell as fallback
if command -v devenv >/dev/null 2>&1; then
  eval "$(devenv print-dev-env)"
else
  echo "⚠️  devenv not found, falling back to nix-shell"
  use nix
fi
EOF
}

update_gitignore() {
    if [[ ! -f .gitignore ]]; then
        touch .gitignore
    fi
    
    # Add devenv entries to gitignore if not already present
    if ! grep -q "^\.devenv" .gitignore; then
        echo "" >> .gitignore
        echo "# devenv" >> .gitignore
        echo ".devenv" >> .gitignore
    fi
}

# Main execution
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "=============== devenv.nix (preview) ==============="
    generate_devenv_nix
    echo ""
    echo "=============== .envrc (preview) ==============="
    generate_envrc
    echo ""
    log_info "Dry run complete. No files were created."
    exit 0
fi

# Create files
log_info "Creating devenv.nix..."
generate_devenv_nix > devenv.nix

log_info "Creating .envrc..."
generate_envrc > .envrc

log_info "Updating .gitignore..."
update_gitignore

echo ""
log_success "devenv.nix created successfully!"
echo ""
log_info "Next steps:"
echo "  1. Run: direnv allow"
echo "  2. Next time you cd into this directory, the environment will auto-load!"
echo "  3. Edit devenv.nix to customize your environment"
echo ""
log_info "Auto-loading will happen when you next cd into: $TARGET_DIR"
