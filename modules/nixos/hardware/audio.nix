{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.hardware.audio;
in {
  options.settings.hardware.audio.enable = mkEnableOption "Audio";

  config = mkIf cfg.enable {
    services = {
      # Disable PulseAudio (will use PipeWire)
      pulseaudio.enable = false;
      
      pipewire = {
        enable                 = true; # Enable PipeWire for audio
        alsa.enable            = true; # Enable ALSA support for PipeWire
        # alsa.support32Bit    = true;
        pulse.enable           = true; # Enable PulseAudio emulation for PipeWire
        # If you want to use JACK applications, uncomment this
        #jack.enable           = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        # media-session.enable = true;
      };
    };
  };
}