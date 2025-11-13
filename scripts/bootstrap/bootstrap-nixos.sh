#!/usr/bin/env bash
set -euo pipefail

# Remotely installs NixOS on a target machine using this nix-config
# Adapted from EmergentMind/nix-config bootstrap script

# ==============================================================================
# UX Helpers
# ==============================================================================

function red() {
	echo -e "\x1B[31m[!] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[31m[!] $($2) \x1B[0m"
	fi
}

function green() {
	echo -e "\x1B[32m[+] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[32m[+] $($2) \x1B[0m"
	fi
}

function blue() {
	echo -e "\x1B[34m[*] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[34m[*] $($2) \x1B[0m"
	fi
}

function yellow() {
	echo -e "\x1B[33m[*] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[33m[*] $($2) \x1B[0m"
	fi
}

# Ask yes or no, with yes being the default
function yes_or_no() {
	echo -en "\x1B[34m[?] $* [y/n] (default: y): \x1B[0m"
	while true; do
		read -rp "" yn
		yn=${yn:-y}
		case $yn in
		[Yy]*) return 0 ;;
		[Nn]*) return 1 ;;
		esac
	done
}

# Ask yes or no, with no being the default
function no_or_yes() {
	echo -en "\x1B[34m[?] $* [y/n] (default: n): \x1B[0m"
	while true; do
		read -rp "" yn
		yn=${yn:-n}
		case $yn in
		[Yy]*) return 0 ;;
		[Nn]*) return 1 ;;
		esac
	done
}

# ==============================================================================
# User Variables
# ==============================================================================

target_hostname=""
target_destination=""
target_user=${BOOTSTRAP_USER-$(whoami)}
ssh_port=${BOOTSTRAP_SSH_PORT-22}
ssh_key=${BOOTSTRAP_SSH_KEY-}
persist_dir=""
nix_src_path="src/nix/" # path relative to /home/${target_user}
git_root=$(git rev-parse --show-toplevel)
nix_secrets_dir=${NIX_SECRETS_DIR:-"${git_root}"/../nixos-secrets}

# Create a temp directory for generated host keys
temp=$(mktemp -d)

# Cleanup temporary directory on exit
function cleanup() {
	rm -rf "$temp"
}
trap cleanup exit

# ==============================================================================
# Helper Functions
# ==============================================================================

# Copy data to the target machine
function sync() {
	# $1 = user, $2 = source, $3 = destination
	rsync -av --mkpath --filter=':- .gitignore' -e "ssh -oControlMaster=no -l $1 -oport=${ssh_port}" "$2" "$1@${target_destination}:${nix_src_path}"
}

# Usage function
function help_and_exit() {
	echo
	echo "Remotely installs NixOS on a target machine using this nix-config."
	echo
	echo "USAGE: $0 -n <target_hostname> -d <target_destination> -k <ssh_key> [OPTIONS]"
	echo
	echo "ARGS:"
	echo "  -n <target_hostname>                    specify target_hostname of the target host to deploy the nixos config on."
	echo "  -d <target_destination>                 specify ip or domain to the target host."
	echo "  -k <ssh_key>                            specify the full path to the ssh_key you'll use for remote access to the"
	echo "                                          target during install process."
	echo
	echo "OPTIONS:"
	echo "  -u <target_user>                        specify target_user with sudo access. nix-config will be cloned to their home."
	echo "                                          Default='syg'"
	echo "  --port <ssh_port>                       specify the ssh port to use for remote access. Default=22"
	echo "  --impermanence                          specify if the target machine has impermanence enabled"
	echo "  --temp-override <path>                  override the temp directory path. Useful if /tmp is small."
	echo "  --debug                                 enable debug mode"
	echo "  -h | --help                             show this help message"
	echo
	exit 0
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

while [ $# -gt 0 ]; do
	case "$1" in
	-n)
		shift
		target_hostname=$1
		;;
	-d)
		shift
		target_destination=$1
		;;
	-u)
		shift
		target_user=$1
		;;
	-k)
		shift
		ssh_key=$1
		;;
	--port)
		shift
		ssh_port=$1
		;;
	--temp-override)
		shift
		temp=$1
		;;
	--impermanence)
		persist_dir="/persist"
		;;
	--debug)
		set -x
		;;
	-h | --help) help_and_exit ;;
	*)
		red "ERROR: Invalid option detected."
		help_and_exit
		;;
	esac
	shift
done

if [ -z "$target_hostname" ] || [ -z "$target_destination" ] || [ -z "$ssh_key" ]; then
	red "ERROR: -n, -d, and -k are all required"
	echo
	help_and_exit
fi

# ==============================================================================
# SSH Command Setup
# ==============================================================================

ssh_cmd="ssh \
        -oControlPath=none \
        -oport=${ssh_port} \
        -oForwardAgent=yes \
        -oStrictHostKeyChecking=no \
        -oUserKnownHostsFile=/dev/null \
        -i $ssh_key \
        -t $target_user@$target_destination"

# shellcheck disable=SC2001
ssh_root_cmd=$(echo "$ssh_cmd" | sed "s|${target_user}@|root@|")
scp_cmd="scp -oControlPath=none -oport=${ssh_port} -oStrictHostKeyChecking=no -i $ssh_key"

# ==============================================================================
# Main Installation Function
# ==============================================================================

generated_hardware_config=0
function nixos_anywhere() {
	# Clear the known keys, since they should be newly generated for the iso
	green "Wiping known_hosts of $target_destination"
	ssh-keygen -R "$target_destination" -f ~/.ssh/known_hosts 2>/dev/null || true

	green "Installing NixOS on $target_hostname at $target_destination"

	# Check if disk-config.nix exists for this host
	disk_config="${git_root}/systems/${target_hostname}/disk-config.nix"
	if [ ! -f "$disk_config" ]; then
		red "ERROR: disk-config.nix not found at $disk_config"
		red "Please create a disk configuration for $target_hostname first"
		exit 1
	fi

	# Build the install flake
	green "Building nixos-anywhere configuration for $target_hostname"
	
	# Use nixos-anywhere to install
	if command -v nixos-anywhere &>/dev/null; then
		green "Running nixos-anywhere..."
		nixos-anywhere --flake ".#${target_hostname}" "root@${target_destination}" \
			--ssh-option "Port=${ssh_port}" \
			--ssh-option "IdentityFile=${ssh_key}" \
			--ssh-option "StrictHostKeyChecking=no"
	else
		red "ERROR: nixos-anywhere is not installed"
		red "Install with: nix-shell -p nixos-anywhere"
		exit 1
	fi

	green "Installation complete!"
	echo
}

# ==============================================================================
# Hardware Configuration Generation
# ==============================================================================

function generate_hardware_config() {
	green "Generating hardware-configuration.nix for $target_hostname"
	
	# Create the host directory if it doesn't exist
	mkdir -p "${git_root}/systems/${target_hostname}"
	
	# Generate hardware config from the target system
	$ssh_root_cmd "nixos-generate-config --no-filesystems --root /mnt" || {
		red "WARNING: Failed to generate hardware config on target"
		return 1
	}
	
	# Copy it back
	$scp_cmd "root@${target_destination}:/mnt/etc/nixos/hardware-configuration.nix" \
		"${git_root}/systems/${target_hostname}/hardware-configuration.nix" || {
		red "WARNING: Failed to copy hardware config"
		return 1
	}
	
	green "Hardware configuration generated at systems/${target_hostname}/hardware-configuration.nix"
	generated_hardware_config=1
	return 0
}

# ==============================================================================
# Age Key Management
# ==============================================================================

function sops_generate_host_age_key() {
	green "Generating host age key for $target_hostname"
	
	# Get the SSH host key from the target
	ssh_host_key="${temp}/ssh_host_ed25519_key.pub"
	$scp_cmd "root@${target_destination}:/etc/ssh/ssh_host_ed25519_key.pub" "$ssh_host_key" || {
		red "ERROR: Failed to get SSH host key from target"
		return 1
	}
	
	# Convert SSH key to age key
	if ! command -v ssh-to-age &>/dev/null; then
		red "ERROR: ssh-to-age not found. Install with: nix-shell -p ssh-to-age"
		return 1
	fi
	
	age_key=$(nix shell nixpkgs#ssh-to-age -c sh -c "cat '$ssh_host_key' | ssh-to-age")
	
	# Create the keys directory if it doesn't exist
	mkdir -p "${nix_secrets_dir}/keys/hosts"
	
	# Save the age key
	echo "$age_key" > "${nix_secrets_dir}/keys/hosts/${target_hostname}.txt"
	
	green "Host age key generated and saved to keys/hosts/${target_hostname}.txt"
	green "Age key: $age_key"
	
	# Update .sops.yaml if it exists
	if [ -f "${nix_secrets_dir}/.sops.yaml" ]; then
		yellow "Don't forget to add this key to your .sops.yaml creation_rules"
		yellow "  - &${target_hostname} ${age_key}"
	fi
	
	return 0
}

function sops_setup_user_age_key() {
	local user=$1
	local hostname=$2
	
	green "Setting up user age key for $user on $hostname"
	
	# Create age key directory on target
	$ssh_cmd "mkdir -p ~/.config/sops/age" || {
		red "ERROR: Failed to create age directory on target"
		return 1
	}
	
	# Generate user age key if it doesn't exist locally
	local user_key_file="${nix_secrets_dir}/keys/${user}-${hostname}.txt"
	if [ ! -f "$user_key_file" ]; then
		yellow "Generating new user age key"
		if ! command -v age-keygen &>/dev/null; then
			red "ERROR: age-keygen not found. Install with: nix-shell -p age"
			return 1
		fi
		age-keygen -o "$user_key_file"
		green "User age key generated at $user_key_file"
	fi
	
	# Copy the user key to the target
	$scp_cmd "$user_key_file" "${user}@${target_destination}:~/.config/sops/age/keys.txt" || {
		red "ERROR: Failed to copy user age key to target"
		return 1
	}
	
	green "User age key deployed to target"
	return 0
}

# ==============================================================================
# Main Execution Flow
# ==============================================================================

blue "Bootstrap Configuration:"
blue "  Target Host: $target_hostname"
blue "  Destination: $target_destination"
blue "  User: $target_user"
blue "  SSH Port: $ssh_port"
blue "  SSH Key: $ssh_key"
if [ -n "$persist_dir" ]; then
	blue "  Impermanence: enabled (${persist_dir})"
fi
echo

if yes_or_no "Run nixos-anywhere installation?"; then
	nixos_anywhere
fi

updated_age_keys=0
if yes_or_no "Generate host (ssh-based) age key?"; then
	sops_generate_host_age_key && updated_age_keys=1
fi

if yes_or_no "Generate hardware configuration?"; then
	generate_hardware_config
fi

if yes_or_no "Setup user age key?"; then
	sops_setup_user_age_key "$target_user" "$target_hostname" && updated_age_keys=1
fi

if [[ $updated_age_keys == 1 ]]; then
	yellow "Age keys have been updated. You may need to:"
	yellow "  1. Update .sops.yaml creation_rules in nix-secrets"
	yellow "  2. Run: cd ../nixos-secrets && sops updatekeys secrets.yaml"
	echo
fi

if yes_or_no "Sync nix-config to target?"; then
	green "Syncing nix-config to $target_hostname"
	sync "$target_user" "${git_root}" "$target_destination"
	
	if [ -d "$nix_secrets_dir" ]; then
		if yes_or_no "Sync nix-secrets to target?"; then
			sync "$target_user" "${nix_secrets_dir}" "$target_destination"
		fi
	fi
	
	if yes_or_no "Do you want to rebuild immediately?"; then
		green "Rebuilding nix-config on $target_hostname"
		$ssh_cmd "cd ${nix_src_path}nixos && sudo nixos-rebuild --impure --show-trace --flake .#$target_hostname switch"
	fi
else
	echo
	green "NixOS was successfully installed!"
	echo "Post-install config build instructions:"
	echo "To copy nix-config from this machine to the $target_hostname, run the following command"
	echo "  rsync -av ~/.config/nixos ${target_user}@${target_destination}:${nix_src_path}"
	echo "To rebuild, sign into $target_hostname and run the following command"
	echo "  cd ${nix_src_path}nixos"
	echo "  sudo nixos-rebuild --show-trace --flake .#$target_hostname switch"
	echo
fi

if [[ $generated_hardware_config == 1 ]]; then
	if yes_or_no "Do you want to commit the generated hardware-configuration.nix for $target_hostname to nix-config?"; then
		cd "$git_root"
		git add "systems/${target_hostname}/hardware-configuration.nix"
		git commit -m "feat(systems): add hardware config for ${target_hostname}"
		green "Hardware configuration committed"
	fi
fi

green "Bootstrap complete! 🚀"
