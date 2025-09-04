{ lib, ... }:
{
  imports = lib.fileset.toList (
    lib.fileset.fileFilter
      (file:
        file.hasExt "nix"
        && file.name != "default.nix"
        && !lib.strings.hasSuffix ".conf.nix" file.name
      )
      ./nixos
  );
}
