{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.brave;
in
{
  options.settings.programs.brave.enable = mkEnableOption "Brave web browser";

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
        # "hjdoplcnndgiblooccencgcggcoihigg" # Terms of Service; Didn’t Read
      ];
    };
  };
}
