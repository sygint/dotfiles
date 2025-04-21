{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.services.containerization;
in {
  options.settings.services.containerization = {
    enable = mkEnableOption "Enable Containerization (Podman)";

    service = lib.mkOption {
      type = lib.types.enum [ "podman" "docker" ];
      default = "podman";
      description = "The containerization service to use (either podman or docker).";
    };
  };

  config = mkIf cfg.enable (
    mkIf (cfg.service == "podman") {
      # Podman
      virtualisation = {
        containers.enable = true;

        podman = {
          enable = true;
          
          # Create a `docker` alias for podman, to use it as a drop-in replacement
          dockerCompat = true;

          # Required for containers under podman-compose to be able to talk to each other.
          defaultNetwork.settings.dns_enabled = true;
        };
      };

      environment = {
        systemPackages = with pkgs; [
          dive # look into docker image layers
          podman-tui # status of containers in the terminal
          docker-compose # start group of containers for dev
          #podman-compose # start group of containers for dev
          podman-desktop
        ];
      
        # for running rootless podman
        extraInit = ''
          if [ -z "$DOCKER_HOST" -a -n "$XDG_RUNTIME_DIR" ]; then
            export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
          fi
        '';
      };
    # } // mkIf (cfg.service == "docker") {
      # not currently supported
    }
  );
}