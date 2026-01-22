{
  description = "Smart project scaffolding for devenv with automatic language detection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        devenv-bootstrap = pkgs.stdenv.mkDerivation {
          pname = "devenv-bootstrap";
          version = "2.1.0";
          
          src = ./.;
          
          nativeBuildInputs = [ pkgs.makeWrapper ];
          
          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/share/devenv-bootstrap/templates
            
            cp devenv-bootstrap $out/bin/
            chmod +x $out/bin/devenv-bootstrap
            
            cp templates/*.nix $out/share/devenv-bootstrap/templates/
            
            # Set SCRIPT_DIR to point to where templates are located
            wrapProgram $out/bin/devenv-bootstrap \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.jq ]} \
              --set DEVENV_BOOTSTRAP_TEMPLATE_DIR $out/share/devenv-bootstrap/templates
          '';
          
          meta = with pkgs.lib; {
            description = "Smart project scaffolding for devenv";
            homepage = "https://github.com/sygint/devenv-bootstrap";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };
        
      in
      {
        packages = {
          default = devenv-bootstrap;
          devenv-bootstrap = devenv-bootstrap;
        };
        
        apps = {
          default = flake-utils.lib.mkApp {
            drv = devenv-bootstrap;
          };
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            coreutils
            jq
          ];
        };
      }
    );
}
