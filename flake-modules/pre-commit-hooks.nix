{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem = { config, ... }: {
    pre-commit.settings.hooks = {
      deadnix.enable = true;
      statix.enable = true;
      flake-checker.enable = true;
      nixfmt.enable = true;
    };
  };
}
