{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url   = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprland.url  = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    stylix.url = "github:danth/stylix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    home-manager = {
      url                    = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-hardware, home-manager, zen-browser, ... } @ inputs:
  let
    lib      = nixpkgs.lib;
    system   = "x86_64-linux";  # Make sure to specify the system architecture
    hostName = "nixos";
    username = "syg";
    syncPassword = "syncmybattleship";
  in
  {
    nixosConfigurations = {
      "${hostName}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit system;
          inherit inputs;
          inherit username;
          inherit hostName;
          inherit syncPassword;
        };
        modules = [
          inputs.stylix.nixosModules.stylix
          
          ./systems/nixos
          nixos-hardware.nixosModules.framework-13-7040-amd

          {nixpkgs.overlays = [inputs.hyprpanel.overlay];}

          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              inherit inputs;
              inherit username;
              inherit hostName;
              inherit syncPassword;
            };
            home-manager.useGlobalPkgs       = true;
            home-manager.useUserPackages     = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.${username}   = import ./hosts/${hostName}/home.nix;
          }
        ];
      };
    };
  };
}
