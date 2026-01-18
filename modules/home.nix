{ inputs, ... }:
{
  # Auto-import all home modules via import-tree (Phase 1: dendritic-lite)
  # All modules are imported, but only enabled modules are activated per user.
  # See: https://github.com/vic/import-tree
  imports = [
    (inputs.import-tree ./home)
  ];

  # Home Manager state version (should match system.stateVersion)
  home.stateVersion = "24.11";
}
