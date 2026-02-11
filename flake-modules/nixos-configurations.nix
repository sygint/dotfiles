{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  # Import shared constants and system definitions
  shared = import ./lib.nix { inherit inputs; };
  inherit (shared) systems hostVars;
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
          ;
        userVars = vars.user;
        fh = inputs.fh;
        hasSecrets = cfg.hasSecrets;
      };
    }
  ) systems;
}
