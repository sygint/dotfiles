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
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    disko.url = "github:nix-community/disko";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = { self, nixpkgs, nixos-hardware, home-manager, fh, nix-snapd, ... } @ inputs:
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
        # Add new systems here!
      };

      # Import variables for home-manager (unchanged)
      variables = import ./systems/orion/variables.nix;
      inherit (variables.user) username;
      userVars = variables.user;
      systemVars = variables.system;

      inherit (nixpkgs.legacyPackages.${system}) pkgs;

      mkHomeConfiguration = variables:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit self inputs userVars;
          };
          modules = [
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
              inherit self system inputs fh userVars;
              hasSecrets = false; # Temporarily disabled - will enable after age key setup
            };
          }
      ) systems;

      homeConfigurations = {
        ${username} = mkHomeConfiguration userVars;
        "${username}@${systemVars.hostName}" = mkHomeConfiguration userVars;
      };

        # Add deploy-rs output for fleet management
        deploy = {
          nodes = {
            cortex = {
              hostname = "192.168.1.7";  # Current DHCP IP - configure static reservation on UDM Pro for 192.168.1.34
              user = "jarvis";
              sshUser = "jarvis";
              profiles.system = {
                path = self.nixosConfigurations.cortex.config.system.build.toplevel;
              };
            };
            # Add other systems here as needed
          };
        };
    };
}
