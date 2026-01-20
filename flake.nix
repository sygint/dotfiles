{
  description = "NixOS config flake with flake-parts";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
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
    # Binary caches for faster builds
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Import flake modules
      imports = [
        ./flake-modules/nixos-configurations.nix
        ./flake-modules/home-configurations.nix
        ./flake-modules/deploy.nix
      ];

      # Systems to support
      systems = [ "x86_64-linux" ];

      # Per-system outputs (packages, devShells, etc.)
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Formatter
          formatter = pkgs.nixpkgs-fmt;

          # Dev shell
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nixd
              nixpkgs-fmt
              just
            ];
          };
        };
    };
}
