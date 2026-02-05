{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.brave;
in
{
  options.modules.features.brave.enable =
    mkEnableOption "Brave web browser with privacy-focused configuration";

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} = {
      programs.chromium = {
        enable = true;
        package = pkgs.brave;
        extensions = [
          "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
          # "ldpochfccmkkmhdbclfhpagapcfdljkj" # Decentraleyes
          "ikclbgejgcbdlhjmckecmdljlpbhmbmf" # HTTPS Everywhere
          # "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
          # "fploionmjgeclbkemipmkogoaohcdbig" # Page Load time
          "hmgpakheknboplhmlicfkkgjipfabmhp" # Privacy | Private Debit Cards
          "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
          "fmkadmapgofadopljbjfkapdkoienihi" # React Developer Tools
          # "hjdoplcnndgiblooccencgcggcoihigg" # Terms of Service; Didn't Read
        ];
        commandLineArgs = [
          # Enable hardware video acceleration
          "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
          "--enable-accelerated-video-decode"
          "--enable-gpu-rasterization"
          "--ignore-gpu-blocklist"
          # Use VA-API for video acceleration on AMD/Intel
          "--enable-features=UseOzonePlatform"
          "--ozone-platform=wayland"
          # Disable Brave Rewards and BAT ads completely
          "--disable-brave-rewards"
          "--disable-brave-rewards-extension"
          "--disable-brave-update"
          # Disable all notifications and sponsored content
          "--disable-features=BraveRewards"
          "--disable-brave-ads-ntp-reconcile"
          # Additional privacy flags
          "--disable-background-networking"
          "--disable-breakpad"
        ];
      };
    };
  };
}
