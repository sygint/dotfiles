{ config, lib, pkgs, ... }:

# Legacy wrapper: delegate implementation to the new namespaced `modules/features/ai`.
# This keeps the old `modules.features.ai-services` module path usable while the
# real implementation lives in `modules/features/ai` to avoid duplication.

let
  impl = import ../ai/ai.nix;
in impl { inherit config lib pkgs; }
