{ pkgs, ... }:
let
  lmstudio = pkgs.callPackage ../../../packages/lmstudio.nix { };
  opencode = pkgs.callPackage ../../../packages/opencode.nix { };
  opencode-desktop = pkgs.callPackage ../../../packages/opencode-desktop.nix { };
  opencode-lmstudio-sync = pkgs.callPackage ../../../packages/opencode-lmstudio-sync.nix { };
  lms-promote = pkgs.callPackage ../../../packages/lms-promote.nix { };
in
{
  # Extra user-specific packages for syg
  # This is where we add additional programs that don't need
  # their own complex configuration modules
  home.packages = with pkgs; [
    appimage-run
    bun
    claude-code
    claude-code-router
    lmstudio
    obsidian
    opencode
    opencode-desktop
    opencode-lmstudio-sync
    lms-promote
    solaar
    slack
    tea
    zed-editor
    gnome-calculator
    grsync
    # Add other extra programs here as needed
  ];
}
