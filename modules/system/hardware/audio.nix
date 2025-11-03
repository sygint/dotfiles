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

        # WirePlumber configuration for Bluetooth auto-switching
        wireplumber.extraConfig = {
          "51-bluetooth-priority" = {
            # Set high priority for Bluetooth devices so they become default when connected
            # This allows automatic switching to BT headphones when they connect,
            # and back to built-in speakers when they disconnect
            "monitor.bluez.rules" = [
              {
                matches = [
                  # Match all Bluetooth audio sinks (output devices like headphones)
                  {
                    "node.name" = "~bluez_output.*";
                  }
                  # Match all Bluetooth audio sources (input devices like mics)
                  {
                    "node.name" = "~bluez_input.*";
                  }
                ];
                actions = {
                  "update-props" = {
                    # Set high session priority (default is 0)
                    # Higher values mean this device will be preferred as default
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
