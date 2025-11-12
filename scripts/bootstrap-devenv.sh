#!/usr/bin/env bash

# Bootstrap a devenv.nix file for any project with smart Node.js version detection
# Usage: bootstrap-devenv [directory]

set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR=$(realpath "$TARGET_DIR")

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "❌ Directory '$TARGET_DIR' not found"
    exit 1
fi

echo "🚀 Bootstrapping devenv for: $TARGET_DIR"

# Function to detect project type
detect_project_type() {
    local dir="$1"
    
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

# Function to detect Node.js version from project files
detect_node_version() {
    local dir="$1"
    local node_version="20"
    local node_package="nodejs_20"
    local version_source="default"
    
    # Check volta section in package.json first
    if [[ -f "$dir/package.json" ]] && command -v jq >/dev/null && jq -e '.volta.node' "$dir/package.json" >/dev/null 2>&1; then
        local volta_version=$(jq -r '.volta.node' "$dir/package.json" 2>/dev/null)
        if [[ "$volta_version" =~ ^([0-9]+) ]]; then
            node_version="${BASH_REMATCH[1]}"
            version_source="package.json volta.node"
        fi
    # Check .nvmrc file
    elif [[ -f "$dir/.nvmrc" ]]; then
        local nvmrc_version=$(cat "$dir/.nvmrc" 2>/dev/null | tr -d 'v' | cut -d. -f1)
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
echo "📦 Detected project type: $PROJECT_TYPE"

cd "$TARGET_DIR"

case "$PROJECT_TYPE" in
    "vite"|"nextjs"|"react"|"nodejs")
        # Get Node.js version info
        IFS=':' read -r node_version node_package version_source <<< "$(detect_node_version "$TARGET_DIR")"
        
        echo "📝 Creating Node.js/React devenv.nix..."
        echo "🔍 Using Node.js $node_version ($node_package) from $version_source"
        
        cat > devenv.nix << EOF
{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = with pkgs; [ 
    git
    nodePackages.pnpm
    curl
    jq
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
    echo "📁 Project: \$(basename \$(pwd))"
    echo "📦 Node.js: \$(node --version) (nixpkgs: $node_package)"
    echo "📦 pnpm: \$(pnpm --version)"
    echo ""
    
    # Show version detection info
    echo "📍 Version source: $version_source"
    if [[ -f package.json ]] && command -v jq >/dev/null && jq -e '.volta.node' package.json >/dev/null 2>&1; then
      echo "   └─ package.json volta.node = \$(jq -r '.volta.node' package.json)"
    elif [[ -f .nvmrc ]]; then
      echo "   └─ .nvmrc = \$(cat .nvmrc)"
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
        ;;

    "python")
        echo "📝 Creating Python devenv.nix..."
        cat > devenv.nix << 'EOF'
{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  packages = [ 
    pkgs.git
    nodePackages.pnpm
    pkgs.curl
    pkgs.jq
  ];

  languages.python = {
    enable = true;
    package = pkgs.python3;
    poetry.enable = true;
    pip.install.enable = true;
  };

  scripts.dev.exec = "python main.py";
  scripts.test.exec = "pytest";
  scripts.lint.exec = "black . && flake8";

  enterShell = ''
    echo "🐍 Python Development Environment"
    echo "================================="
    echo "📁 Project: $(basename $(pwd))"
    echo "🐍 Python: $(python --version)"
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
        ;;

    "rust")
        echo "📝 Creating Rust devenv.nix..."
        cat > devenv.nix << 'EOF'
{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  packages = [ 
    pkgs.git
    nodePackages.pnpm
    pkgs.curl
    pkgs.jq
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
  '';

  # https://devenv.sh/pre-commit-hooks/
  git-hooks.hooks.rustfmt.enable = true;
  git-hooks.hooks.clippy.enable = true;
  # Uncomment to enable additional pre-commit hooks:
  # git-hooks.hooks.cargo-check.enable = true;
}
EOF
        ;;

    *)
        echo "📝 Creating generic devenv.nix..."
        cat > devenv.nix << 'EOF'
{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  packages = [ 
    pkgs.git
    nodePackages.pnpm
    pkgs.curl
    pkgs.jq
    pkgs.gnumake
    pkgs.gcc
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
        ;;
esac

# Create .envrc for direnv
echo "📝 Creating .envrc..."
cat > .envrc << 'EOF'
# Use devenv - requires nix-direnv for proper integration
# For now, using nix-shell as fallback
if command -v devenv >/dev/null 2>&1; then
  eval "$(devenv print-dev-env)"
else
  echo "⚠️  devenv not found, falling back to nix-shell"
  use nix
fi
EOF

# Add to .gitignore
echo "📝 Updating .gitignore..."
if [[ ! -f .gitignore ]]; then
    touch .gitignore
fi

# Add devenv entries to gitignore if not already present
if ! grep -q "^\.devenv" .gitignore; then
    echo "" >> .gitignore
    echo "# devenv" >> .gitignore
    echo ".devenv" >> .gitignore
fi

echo ""
echo "✅ devenv.nix created successfully!"
echo ""
echo "🔧 Next steps:"
echo "1. Run: direnv allow"
echo "2. Next time you cd into this directory, the environment will auto-load!"
echo "3. Edit devenv.nix to customize your environment"
echo ""
echo "💡 Auto-loading will happen when you next cd into: $TARGET_DIR"