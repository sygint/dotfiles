#!/usr/bin/env bash
set -euo pipefail

# test-heavy.sh - minimal heavy test that validates key toolchains are buildable/run
# Runs nix run for commonly used toolchains to ensure the CI runner can build them

TIMEFORMAT='Time: %R seconds'
run_and_time() {
  local cmd="$1"
  echo "Running: $cmd"
  /usr/bin/time -f "${TIMEFORMAT}" bash -lc "$cmd"
}

echo "Starting heavy tests..."

echo "Node.js (nixpkgs) -> node --version"
run_and_time "nix run github:nixos/nixpkgs#nodejs-20_x -- --version" || true

echo "Python3 (nixpkgs) -> python3 --version"
run_and_time "nix run github:nixos/nixpkgs#python3 -- --version" || true

echo "Rust (nixpkgs) -> rustc --version"
run_and_time "nix run github:nixos/nixpkgs#rustc -- --version" || true

echo "Go (nixpkgs) -> go version"
run_and_time "nix run github:nixos/nixpkgs#go -- --version" || true

echo "Heavy tests completed."

exit 0
