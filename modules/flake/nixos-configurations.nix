{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  # Import shared constants and system definitions
  shared = import ./lib.nix { inherit inputs; };
  inherit (shared) systems hostVars;

  # Harmonix config for CLI
  harmonixConfig = import ../../harmonix-config.nix;
in
{
  flake.nixosConfigurations = lib.mapAttrs (
    name: cfg:
    let
      vars = hostVars.${name};
    in
    inputs.nixpkgs.lib.nixosSystem {
      modules = [ cfg.path ] ++ cfg.modules;
      specialArgs = {
        inherit
          self
          inputs
          harmonixConfig
          ;
        userVars = vars.user;
        fh = inputs.fh;
        hasSecrets = cfg.hasSecrets;
      };
    }
  ) systems;
}
