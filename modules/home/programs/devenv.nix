{
  config,
  lib,
  options,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.devenv;
in {
  options.settings.programs.devenv.enable = mkEnableOption "devenv development environment manager (user-level)";

  config = mkIf cfg.enable {
    # Install devenv for the user
    home.packages = [
      inputs.devenv.packages."${pkgs.system}".devenv
    ];

    # Configure direnv for devenv integration
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global = {
          hide_env_diff = true;
          warn_timeout = "30s";
        };
      };
    };

    # Add shell integration for devenv
    programs.zsh.initExtra = lib.mkAfter ''
      # devenv shell integration
      if command -v devenv >/dev/null 2>&1; then
        eval "$(devenv shell --print-completion zsh)"
      fi
    '';

    # Optional: Create a simple devenv template directory
    home.file.".config/devenv/templates/default/.envrc".text = ''
      use devenv
    '';

    home.file.".config/devenv/templates/default/devenv.nix".text = ''
      { pkgs, ... }:

      {
        # https://devenv.sh/basics/
        env.GREET = "devenv";

        # https://devenv.sh/packages/
        packages = [ pkgs.git ];

        # https://devenv.sh/scripts/
        scripts.hello.exec = "echo hello from $GREET";

        enterShell = '''
          hello
          git --version
        ''';

        # https://devenv.sh/tests/
        enterTest = '''
          echo "Running tests"
          git --version | grep --color=auto "${pkgs.git.version}"
        ''';

        # https://devenv.sh/services/
        # services.postgres.enable = true;

        # https://devenv.sh/languages/
        # languages.nix.enable = true;

        # https://devenv.sh/pre-commit-hooks/
        # pre-commit.hooks.shellcheck.enable = true;

        # https://devenv.sh/processes/
        # processes.ping.exec = "ping example.com";

        # See full reference at https://devenv.sh/reference/options/
      }
    '';

    home.file.".config/devenv/templates/default/devenv.yaml".text = ''
      inputs:
        nixpkgs:
          url: github:NixOS/nixpkgs/nixpkgs-unstable
    '';
  };
}
