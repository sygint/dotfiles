{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    # Uncomment and configure home-manager if you want to use it:
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { nixpkgs, home-manager, ... } @ inputs:
  let
    lib = nixpkgs.lib;
    system = "x86_64-linux";  # Make sure to specify the system architecture
    host = "nixos";
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
          ./hosts/${host}/configuration.nix
          {nixpkgs.overlays = [inputs.hyprpanel.overlay];}
        ];
      };
    };
  };
}
