{
  description = "Nixos config flake";

  inputs = {
    nix-snapd.url = "https://flakehub.com/f/io12/nix-snapd/0.1.47.tar.gz";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs?shallow=1&ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    stylix.url = "github:danth/stylix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    disko.url = "github:nix-community/disko";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixos-secrets.url = "path:/home/syg/.config/nixos-secrets";
    nixos-secrets.flake = false;
    opencode.url = "github:anomalyco/opencode";
    devenv-bootstrap.url = "path:/home/syg/.config/nixos/archive/devenv-bootstrap";
    import-tree.url = "github:vic/import-tree";
  };

  nixConfig = {
    # NOTE: To use Cachix for binary caching, set up a personal cache at https://cachix.org and add your cache URL and public key here.
    # Example:
    # extra-substituters = [ "https://your-cachix.cachix.org" ];
    # extra-trusted-public-keys = [ "your-cachix.cachix.org-1:..." ];
    # See https://docs.cachix.org for setup instructions.
    # We'll revisit this later.
    # builders = [ ]; # No remote builders configured
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      fh,
      nix-snapd,
      nix-flatpak,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";

      # List all systems here for easy extensibility
      systems = {
        orion = {
          path = ./systems/orion;
          modules = [
            inputs.stylix.nixosModules.stylix
            nix-snapd.nixosModules.default
            nixos-hardware.nixosModules.framework-13-7040-amd
            home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
          ];
        };
        cortex = {
          path = ./systems/cortex;
          modules = [
            inputs.disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
          ];
        };
        nexus = {
          path = ./systems/nexus;
          modules = [
            inputs.disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
          ];
        };
        axon = {
          path = ./systems/axon;
          modules = [
            inputs.stylix.nixosModules.stylix
            home-manager.nixosModules.home-manager
          ];
        };
        # Add new systems here!
      };

      # Import variables for home-manager (unchanged)
      variables = import ./systems/orion/variables.nix;
      inherit (variables.user) username;
      userVars = variables.user;
      systemVars = variables.system;

      inherit (nixpkgs.legacyPackages.${system}) pkgs;

      mkHomeConfiguration =
        variables:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit self inputs userVars;
            opencode = inputs.opencode.packages.${system};
          };
          modules = [
            nix-flatpak.homeManagerModules.nix-flatpak
            ./systems/orion/homes/syg.nix
            {
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };
    in
    {
      nixosConfigurations = lib.mapAttrs (
        name: cfg:
        nixpkgs.lib.nixosSystem {
          system = system;
          modules = [ cfg.path ] ++ cfg.modules;
          specialArgs = {
            inherit
              self
              system
              inputs
              fh
              userVars
              ;
            # Enable secrets for cortex, orion, and nexus (age key configured)
            hasSecrets = if (name == "cortex" || name == "orion" || name == "nexus") then true else false;
          };
        }
      ) systems;

      homeConfigurations = {
        ${username} = mkHomeConfiguration userVars;
        "${username}@${systemVars.hostName}" = mkHomeConfiguration userVars;
      };

      # Add deploy-rs output for fleet management
      deploy = {
        sshUser = "jarvis"; # Global SSH user for all nodes

        nodes = {
          cortex = {
            hostname = "192.168.1.7"; # TODO: Switch to cortex.home when DNS is fixed
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.cortex;
              user = "root"; # Activate as root (via sudo)
            };
          };
          nexus = {
            hostname = "192.168.1.22"; # Nexus homelab services server
            sshUser = "admin"; # Override global SSH user for Nexus
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nexus;
              user = "root"; # Activate as root (via sudo)
            };
          };
          axon = {
            hostname = "192.168.1.11"; # TODO: Update with actual Axon IP
            profiles.system = {
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.axon;
              user = "root"; # Activate as root (via sudo)
            };
          };
          # Add other systems here as needed
        };
      };

      # Add deploy-rs checks
      checks = builtins.mapAttrs (
        system: deployLib: deployLib.deployChecks self.deploy
      ) inputs.deploy-rs.lib;
    };
}
