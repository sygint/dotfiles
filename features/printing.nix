{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    types
    ;
  cfg = config.modules.features.printing;
in
{
  options.modules.features.printing = {
    enable = mkEnableOption "CUPS printing service with comprehensive USB printer support";

    enableAutoDiscovery = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic discovery of network printers via Avahi";
    };

    enableSharing = mkOption {
      type = types.bool;
      default = false;
      description = "Enable printer sharing over the network";
    };

    enableGuiTools = mkOption {
      type = types.bool;
      default = true;
      description = "Enable additional GUI tools for printer and scanner management";
    };

    drivers = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        # Generic drivers for most printers
        gutenprint

        # HP printer drivers
        hplip

        # Generic PostScript and PCL drivers
        ghostscript
      ];
      description = "List of printer driver packages to install";
    };

    extraDrivers = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional printer drivers to install beyond the default set";
    };

    logLevel = mkOption {
      type = types.enum [
        "error"
        "warn"
        "info"
        "debug"
        "debug2"
      ];
      default = "info";
      description = "CUPS logging level";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional CUPS configuration";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Basic CUPS configuration
    {
      services.printing = {
        enable = true;
        logLevel = cfg.logLevel;
        drivers = cfg.drivers ++ cfg.extraDrivers;
        extraConf = cfg.extraConfig;
      };

      # Enable system-config-printer for GUI management
      programs.system-config-printer.enable = true;

      # Add useful printer management tools
      environment.systemPackages =
        with pkgs;
        [
          cups
          system-config-printer
        ]
        ++ lib.optionals cfg.enableGuiTools [
          # Additional GUI and CLI tools
          simple-scan # Scanning application
          hplip # HP printer management GUI (hp-toolbox)
          gtk3 # Ensure GTK3 support for printer dialogs
        ];
    }

    # Auto-discovery configuration
    (mkIf cfg.enableAutoDiscovery {
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    })

    # Printer sharing configuration
    (mkIf cfg.enableSharing {
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          userServices = true;
        };
      };

      services.printing = {
        listenAddresses = [ "*:631" ];
        allowFrom = [ "all" ];
        browsing = true;
        defaultShared = true;
        openFirewall = true;
      };
    })
  ]);
}
