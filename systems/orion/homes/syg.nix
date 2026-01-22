{ pkgs, ... }:
{
  imports = [
    ../../../modules/home/_base-desktop
    ../../../modules/home.nix
    ./extra-programs.nix
  ];

  home.packages = with pkgs; [
    rofi
  ];

  # Make the monitor-setup script available in the user's PATH by
  # adding it to $HOME/bin via home.file. This avoids injecting the
  # script into system evaluation and keeps it available for interactive
  # sessions and user-level automation. The inline script prefers a
  # monitors.json in $HOME/.config/nixos/monitors.json or $HOME/.config/monitors.json
  home.file."bin/monitor-setup" = {
    text = ''
      #!/usr/bin/env bash
          set -euo pipefail

          MONITORS_JSON=""
          for path in "$HOME/.config/nixos/monitors.json" "$HOME/.config/monitors.json" "/etc/monitors.json"; do
            if [ -f "$path" ]; then MONITORS_JSON="$path"; break; fi
          done

          if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ -z "$XDG_RUNTIME_DIR" ]; then
            echo "No graphical display detected; skipping monitor setup."
            exit 0
          fi

          if ! command -v hyprctl >/dev/null 2>&1; then
            echo "hyprctl not found; skipping monitor setup." >&2
            exit 0
          fi
          if ! command -v jq >/dev/null 2>&1; then
            echo "jq not found; skipping monitor setup." >&2
            exit 0
          fi

          if [ -z "$MONITORS_JSON" ]; then
            echo "No monitors.json found in standard locations; nothing to configure." >&2
            exit 0
          fi

          names="$(hyprctl monitors -j | jq -r '.[].name')"
          count="$(printf "%s\n" "$names" | wc -l | tr -d ' ')"
          if [ "$count" -eq 0 ]; then
            echo "No monitors detected; skipping." >&2
            exit 0
          fi

          while IFS= read -r name; do
            if jq -e --arg n "$name" 'has($n)' "$MONITORS_JSON" >/dev/null; then
              config="$(jq -r --arg n "$name" '.[$n]' "$MONITORS_JSON")"
              echo "Applying monitor config for $name: $config"
              hyprctl keyword monitor "$name, $config" || echo "Failed to apply config for $name"
            else
              echo "No config found for monitor: $name" >&2
            fi
          done <<< "$names"

    '';
    executable = true;
  };

  modules.programs = {
    # hyprland now managed by unified features.hyprland module in system config
    # hyprpanel, waybar, hypridle, screenshots now managed by unified features in system config
    # git, kitty, btop, devenv, vscode now managed by unified features in system config
    # brave, firefox, librewolf now managed by unified features in system config
    # archiver, protonmail-bridge now managed by unified features in system config

    # mullvad-browser now managed by unified features.mullvad module in system config
  };

  # Declarative Flatpak management
  services.flatpak = {
    enable = true;
    packages = [
      "us.zoom.Zoom"
    ];
    update = {
      onActivation = false; # Don't auto-update on every rebuild
      auto = {
        enable = true;
        onCalendar = "weekly"; # Auto-update weekly
      };
    };
  };

  # Add Flatpak directories to XDG_DATA_DIRS so apps appear in Rofi
  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
  };

  # wayland.windowManager.sway.enable = true;

  # Enable XDG user directories
  # xdg = {
  #   enable = true;
  #   createDirectories = true;
  #   userDirs = {
  #     enable = true;
  #     documents = "Documents";
  #     downloads = "Downloads";
  #     music = "Music";
  #     pictures = "Pictures";
  #     videos = "Videos";
  #   };
  # };
}
