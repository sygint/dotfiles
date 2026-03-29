---
task: Continue static security triage for harmonix CLI repository
slug: 20260329-153000_continue-static-security-triage
effort: standard
phase: observe
progress: 0/0
mode: interactive
started: 2026-03-29T15:30:00Z
updated: 2026-03-29T15:30:00Z
---
## Context

This session continues a focused security triage of the harmonix CLI repository to address gosec findings (G702/G304/G703/G204 etc.), keep changes minimal, and prepare a clean PR/CI state. The repo is a CLI that intentionally shells out and manipulates user paths; fixes should prefer input validation, permission tightening, or documented exceptions with justification.

What we did so far:
- Installed and ran gosec, staticcheck, golangci-lint; tests and go build succeeded.
- Applied small fixes for config/secret permissions; validated device/host inputs in `cmd/testing.go`; restricted `copyFile` in `cmd/helpers.go`.

Explicit wants:
- Reduce high-severity gosec findings (G702/G304/G703/G204) with minimal, non-behavioral fixes.
- Add CI check to run gosec/staticcheck/golangci-lint on PRs.
- Keep commits small and document any intentional exceptions with `// #nosec` and rationale.

Explicit not-wants:
- Large refactors that change CLI behavior.
- Reverting unrelated local changes in the worktree.

Implied constraints:
- Changes must be small, tested, and focused per-file; prefer validation over removing functionality.

## Effort Level

💪🏼 EFFORT LEVEL: standard | quick, focused triage and criteria-driven fixes

## Criteria

- [ ] ISC-1: `cmd/testing.go` validates device and host inputs before any exec.Command use
- [ ] ISC-2: `cmd/helpers.go` copyFile prevents cross-directory copies and rejects path traversal
- [ ] ISC-3: `cmd/secrets.go` writes secrets with 0600 and anchors age-key path to HOME
- [ ] ISC-4: `pkg/config/config.go` creates config directory 0750 and files 0600
- [ ] ISC-5: `cmd/main.go` loop-variable aliasing (G601) fixed to avoid memory alias bug
- [ ] ISC-6: `cmd/deployment.go` exec.Command calls using formatted strings are refactored to explicit arg slices or validated
- [ ] ISC-7: gosec scan reduced: no remaining high-severity G702/G304 findings without documented justification
- [ ] ISC-8: CI workflow added to run gosec, staticcheck, golangci-lint, go test -race, and go build on PRs

progress: 0/8

## Capabilities Selected

- Security (observe) — invoke Security skill now to surface focused mitigations and check best practices

## Decisions

No decisions yet. Small per-file fixes preferred; any remaining findings that cannot be safely changed will be documented with `// #nosec` and a short rationale.

## Verification

Will run gosec and linter suite after each small change and add evidence here for each satisfied ISC criterion.
