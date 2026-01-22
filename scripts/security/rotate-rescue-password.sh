#!/usr/bin/env bash
# Rotate the rescue (console) user password and update the sops-nix secret
# Usage: ./rotate-rescue-password.sh <host> [user]
# Example: ./rotate-rescue-password.sh nexus

set -euo pipefail

HOST="${1:-}"
USER="${2:-rescue}"

if [[ -z "$HOST" ]]; then
  echo "Usage: $0 <host> [user]"
  exit 1
fi

# Generate a strong password
tmp_pw=$(openssl rand -base64 32)
echo "[INFO] Generated password for $USER: $tmp_pw"

# Hash the password for NixOS (using mkpasswd if available, else python)
if command -v mkpasswd >/dev/null 2>&1; then
  hash=$(mkpasswd -m sha-512 "$tmp_pw")
else
  hash=$(python3 -c "import crypt, getpass; print(crypt.crypt('$tmp_pw', crypt.mksalt(crypt.METHOD_SHA512)))")
fi

# Update the sops secret file (assumes sops-nix/age and correct path)
SECRET_PATH="../nixos-secrets/secrets.yaml"
SECRET_KEY="$HOST.rescue_password_hash"

# Insert or update the secret in the YAML file
if grep -q "^$SECRET_KEY:" "$SECRET_PATH"; then
  sed -i "s|^$SECRET_KEY:.*|$SECRET_KEY: '$hash'|" "$SECRET_PATH"
else
  echo "$SECRET_KEY: '$hash'" >> "$SECRET_PATH"
fi

echo "[INFO] Updated $SECRET_KEY in $SECRET_PATH"

echo "[INFO] Now re-encrypt secrets and redeploy to apply the new password."
echo "[INFO] Store this password securely: $tmp_pw"

# Optionally, copy password to clipboard (Linux only)
if command -v xclip >/dev/null 2>&1; then
  echo -n "$tmp_pw" | xclip -selection clipboard
  echo "[INFO] Password copied to clipboard."
fi
