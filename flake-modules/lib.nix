# Shared constants and utilities for flake modules
{ inputs, ... }:
let
  # System architecture - defined once for consistency
  system = "x86_64-linux";

  # Import variables for home-manager - shared across modules
  variables = import ../systems/orion/variables.nix;
  userVars = variables.user;
  systemVars = variables.system;
in
{
  inherit
    system
    variables
    userVars
    systemVars
    ;
}
