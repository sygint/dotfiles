{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.kitty;
in {
  options.settings.programs.kitty = {
    enable = mkEnableOption "Kitty terminal";
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      settings = {
        confirm_os_window_close = 0;
        scrollback_lines        = 2000;
        wheel_scroll_min_lines  = 1;
        window_padding_width    = 4;

        tab_bar_style           = "fade";
        tab_fade                = 1;
        active_tab_font_style   = "bold";
        inactive_tab_font_style = "bold";
      };
    };
  };
}