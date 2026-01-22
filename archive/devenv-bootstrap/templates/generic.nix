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
