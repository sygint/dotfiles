#!/usr/bin/env bash
# Script to generate modules/system/all.nix from modules filesystem
set -euo pipefail
root="$(dirname "$0")/.."
modules_dir="$root/modules/system"
out="$modules_dir/all.nix"

# Find .nix files under modules/system (excluding default.nix and .conf.nix)
files=$(find "$modules_dir" -name '*.nix' -type f | grep -v '/default.nix$' | grep -v '\.conf\.nix$' | grep -v '/all.nix$' | sort)

cat > "$out" <<'EOF'
[
EOF
for f in $files; do
  # Convert to flake path (inputs.self + "/path")
  rel=${f#$root/}
  echo "  inputs.self + \"/$rel\"" >> "$out"
done

echo "\n  # Add additional modules here in preferred order\n]" >> "$out"

echo "Generated $out with $(wc -l < <(echo "$files")) modules"
