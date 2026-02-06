{ inputs, ... }:
let
  # Auto-discover all .nix files and directories in this folder
  entries = builtins.readDir ./.;
  isModule =
    name: type:
    # Skip default.nix and files starting with _ (templates)
    name != "default.nix"
    && builtins.substring 0 1 name != "_"
    && (
      (type == "regular" && builtins.match ".*\\.nix" name != null)
      || (type == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
    );
  moduleNames = builtins.filter (n: isModule n entries.${n}) (builtins.attrNames entries);
in
{
  imports = map (name: ./. + "/${name}") moduleNames;
}
