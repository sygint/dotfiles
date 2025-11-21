{ lib, ... }:
{
  imports = lib.fileset.toList (
    lib.fileset.fileFilter
      (file:
        file.hasExt "nix"
        && file.name != "default.nix"
        && !lib.strings.hasSuffix ".conf.nix" file.name
      )
      ./home/programs
  );

  # Home Manager state version (should match system.stateVersion)
  home.stateVersion = "24.11";
}
