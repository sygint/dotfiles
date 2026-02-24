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
    types
    ;
  cfg = config.modules.features.sddm-noctalia;

  noctalia-sddm-theme = pkgs.stdenvNoCC.mkDerivation {
    propagatedBuildInputs = [ pkgs.sddm ];
    pname = "sddm-noctalia-theme";
    version = "unstable";

    src = pkgs.fetchFromGitHub {
      owner = "mda-dev";
      repo = "noctalia-sddm-theme";
      rev = "2f4485139b2be9999987450930988bb2793fc379";
      hash = "sha256-C7DLXvWTKW2TKFbqjWqzX9lfsWYku0x1WNoOyFGoQz4=";
    };

    dontBuild = true;
    dontWrapQtApps = true;

    installPhase = ''
            runHook preInstall

            mkdir -p $out/share/sddm/themes/noctalia
            cp -r . $out/share/sddm/themes/noctalia/

            ${lib.optionalString (cfg.wallpaper != null) ''
              cp ${cfg.wallpaper} $out/share/sddm/themes/noctalia/Assets/background.png
            ''}

            cat > $out/share/sddm/themes/noctalia/theme.conf <<EOF
      background=Assets/background.png
      fontFamily="${cfg.fontFamily}"
      dropShadows=${if cfg.dropShadows then "true" else "false"}
      blurRadius=${toString cfg.blurRadius}
      cardOpacity=${toString cfg.cardOpacity}
      buttonRadius=${toString cfg.buttonRadius}
      passwordInputRadius=${toString cfg.passwordInputRadius}
      cardRadius=${toString cfg.cardRadius}
      mPrimary=${cfg.colors.primary}
      mOnPrimary=${cfg.colors.onPrimary}
      mSecondary=${cfg.colors.secondary}
      mOnSecondary=${cfg.colors.onSecondary}
      mTertiary=${cfg.colors.tertiary}
      mOnTertiary=${cfg.colors.onTertiary}
      mError=${cfg.colors.error}
      mOnError=${cfg.colors.onError}
      mSurface=${cfg.colors.surface}
      mOnSurface=${cfg.colors.onSurface}
      mSurfaceVariant=${cfg.colors.surfaceVariant}
      mOnSurfaceVariant=${cfg.colors.onSurfaceVariant}
      mOutline=${cfg.colors.outline}
      mShadow=${cfg.colors.shadow}
      mHover=${cfg.colors.hover}
      mOnHover=${cfg.colors.onHover}
      EOF

            runHook postInstall
    '';
  };
in
{
  options.modules.features.sddm-noctalia = {
    enable = mkEnableOption "Noctalia-style SDDM login theme";

    wallpaper = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to wallpaper image for the login screen background";
    };

    fontFamily = mkOption {
      type = types.str;
      default = "Fira Sans, Noto Sans, sans-serif";
      description = "Font family for the login screen";
    };

    dropShadows = mkOption {
      type = types.bool;
      default = true;
    };

    blurRadius = mkOption {
      type = types.int;
      default = 40;
      description = "Background blur radius (0 = no blur)";
    };

    cardOpacity = mkOption {
      type = types.float;
      default = 0.95;
    };

    buttonRadius = mkOption {
      type = types.int;
      default = 20;
    };

    passwordInputRadius = mkOption {
      type = types.int;
      default = 30;
    };

    cardRadius = mkOption {
      type = types.int;
      default = 20;
    };

    colors = {
      primary = mkOption {
        type = types.str;
        default = "#89b4fa";
      };
      onPrimary = mkOption {
        type = types.str;
        default = "#e6e1e5";
      };
      secondary = mkOption {
        type = types.str;
        default = "#f5c2e7";
      };
      onSecondary = mkOption {
        type = types.str;
        default = "#e6e1e5";
      };
      tertiary = mkOption {
        type = types.str;
        default = "#94e2d5";
      };
      onTertiary = mkOption {
        type = types.str;
        default = "#e6e1e5";
      };
      error = mkOption {
        type = types.str;
        default = "#f38ba8";
      };
      onError = mkOption {
        type = types.str;
        default = "#ffffff";
      };
      surface = mkOption {
        type = types.str;
        default = "#1e1e2e";
      };
      onSurface = mkOption {
        type = types.str;
        default = "#ffffff";
      };
      surfaceVariant = mkOption {
        type = types.str;
        default = "#313244";
      };
      onSurfaceVariant = mkOption {
        type = types.str;
        default = "#ffffff";
      };
      outline = mkOption {
        type = types.str;
        default = "#45475a";
      };
      shadow = mkOption {
        type = types.str;
        default = "#000000";
      };
      hover = mkOption {
        type = types.str;
        default = "#89b4fa";
      };
      onHover = mkOption {
        type = types.str;
        default = "#e6e1e5";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      noctalia-sddm-theme
    ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = false;
      theme = "noctalia";
    };
  };
}
