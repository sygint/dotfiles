{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  fleetConfig = import ../fleet-config.nix;

  # Import shared constants (same as nixos-configurations.nix)
  shared = import ./lib.nix { inherit inputs; };
  inherit (shared) system userVars;

  # Re-import the systems definition from nixos-configurations.nix
  # This ensures we use the same module lists
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
  };
in
{
  # Generate Colmena hive configuration
  flake.colmena = {
    meta = {
      # Colmena requires nixpkgs at the top level
      nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      # Pass through the same specialArgs as nixosConfigurations
      specialArgs = {
        inherit
          self
          system
          inputs
          userVars
          fleetConfig
          ;
        fh = inputs.fh;
      };
    };
  }
  // lib.mapAttrs (
    name: hostCfg:
    let
      systemCfg = systems.${name};
    in
    {
      # Deployment configuration from fleet-config.nix
      deployment = {
        targetHost = hostCfg.ip;
        targetUser = hostCfg.ssh.user or "root";
        targetPort = hostCfg.ssh.port or 22;
        # Use buildOnTarget based on fleet-config's deploy.remoteBuild setting
        buildOnTarget = hostCfg.deploy.remoteBuild or false;
        tags = hostCfg.tags or [ ];
      };

      # Import the same modules as nixosConfigurations, plus a module to inject hasSecrets
      imports = [
        systemCfg.path
      ]
      ++ systemCfg.modules
      ++ [
        # Inject hasSecrets as a module to avoid needing it in specialArgs
        (
          { lib, ... }:
          {
            _module.args.hasSecrets = lib.mkForce systemCfg.hasSecrets;
          }
        )
      ];
    }
  ) fleetConfig.hosts;
}
