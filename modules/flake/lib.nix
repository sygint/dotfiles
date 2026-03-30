# Shared constants and utilities for flake modules
{ inputs, ... }:
let
  # System architecture - defined once for consistency
  system = "x86_64-linux";

  # Per-host system definitions — single source of truth for both
  # nixosConfigurations and Colmena. Add new systems here.
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
        inputs.buildbot-nix.nixosModules.buildbot-master
        inputs.buildbot-nix.nixosModules.buildbot-worker
        inputs.harmonia.nixosModules.harmonia
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

  # Per-host user variables — loaded from each host's variables.nix
  # Used by specialArgs so modules can access host-specific settings
  hostVars = builtins.mapAttrs (name: cfg: import (cfg.path + "/variables.nix")) systems;
in
{
  inherit
    system
    systems
    hostVars
    ;
}
