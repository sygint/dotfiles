{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url   = "github:nixos/nixpkgs?ref=nixos-unstable";
    hyprland.url  = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    stylix.url = "github:danth/stylix";
    home-manager = {
      url                    = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... } @ inputs:
  let
    lib      = nixpkgs.lib;
    system   = "x86_64-linux";  # Make sure to specify the system architecture
    host     = "nixos";
    username = "syg";
  in
  {
    nixosConfigurations = {
      "${host}" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit system;
          inherit inputs;
          inherit username;
          inherit host;
        };
        modules = [
          inputs.stylix.nixosModules.stylix
          
          ./hosts/${host}/configuration.nix

          {nixpkgs.overlays = [inputs.hyprpanel.overlay];}

          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              inherit username;
              inherit inputs;
              inherit host;
            };
            home-manager.useGlobalPkgs       = true;
            home-manager.useUserPackages     = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.${username}   = import ./hosts/${host}/home.nix;
          }
        ];
      };
    };
  };
}
