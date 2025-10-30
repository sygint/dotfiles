{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.programs.brave;
in
{
  options.modules.programs.brave.enable = mkEnableOption "Brave web browser";

  config = mkIf cfg.enable {
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
      ];
    };
  };
}
