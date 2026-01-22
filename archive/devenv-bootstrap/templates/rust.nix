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
