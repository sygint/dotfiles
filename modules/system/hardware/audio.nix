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

        # WirePlumber configuration for audio device priority
        wireplumber.extraConfig = {
          "51-device-priority" = {
            # Priority rules for automatic device selection
            # Higher priority.session values = preferred as default
            # Order: Bluetooth (2000) > Built-in Audio (1009) > USB Dock (500)
            "monitor.alsa.rules" = [
              {
                matches = [
                  # Match USB dock audio (PCM2912A codec from docking station)
                  {
                    "node.name" = "~alsa_output.usb-Burr-Brown_from_TI_USB_audio_CODEC.*";
                  }
                ];
                actions = {
                  "update-props" = {
                    # Lower priority so built-in speakers are preferred
                    # USB dock still available for manual selection when needed
                    "priority.session" = 500;
                  };
                };
              }
              {
                matches = [
                  # Match SteelSeries Arctis 1 Wireless headset (USB dongle)
                  {
                    "node.name" = "~alsa_output.usb-SteelSeries_SteelSeries_Arctis_1_Wireless.*";
                  }
                ];
                actions = {
                  "update-props" = {
                    # Lower priority so built-in speakers are preferred
                    # SteelSeries still available for manual selection when needed
                    "priority.session" = 500;
                  };
                };
              }
            ];
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
                    # Set high session priority (default is 0, ALSA devices are around 1000-1009)
                    # Higher values mean this device will be preferred as default
                    # We set this to 2000 to ensure Bluetooth takes precedence over all other audio
                    "priority.session" = 2000;
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
