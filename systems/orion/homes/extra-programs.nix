{ pkgs, ... }:
let
  opencode = pkgs.callPackage ../../../packages/opencode.nix { };
  opencode-desktop = pkgs.callPackage ../../../packages/opencode-desktop.nix { };
in
{
  # Extra user-specific packages for syg
  # This is where we add additional programs that don't need
  # their own complex configuration modules
  home.packages = with pkgs; [
    appimage-run
    claude-code
    claude-code-router
    obsidian
    opencode
    opencode-desktop
    solaar
    tea
    zed-editor
    gnome-calculator
    grsync
    # Add other extra programs here as needed
  ];
}
