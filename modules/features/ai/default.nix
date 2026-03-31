{ config, lib, pkgs, ... }:

# Thin wrapper so modules/features/default.nix auto-discovery picks up this feature
# Imports the main ai.nix implementation in this directory.

let
  impl = import ./ai.nix;
in impl
