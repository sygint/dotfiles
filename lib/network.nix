# Network configuration helper library
# Provides convenient functions to access network-config.nix throughout your flake
{ lib ? (import <nixpkgs> {}).lib }:
let
  inherit (lib) mapAttrs attrNames;
  
  # Import the network configuration
  networkConfig = import ../network-config.nix;
  
  # Helper function to get host config by name
  # Usage: getHost "cortex"
  getHost = hostName: 
    networkConfig.hosts.${hostName} or (throw "Host '${hostName}' not found in network-config.nix");
  
  # Helper function to get SSH connection string
  # Usage: getSshTarget "cortex" => "jarvis@192.168.1.7"
  getSshTarget = hostName:
    let host = getHost hostName;
    in "${host.ssh.user}@${host.ip}";
  
  # Helper function to get full SSH command
  # Usage: getSshCommand "cortex" => "ssh jarvis@192.168.1.7"
  getSshCommand = hostName:
    let host = getHost hostName;
    in "ssh ${host.ssh.user}@${host.ip}";
  
  # Helper function to check if host has WoL enabled
  # Usage: hasWol "cortex" => true
  hasWol = hostName:
    let host = getHost hostName;
    in host.wol.enabled or false;
  
  # Helper function to get WoL MAC address
  # Usage: getWolMac "cortex" => "9c:6b:00:35:51:55"
  getWolMac = hostName:
    let host = getHost hostName;
    in if hasWol hostName
       then host.wol.mac
       else throw "Host '${hostName}' does not have Wake-on-LAN enabled";
  
  # Helper function to check if host is deployable
  # Usage: isDeployable "cortex" => true
  isDeployable = hostName:
    let host = getHost hostName;
    in host.deploy.enabled or false;
  
  # Helper function to get deploy configuration
  # Usage: getDeployConfig "cortex"
  getDeployConfig = hostName:
    let host = getHost hostName;
    in if isDeployable hostName
       then host.deploy
       else throw "Host '${hostName}' is not configured for deployment";
  
  # Get list of all deployable hosts
  # Usage: getDeployableHosts => [ "cortex" ]
  getDeployableHosts =
    builtins.filter (name: (getHost name).deploy.enabled or false) (attrNames networkConfig.hosts);
  
  # Get list of all hosts with WoL enabled
  # Usage: getWolHosts => [ "cortex" ]
  getWolHosts =
    builtins.filter (name: (getHost name).wol.enabled or false) (attrNames networkConfig.hosts);
  
  # Generate deploy-rs node configuration for a host
  # Usage: mkDeployNode "cortex"
  mkDeployNode = hostName: activatePath:
    let 
      host = getHost hostName;
      deployConfig = getDeployConfig hostName;
    in {
      hostname = host.ip;
      profiles.system = {
        path = activatePath;
        user = "root";
        sshUser = host.ssh.user;
        remoteBuild = deployConfig.remoteBuild or false;
      };
    };
in
{
  # Export the raw config
  inherit networkConfig;
  
  # Export helper functions
  inherit getHost;
  inherit getSshTarget getSshCommand;
  inherit hasWol getWolMac getWolHosts;
  inherit isDeployable getDeployConfig getDeployableHosts;
  inherit mkDeployNode;
  
  # Convenience exports
  network = networkConfig.network;
  hosts = networkConfig.hosts;
  hostNames = attrNames networkConfig.hosts;
}
