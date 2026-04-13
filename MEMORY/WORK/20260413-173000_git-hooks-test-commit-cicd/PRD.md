---
task: Test git-hooks, commit, push, plan CI/CD strategy
slug: 20260413-173000_git-hooks-test-commit-cicd
effort: standard
phase: observe
progress: 0/10
mode: interactive
started: 2026-04-13T17:30:00-05:00
updated: 2026-04-13T17:31:00-05:00
---

## Context

Git-hooks.nix integration was just implemented on `feat/git-hooks-nix` branch in worktree `~/.config/nixos-git-hooks`. Changes: flake.nix (git-hooks-nix input, hooks config, devShell wiring), .gitignore (.pre-commit-config.yaml), flake.lock. Need to test, commit, push to Forgejo, then plan CI/CD strategy.

Infrastructure: Forgejo on cortex (`git.cortex.home:3022`), remote name `cortex`. Buildbot-nix planned (PR-21 in merge plan) but not yet deployed — it's commented out on nexus. Forgejo Actions explicitly disabled in favor of buildbot-nix.

### Risks

- `nix develop` may be slow (first time building hook packages)
- Pre-commit hooks may conflict with old `.git/hooks/` symlinks (both would fire)
- Push to cortex needs forgejo SSH key working

## Criteria

- [ ] ISC-1: `nix develop` enters devShell without errors in worktree
- [ ] ISC-2: Pre-commit hooks auto-install on devShell entry
- [ ] ISC-3: All changes committed with conventional commit message
- [ ] ISC-4: Branch pushed to cortex remote successfully
- [ ] ISC-5: Old `.git/hooks/` scripts moved to `scripts/legacy-hooks/`
- [ ] ISC-6: CI/CD strategy document written with local vs CI split
- [ ] ISC-7: Document specifies which hooks run locally (pre-commit)
- [ ] ISC-8: Document specifies which checks run in CI (host builds)
- [ ] ISC-9: Document covers buildbot-nix integration approach
- [ ] ISC-10: Document covers Forgejo webhook configuration needed

## Decisions

## Verification
