{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem = { config, pkgs, lib, ... }: {
    pre-commit = {
      check.enable = false; # Disable NixOS check (self-referential build issue)
      settings.hooks = {
        deadnix.enable = true;
        statix.enable = true;
        flake-checker.enable = true;
        nixfmt.enable = true;
      };
    };
  };
}
