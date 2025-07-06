{ lib, ... }:
{
  imports =
    lib.fileset.toList (
      lib.fileset.fileFilter
        (file:
          file.hasExt "nix"
          && file.name != "default.nix"
          && !lib.strings.hasSuffix ".conf.nix" file.name
          && !lib.strings.hasSuffix ".tmpl.nix" file.name
        )
        ./home
    );
}