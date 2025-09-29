{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "nixos-dotfiles-dev";
  buildInputs = [
    pkgs.git
    pkgs.jq
    pkgs.gnugrep
    pkgs.gawk
    pkgs.gnumake
    pkgs.bashInteractive
    pkgs.openssh
    pkgs.gitAndTools.git-secrets
    pkgs.python3
    pkgs.python3Packages.pip
  ];
  shellHook = ''
    echo "\033[1;32m[devenv] Development environment loaded.\033[0m"
    echo "- git, git-secrets, jq, trufflehog (via venv), and more are available."
    echo "- Use 'devenv shell' or 'nix develop' to enter this environment."
    if [ ! -d .venv ]; then
      echo "[devenv] Creating Python venv in .venv..."
      python3 -m venv .venv
    fi
    # shellcheck disable=SC1091
    source .venv/bin/activate
    if ! .venv/bin/trufflehog --version >/dev/null 2>&1; then
      echo "[devenv] Installing trufflehog in .venv..."
      pip install --quiet trufflehog
    fi
    hash -r
    echo "[devenv] Python venv activated. trufflehog is available."
  '';
}
