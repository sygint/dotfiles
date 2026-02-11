{
  description = "NixOS config flake with flake-parts";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    dotfiles = {
      url = "path:./dotfiles";
      flake = false;
    };
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
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixos-secrets.url = "path:/home/syg/.config/nixos-secrets";
    nixos-secrets.flake = false;
    opencode.url = "github:anomalyco/opencode";
    devenv-bootstrap.url = "path:/home/syg/.config/nixos/archive/devenv-bootstrap";
    import-tree.url = "github:vic/import-tree";

    # Fleet management with Colmena
    nixos-fleet.url = "path:/home/syg/Projects/open-source/nixos-fleet";

    # Dank Material Shell - Quickshell-based desktop shell for Wayland
    dank-material-shell.url = "github:AvengeMedia/DankMaterialShell";
    dank-material-shell.inputs.nixpkgs.follows = "nixpkgs";

    # Noctalia Shell - Minimal Quickshell-based desktop shell
    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";
    noctalia-shell.inputs.nixpkgs.follows = "nixpkgs";

    # swhkd - Simple Wayland HotKey Daemon for compositor-agnostic keybindings
    swhkd.url = "github:waycrate/swhkd";
    swhkd.inputs.nixpkgs.follows = "nixpkgs";

    # CI/CD - Buildbot-nix for Nix flake builds
    buildbot-nix.url = "github:nix-community/buildbot-nix";

    # Binary cache - Harmonia for serving build artifacts
    harmonia.url = "github:nix-community/harmonia";
    harmonia.inputs.nixpkgs.follows = "nixpkgs";
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
        ./flake-modules/colmena.nix
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
        let
          fleetConfig = import ./fleet-config.nix;
          hostNames = builtins.attrNames fleetConfig.hosts;
          wolHosts = builtins.filter (n: fleetConfig.hosts.${n}.wol.enabled) hostNames;

          # Generate case branches for fleet-sleep
          sleepCases = builtins.concatStringsSep "\n" (
            builtins.map (
              name:
              let
                h = fleetConfig.hosts.${name};
              in
              "${name}) echo 'Suspending ${name} (${h.ip})...'; ssh ${h.ssh.user}@${h.ip} 'sudo systemctl suspend'; echo '${name} is now suspended.' ;;"
            ) hostNames
          );

          # Generate case branches for fleet-wake
          wakeCases = builtins.concatStringsSep "\n" (
            builtins.map (
              name:
              let
                h = fleetConfig.hosts.${name};
              in
              "${name}) echo 'Sending WoL magic packet to ${name} (MAC: ${h.wol.mac})...'; ${pkgs.wol}/bin/wol ${h.wol.mac}; echo 'Magic packet sent. ${name} should wake shortly.'; echo 'Check with: ping ${h.ip}' ;;"
            ) wolHosts
          );

          # Host list strings for help text
          sleepHostList = builtins.concatStringsSep "\n" (
            builtins.map (
              name:
              let
                h = fleetConfig.hosts.${name};
              in
              "  ${name} (${h.ip})"
            ) hostNames
          );
          wakeHostList = builtins.concatStringsSep "\n" (
            builtins.map (
              name:
              let
                h = fleetConfig.hosts.${name};
              in
              "  ${name} (MAC: ${h.wol.mac}, IP: ${h.ip})"
            ) wolHosts
          );

          fleet-sleep = pkgs.writeShellScriptBin "fleet-sleep" ''
            set -euo pipefail
            HOST="''${1:-}"
            if [ -z "$HOST" ]; then
              echo "Usage: fleet-sleep <hostname>"
              echo ""
              echo "Suspends a remote machine via SSH."
              echo ""
              echo "Available hosts:"
              echo "${sleepHostList}"
              exit 1
            fi
            case "$HOST" in
            ${sleepCases}
            *) echo "Error: Unknown host '$HOST'"; exit 1 ;;
            esac
          '';

          fleet-wake = pkgs.writeShellScriptBin "fleet-wake" ''
            set -euo pipefail
            HOST="''${1:-}"
            if [ -z "$HOST" ]; then
              echo "Usage: fleet-wake <hostname>"
              echo ""
              echo "Sends a Wake-on-LAN magic packet to wake a remote machine."
              echo ""
              echo "WoL-enabled hosts:"
              echo "${wakeHostList}"
              exit 1
            fi
            case "$HOST" in
            ${wakeCases}
            *) echo "Error: Host '$HOST' does not have Wake-on-LAN enabled."; echo "Enable it in fleet-config.nix under hosts.\$HOST.wol"; exit 1 ;;
            esac
          '';
        in
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
              inputs'.nixos-fleet.packages.fleet
              fleet-sleep
              fleet-wake
            ];
          };

          # Colmena app wrapper for fleet CLI
          apps.colmena = {
            type = "app";
            program = "${pkgs.writeShellScript "colmena-wrapper" ''
              exec ${pkgs.colmena}/bin/colmena "$@"
            ''}";
            meta.description = "Colmena deployment tool for NixOS fleet management";
          };
        };
    };
}
