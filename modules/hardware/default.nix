# Hardware modules — physical layer (GPUs, sensors, firmware)
# Auto-discovers .nix files and directories with default.nix
{ ... }:
let
  entries = builtins.readDir ./.;
  isModule =
    name: type:
    name != "default.nix"
    && builtins.substring 0 1 name != "_"
    && (
      (type == "regular" && builtins.match ".*\\.nix" name != null)
      || (type == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
    );
  moduleNames = builtins.filter (n: isModule n entries.${n}) (builtins.attrNames entries);
  makePath =
    name: type: if type == "directory" then ./. + "/${name}/default.nix" else ./. + "/${name}";
in
{
  imports = map (name: makePath name entries.${name}) moduleNames;
}
