{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # Uncomment and configure home-manager if you want to use it:
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { nixpkgs, ... } @ inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";  # Make sure to specify the system architecture
        modules = [
          ./hosts/default/configuration.nix
          # inputs.home-manager.nixosModules.default  # Uncomment to include home-manager
        ];
      };
    };
  };
}
