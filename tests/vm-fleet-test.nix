{ system ? "nexus" }:

let
  modulePath = ../systems/${system}/default.nix;
  # Get the actual flake inputs or provide a minimal mock
  flake = builtins.getFlake (toString ../.);
  testModule = import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }:
  {
    name = "${system}-vm-test";
    nodes = {
      testvm = { config, pkgs, lib, ... }: {
        imports = [
          (import modulePath { 
            inherit config pkgs lib;
            hasSecrets = true; 
            inputs = flake.inputs;
            isTest = true;  # Signal that this is a test environment
          })
        ];
        # Disable features that don't work well in test VMs
        modules.services.virtualization.enable = lib.mkForce false;
      };
    };
    testScript = ''
      start_all()
      testvm.wait_for_unit("multi-user.target")
      testvm.succeed("id deploy")
      testvm.succeed("sudo -n -u deploy true")
      testvm.succeed("sudo -l -U deploy | grep NOPASSWD")
      # Add more checks as needed
    '';
  });
in
(testModule {}).test
