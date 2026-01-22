# Example: Complex Feature with Multiple Options
#
# This example shows a complex feature module with:
# - Multiple configuration options
# - Conditional features
# - Both system and user configuration
# - Settings passed to configuration files
#
# Location: modules/features/example-complex.nix

{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.features.example-complex;

  # Helper to generate config file
  configFile = pkgs.writeText "example-config.json" (
    builtins.toJSON {
      username = userVars.username;
      theme = cfg.theme;
      plugins = cfg.plugins;
      advanced = cfg.enableAdvanced;
    }
  );
in
{
  options.modules.features.example-complex = {
    enable = mkEnableOption "Example Complex Feature";

    theme = mkOption {
      type = types.enum [
        "light"
        "dark"
        "auto"
      ];
      default = "dark";
      description = "Color theme to use";
    };

    plugins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of plugins to enable";
      example = [
        "plugin1"
        "plugin2"
      ];
    };

    enableAdvanced = mkOption {
      type = types.bool;
      default = false;
      description = "Enable advanced features";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional settings";
    };
  };

  config = mkIf cfg.enable {
    # System: Base package
    environment.systemPackages = with pkgs; [
      jq # For working with JSON config
    ];

    # System: Advanced features (conditional)
    environment.systemPackages = mkIf cfg.enableAdvanced (
      with pkgs;
      [
        nodejs # Additional tools for advanced features
      ]
    );

    # User: Configuration
    home-manager.users.${userVars.username} = {
      # Main package
      home.packages = with pkgs; [
        bat # Example main tool
      ];

      # Configuration file from generated JSON
      xdg.configFile."example/config.json".source = configFile;

      # Additional config with user settings
      home.file.".config/example/settings.toml".text = ''
        theme = "${cfg.theme}"

        [plugins]
        ${lib.concatMapStringsSep "\n" (p: "enable_${p} = true") cfg.plugins}

        [advanced]
        enabled = ${if cfg.enableAdvanced then "true" else "false"}

        [custom]
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${builtins.toJSON v}") cfg.settings)}
      '';
    };
  };
}
