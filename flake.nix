{
  description = "Nixos config flake";

  inputs = {
    nix-snapd.url = "https://flakehub.com/f/io12/nix-snapd/0.1.47.tar.gz";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";
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
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
  };

  outputs = { nixpkgs, nixos-hardware, home-manager, fh, nix-snapd, ... } @ inputs:
  let
    lib          = nixpkgs.lib;
    system       = "x86_64-linux";  # Make sure to specify the system architecture

    inherit (import ./variables.nix) hostName username gitUsername gitEmail syncPassword browser terminal keyboardLayout menu;
  in
  {
    nixosConfigurations = {
      "${hostName}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit system;
          inherit inputs;
          inherit hostName;
          inherit username;
          inherit syncPassword;
          inherit fh;
        };
        modules = [
          inputs.stylix.nixosModules.stylix
          nix-snapd.nixosModules.default
          ./systems/nixos
          nixos-hardware.nixosModules.framework-13-7040-amd

          {nixpkgs.overlays = [inputs.hyprpanel.overlay];}

          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              inherit inputs;
              inherit username;
              inherit gitUsername;
              inherit gitEmail;
              inherit browser;
              inherit terminal;
              inherit keyboardLayout;
              inherit menu;
            };
            home-manager.useGlobalPkgs       = true;
            home-manager.useUserPackages     = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.${username}   = import ./home/${username}.nix;
          }
        ];
      };
    };
  };
}
