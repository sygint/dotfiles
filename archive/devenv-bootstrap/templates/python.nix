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
    venv.enable = true;
    # Uncomment if using poetry:
    # poetry.enable = true;
  };

  scripts.dev.exec = "python __ENTRYPOINT__";
  scripts.test.exec = "pytest";
  scripts.lint.exec = "black . && flake8";

  enterShell = ''
    echo "🐍 Python Development Environment"
    echo "================================="
    echo "📁 Project: $(basename $(pwd))"
    echo "🐍 Python: $(python --version)"
    echo ""
    echo "🚀 Available scripts:"
    echo "  dev   - Run __ENTRYPOINT__"
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
