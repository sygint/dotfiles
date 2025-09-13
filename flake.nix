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
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, fh, nix-snapd, ... } @ inputs:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux"; # Make sure to specify the system architecture

      variables = import ./systems/orion/variables.nix;
      inherit (variables.user) username;

      userVars = variables.user;
      systemVars = variables.system;

      # Common pkgs configuration
      inherit (nixpkgs.legacyPackages.${system}) pkgs;

      # Function to create home configuration for any user
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
      nixosConfigurations = {
        orion = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit self system inputs fh userVars;
          };

          modules = [
            inputs.stylix.nixosModules.stylix
            nix-snapd.nixosModules.default
            ./systems/orion
            nixos-hardware.nixosModules.framework-13-7040-amd

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit self inputs userVars;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.${username} = import ./systems/orion/homes/syg.nix;
              };
            }
          ];
        };
      };

      # Standalone Home Manager configuration
      homeConfigurations = {
        # Standard username configuration
        ${username} = mkHomeConfiguration userVars;
        # Also provide hostname@user format for nh compatibility
        "${username}@${systemVars.hostName}" = mkHomeConfiguration userVars;
      };
    };
}
