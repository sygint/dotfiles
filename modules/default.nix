# Master module import — single auto-discovery for all module directories
#
# Scans hardware/ and features/ for .nix files and directories with default.nix.
# system/ is imported directly (it's a real module, not a discovery target).
# home/ is imported via home-manager.sharedModules in system configs.
{ ... }:
let
  # Scan a directory for .nix modules (files and dirs with default.nix)
  discoverModules = dir:
    let
      entries = builtins.readDir dir;
      isModule = name: type:
        name != "default.nix"
        && builtins.substring 0 1 name != "_"
        && (
          (type == "regular" && builtins.match ".*\\.nix" name != null)
          || (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
        );
      names = builtins.filter (n: isModule n entries.${n}) (builtins.attrNames entries);
      toPath = name: type:
        if type == "directory" then dir + "/${name}/default.nix" else dir + "/${name}";
    in
    map (name: toPath name entries.${name}) names;
in
{
  imports =
    discoverModules ./hardware
    ++ discoverModules ./features
    ++ [ ./system ];
}
