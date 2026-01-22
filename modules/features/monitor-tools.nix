{
  config,
  lib,
  pkgs,
  self,
  userVars,
  inputs ? { },
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.monitor-tools;
  # Attempt to include the real monitor-setup script from the flake root
  # (inputs.self). If it's missing because of an unusual import/eval
  # context, fall back to placing a harmless placeholder script to
  # avoid blocking system evaluation.
  scriptSrcFromSelf = self + "/scripts/desktop/monitor-setup.sh";
  scriptSrcLocal = ./../../scripts/desktop/monitor-setup.sh;
  scriptSrc =
    if builtins.pathExists scriptSrcFromSelf then
      scriptSrcFromSelf
    else if builtins.pathExists scriptSrcLocal then
      scriptSrcLocal
    else
      null;
  scriptExists = scriptSrc != null && builtins.pathExists scriptSrc;
  monitorSetupPackage = if lib.hasAttr "monitorSetup" self then self.monitorSetup else null;
in
{
  options.modules.features.monitor-tools.enable =
    mkEnableOption "Monitor tools and scripts globally available";

  config = mkIf cfg.enable {
    environment.systemPackages = [
      # Read the script from the repo root's scripts/desktop directory; correct
      # relative path from this module file (modules/features/) is
      # '../../scripts/desktop/monitor-setup.sh'. Using builtins.readFile
      # ensures the script is included in the Nix derivation so it's usable
      # on the target system.
      # Prefer reading the script via the flake input root to ensure
      # the file is always available during flake evaluation (handles
      # both local repo and flake-imported module cases).
      # Provide a safe placeholder for the monitor-setup wrapper so the
      # system can include a `monitor-setup` command without failing at
      # evaluation when `scripts/desktop/monitor-setup.sh` isn't available
      # at evaluation time. The real script continues to live under
      # `scripts/desktop/monitor-setup.sh` and can be invoked directly from
      # user scripts (or this module can be updated to include the real
      # script contents once a robust import strategy is implemented).
      # Include the full script content so the `monitor-setup` binary
      # is the same as the script in the repo. Use `inputs.self` to
      # locate the file in flake context; this works when this module is
      # evaluated as part of the flake described by this repository.
      # Note: monitor-setup is provided at user-level (home-manager) to
      # avoid flake evaluation issues at system evaluation time. System
      # package only includes utilities like jq.
      (
        if monitorSetupPackage != null then
          monitorSetupPackage
        else
          (pkgs.writeShellScriptBin "monitor-setup" (
            let
              scriptText =
                if scriptExists then
                  builtins.readFile scriptSrc
                else
                  ''
                    #!/usr/bin/env bash
                    echo "monitor-setup placeholder installed; real script missing at evaluation time."
                    exit 0
                  '';
            in
            scriptText
          ))
      )
      pkgs.jq
    ];
  };
}
