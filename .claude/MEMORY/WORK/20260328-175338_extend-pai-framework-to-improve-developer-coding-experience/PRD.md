---
task: Extend PAI framework to improve developer coding experience
slug: 20260328-175338_extend-pai-framework-to-improve-developer-coding-experience
effort: standard
phase: observe
progress: 0/8
mode: interactive
started: 2026-03-28T10:53:38-07:00
updated: 2026-03-28T12:07:40-07:00

## Context

The user requested: "I wanna extend our PAI framework to improve the coding experience." Goal: identify and implement concrete improvements to developer tooling, feedback, and automation inside PAI to make coding faster, safer, and more delightful.

### Explicit wants
- Improve coding experience inside PAI

### Explicit not-wants
- No unrelated infra or ops changes unless required

### Implied wants and constraints
- Low friction developer feedback (linting, auto-fixes, suggestions)
- Better multi-file refactor support (batch, worktree isolation)
- Improved code reviews and security checks integrated into Algorithm flow
- Maintain Algorithm rules (PRD updates, voice calls, ISC gates)

## Criteria

- [ ] ISC-1: API for registering code-quality rules in PAI
- [ ] ISC-2: Integrated linter invocation in Build phase
- [ ] ISC-3: /batch orchestration for multi-file refactors documented
- [ ] ISC-4: Worktree isolation facility callable by agents
- [ ] ISC-5: Post-change /simplify review step integrated and invoked
- [ ] ISC-6: Security-review capability invoked automatically for changes
- [ ] ISC-7: PRD auto-update hooks verify progress updates
- [ ] ISC-8: Developer-facing CLI docs added for new features

### Risky assumptions
- Assuming repo tooling can call linters without adding heavy dependencies
- /simplify skill exists and can be invoked programmatically
- Agents have permission to create worktrees and run git operations

### Prerequisites check
- Confirm /simplify and /batch skills are available in skill index (they are listed in Algorithm.md)
- Identify a linter we can run cross-platform (eslint for JS/TS, golangci-lint for Go, shellcheck for shell)

## Decisions

Decisions will be documented here during Plan/Build.

### Plan

Goal: Implement integrated linter + /simplify invocation in Build/Execute, wire a CLI command and document usage.

Steps:
1. Add a new CLI command `pai code-lint` that detects project type and runs appropriate linters.
2. Integrate linter step into Algorithm BUILD phase by updating `PAI/Tools/algorithm.ts` to call the linter before code edits are committed.
3. After code changes, invoke `Skill("simplify")` to run the simplify review and append results to PRD Verification.
4. Add docs under `PAI/CLI.md` describing `pai code-lint` and how /simplify is used.
5. Update PRD progress as each ISC is satisfied.

Work allocation: I'll modify CLI and algorithm tools in this repo; keep changes minimal and configurable.

## Verification

Verification evidence will be added during Verify phase.
---
