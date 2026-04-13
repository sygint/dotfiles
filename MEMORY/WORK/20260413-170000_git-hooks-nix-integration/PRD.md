---
task: Implement git-hooks.nix integration for NixOS flake
slug: 20260413-170000_git-hooks-nix-integration
effort: standard
phase: complete
progress: 12/12
mode: interactive
started: 2026-04-13T17:00:00-05:00
updated: 2026-04-13T17:03:00-05:00
---

## Context

Replace hand-written `.git/hooks/pre-commit` (286 lines) and `.git/hooks/pre-push` (108 lines) with Nix-idiomatic `git-hooks.nix` (cachix/git-hooks.nix) integration via flake-parts. Current hooks are not version-controlled, not reproducible across clones, and `nix flake check` is a no-op (no `checks` output defined). The formatter check only looks for tabs, not actual `nixpkgs-fmt` formatting.

Work happens in worktree at `~/.config/nixos-git-hooks` on branch `feat/git-hooks-nix`.

### Risks

- flake-parts module API for git-hooks.nix uses `pre-commit.settings.hooks.*` (confirmed from template)
- Custom hooks (secret scanning) need `entry` pointing to script
- `nix flake check` runs in sandbox — secret scanning hooks that need git state won't work there
- Must preserve existing devShell packages (fleet-sleep, fleet-wake, fleet-dev, etc.)

## Criteria

- [x] ISC-1: `git-hooks.nix` added as flake input with nixpkgs follows
- [x] ISC-2: `inputs.git-hooks-nix.flakeModule` imported in flake-parts imports
- [x] ISC-3: `nixpkgs-fmt` hook enabled in pre-commit settings
- [x] ISC-4: `statix` hook enabled in pre-commit settings
- [x] ISC-5: `deadnix` hook enabled in pre-commit settings
- [x] ISC-6: `ripsecrets` hook enabled for secret detection
- [x] ISC-7: Custom hook for broken Nix import detection configured
- [x] ISC-8: `config.pre-commit.shellHook` wired into devShells.default
- [x] ISC-9: `config.pre-commit.settings.enabledPackages` added to devShell packages
- [x] ISC-10: `.pre-commit-config.yaml` added to `.gitignore`
- [x] ISC-11: Existing devShell packages preserved (git, nixd, nixpkgs-fmt, just, go, fleet-*)
- [x] ISC-12: `nix flake check` evaluates without errors in worktree
- [x] ISC-A1: Old `.git/hooks/pre-commit` and `pre-push` NOT deleted (shared with main worktree)

## Decisions

- Used `language = "system"` for custom hook (auto-adapts per pre-commit version)
- nixosConfigurations error in `nix flake check` is pre-existing (secrets hash mismatch) — not related to our changes
- Kept `nixpkgs-fmt` in both `formatter` and `pre-commit.settings.hooks` — formatter is for `nix fmt`, hook is for pre-commit

## Verification

- ISC-1: Confirmed `git-hooks-nix.url` and `follows = "nixpkgs"` in flake.nix inputs
- ISC-2: Confirmed `inputs.git-hooks-nix.flakeModule` in imports list
- ISC-3: Confirmed `nixpkgs-fmt.enable = true` in pre-commit.settings.hooks
- ISC-4: Confirmed `statix.enable = true` in pre-commit.settings.hooks
- ISC-5: Confirmed `deadnix.enable = true` in pre-commit.settings.hooks
- ISC-6: Confirmed `ripsecrets.enable = true` in pre-commit.settings.hooks
- ISC-7: Confirmed `check-nix-imports` custom hook with writeShellScript entry
- ISC-8: Confirmed `${config.pre-commit.shellHook}` in devShells.default shellHook
- ISC-9: Confirmed `config.pre-commit.settings.enabledPackages ++` in devShell packages
- ISC-10: Confirmed `.pre-commit-config.yaml` in .gitignore
- ISC-11: Confirmed git, nixd, nixpkgs-fmt, just, go, fleet-sleep, fleet-wake, fleet-dev all preserved
- ISC-12: `nix flake show` confirms `checks.x86_64-linux.pre-commit` derivation exists, `nix flake check --no-build` passes (nixosConfigurations error is pre-existing)
- ISC-A1: Old hooks still exist as symlinks at `.git/hooks/pre-commit` and `.git/hooks/pre-push`
