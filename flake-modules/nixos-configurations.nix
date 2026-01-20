{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  # Import shared constants
  shared = import ./lib.nix { inherit inputs; };
  inherit (shared) system userVars;

  # List all systems here for easy extensibility
  systems = {
    orion = {
      path = ../systems/orion;
      modules = [
        inputs.stylix.nixosModules.stylix
        inputs.nix-snapd.nixosModules.default
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
      ];
      hasSecrets = true;
    };
    cortex = {
      path = ../systems/cortex;
      modules = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
      ];
      hasSecrets = true;
    };
    nexus = {
      path = ../systems/nexus;
      modules = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
      ];
      hasSecrets = true;
    };
    axon = {
      path = ../systems/axon;
      modules = [
        inputs.stylix.nixosModules.stylix
        inputs.home-manager.nixosModules.home-manager
      ];
      hasSecrets = false;
    };
    # Add new systems here!
  };
in
{
  flake.nixosConfigurations = lib.mapAttrs (
    name: cfg:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ cfg.path ] ++ cfg.modules;
      specialArgs = {
        inherit
          self
          system
          inputs
          userVars
          ;
        fh = inputs.fh;
        hasSecrets = cfg.hasSecrets;
      };
    }
  ) systems;
}
