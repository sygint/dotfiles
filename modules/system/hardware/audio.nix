{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.hardware.audio;
in
{
  options.modules.hardware.audio.enable = mkEnableOption "Audio";

  config = mkIf cfg.enable {
    services = {
      # Disable PulseAudio (will use PipeWire)
      pulseaudio.enable = false;

      pipewire = {
        enable = true; # Enable PipeWire for audio
        alsa.enable = true; # Enable ALSA support for PipeWire
        # alsa.support32Bit    = true;
        pulse.enable = true; # Enable PulseAudio emulation for PipeWire
        # If you want to use JACK applications, uncomment this
        #jack.enable           = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        # media-session.enable = true;

        # Auto-switch to Bluetooth audio when devices connect
        wireplumber.extraConfig = {
          "51-bluetooth-priority" = {
            "monitor.bluez.rules" = [
              {
                matches = [
                  { "node.name" = "~bluez_output.*"; }
                  { "node.name" = "~bluez_input.*"; }
                ];
                actions = {
                  update-props = {
                    "priority.session" = 1000;
                  };
                };
              }
            ];
          };
        };
      };
    };
  };
}
