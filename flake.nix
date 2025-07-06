{
  description = "Nixos config flake";

  inputs = {
    nix-snapd.url = "https://flakehub.com/f/io12/nix-snapd/0.1.47.tar.gz";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url   = "github:nixos/nixpkgs?shallow=1&ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprland.url  = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    stylix.url = "github:danth/stylix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    home-manager = {
      url                    = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
  };

  outputs = { nixpkgs, nixos-hardware, home-manager, fh, nix-snapd, ... } @ inputs:
  let
    lib          = nixpkgs.lib;
    system       = "x86_64-linux";  # Make sure to specify the system architecture

    userVars = import ./variables.nix;
    inherit (userVars) hostName username;
    
    # Common pkgs configuration
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations = {
      "${hostName}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit
            system
            inputs
            fh
            userVars
          ;
        };
        
        pkgs = nixpkgs.legacyPackages.x86_64-linux;

        modules = [
          inputs.stylix.nixosModules.stylix
          nix-snapd.nixosModules.default
          ./systems/nixos
          nixos-hardware.nixosModules.framework-13-7040-amd

          {nixpkgs.overlays = [inputs.hyprpanel.overlay];}

          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              inherit
                inputs
                userVars
                ;
            };
            home-manager.useGlobalPkgs       = true;
            home-manager.useUserPackages     = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.${username}   = import ./home/${username}.nix;
          }
        ];
      };
    };

    # Standalone Home Manager configuration
    homeConfigurations = {
      "syg" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs;
        extraSpecialArgs = {
          inherit inputs userVars;
        };
        modules = [
          ./home-standalone.nix
          {
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };
    };
  };
}
