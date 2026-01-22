# PRD-001: Legacy Code & Documentation Cleanup

**Product Requirements Document**  
**Project:** NixOS Fleet Configuration Repository Modernization  
**Created:** December 3, 2025  
**Status:** Draft  
**Author:** AI-Assisted Analysis

---

## Executive Summary

This PRD defines the requirements for cleaning up legacy code, scripts, and documentation from the NixOS fleet configuration repository. The project has evolved through several major tooling migrations:

1. **Pre-nixos-secrets era** → Manual secrets handling
2. **Pre-devenv-bootstrap era** → Ad-hoc dev environments  
3. **Pre-nixos-fleet era** → Local fleet scripts in `scripts/fleet/`

The goal is to remove obsolete code, update documentation to reflect current workflows, and establish a clean, maintainable codebase.

---

## Table of Contents

1. [Background & Context](#background--context)
2. [Current State Analysis](#current-state-analysis)
3. [Legacy Components Inventory](#legacy-components-inventory)
4. [Migration Mapping](#migration-mapping)
5. [Requirements](#requirements)
6. [Implementation Plan](#implementation-plan)
7. [Acceptance Criteria](#acceptance-criteria)
8. [Risks & Mitigations](#risks--mitigations)

---

## Background & Context

### Project Evolution

This NixOS configuration repository manages a fleet of systems:
- **Orion** - Framework 13 laptop (primary workstation)
- **Cortex** - AI/Gaming rig with RTX 5090
- **Nexus** - Server system
- **Axon** - HTPC system

### Key Migrations Completed

| Migration | From | To | Status |
|-----------|------|-----|--------|
| Fleet Management | `scripts/fleet/*` local scripts | `nixos-fleet` standalone flake | ✅ Migrated |
| Secrets Management | Manual/ad-hoc | `nixos-secrets` flake input + sops-nix | ✅ Migrated |
| Dev Environment | Various shell.nix files | `devenv-bootstrap` flake | ✅ Migrated |
| Deployment | Manual scripts | Colmena + deploy-rs | ✅ Migrated |

### Current Flake Inputs (Source of Truth)

From `flake.nix`:
```nix
inputs = {
  nixos-fleet.url = "path:/home/syg/Projects/open-source/nixos-fleet";
  nixos-secrets.url = "path:/home/syg/.config/nixos-secrets";
  devenv-bootstrap.url = "path:/home/syg/Projects/open-source/devenv-bootstrap";
  sops-nix.url = "github:Mic92/sops-nix";
  colmena.url = "github:zhaofengli/colmena";
  deploy-rs.url = "github:serokell/deploy-rs";
  disko.url = "github:nix-community/disko";
  # ... other inputs
};
```

---

## Current State Analysis

### Documentation Files

| File | Status | Issues |
|------|--------|--------|
| `BOOTSTRAP.md` | 🟡 Partially Updated | References legacy `scripts/fleet.sh`, outdated "October 29, 2025" date |
| `FLEET-MANAGEMENT.md` | 🟡 Partially Updated | Still references local `./scripts/fleet.sh`, inconsistent with nixos-fleet migration |
| `docs/PROJECT-OVERVIEW.md` | 🟡 Outdated | Repository structure section outdated, references `scripts/fleet.sh` |
| `docs/ARCHITECTURE.md` | 🟢 Current | Module architecture still valid |
| `docs/archive/ANALYSIS-SUMMARY.md` | 📁 Archive | Historical analysis, should remain archived |
| `SECRETS.md` | 🔍 Needs Review | May reference pre-nixos-secrets patterns |
| `ISSUES.md` | 🟢 Current | Active issue tracker |
| `README.md` | 🔍 Needs Review | Entry point - must be accurate |
| `COLMENA-INTEGRATION.md` | 🟢 Current | Colmena is active deployment tool |
| `DEPLOYMENT-PAINPOINTS.md` | 📁 Should Archive | Historical context, pre-migration |
| `COMMIT-PLAN.md` | 📁 Should Archive | One-time planning doc |
| `JUSTFILE-MIGRATION.md` | 📁 Should Archive | Migration complete |

### Scripts Directory Analysis

```
scripts/
├── bootstrap/              # ✅ KEEP - Still used for fresh installs
│   ├── bootstrap-automated.sh
│   ├── bootstrap-nixos.sh
│   └── devenv-bootstrap/   # 🔍 REVIEW - May be superseded by flake
├── deployment/             # 🟡 PARTIAL KEEP
│   ├── safe-deploy.sh      # ✅ KEEP - Useful wrapper
│   ├── pre-flight.sh       # ✅ KEEP - Useful wrapper
│   ├── validate.sh         # ✅ KEEP - Useful wrapper
│   ├── bootstrap-system.sh # 🔍 REVIEW - Duplicate of bootstrap/?
│   └── archive/            # 📁 KEEP AS ARCHIVE
│       ├── check-system.sh.archived
│       └── fleet.sh.archived
├── fleet/                  # ❌ REMOVE or 📁 ARCHIVE - Migrated to nixos-fleet
│   └── exec                # Legacy fleet helper
├── browser/                # ✅ KEEP - Desktop utilities
├── desktop/                # ✅ KEEP - Desktop utilities
├── development/            # ✅ KEEP - Dev utilities
├── network/                # ✅ KEEP - Network utilities
├── power/                  # ✅ KEEP - Power utilities
├── security/               # ✅ KEEP - Security utilities
├── testing/                # ✅ KEEP - Testing utilities
├── secrets-manager.sh      # 🔍 REVIEW - May be superseded by nixos-secrets
├── focalboard-cli.sh       # ✅ KEEP - App utility
├── vikunja-cli.sh          # ✅ KEEP - App utility
└── todo.sh                 # ✅ KEEP - Personal utility
```

### Root-Level Files

| File | Status | Action |
|------|--------|--------|
| `flake.nix` | ✅ Current | Source of truth |
| `flake.lock` | ✅ Current | Lock file |
| `justfile` | ✅ Current | Active task runner |
| `fleet-config.nix` | ✅ Current | Fleet topology |
| `devenv.nix` | 🔍 Review | May be superseded by devenv-bootstrap |
| `shell.nix` | 🔍 Review | May be superseded by devenv-bootstrap |
| `DEPLOYMENT-PAINPOINTS.md` | 📁 Archive | Historical |
| `COMMIT-PLAN.md` | 📁 Archive | Historical |
| `JUSTFILE-MIGRATION.md` | 📁 Archive | Migration complete |
| `TASKS.md` | 🔍 Review | May be outdated |
| `notes.txt` | Personal | Keep or remove |
| `copilot.json` | ✅ Keep | AI config |

---

## Legacy Components Inventory

### Tier 1: Remove/Archive (Migrated to External Flakes)

| Component | Location | Migrated To | Action |
|-----------|----------|-------------|--------|
| Fleet scripts | `scripts/fleet/*` | `nixos-fleet` flake | Archive to `scripts/fleet.archived/` |
| Fleet shell | `scripts/deployment/fleet.sh` | `nixos-fleet` flake | Already archived |
| Check system | `scripts/deployment/check-system.sh` | `nixos-fleet` flake | Already archived |

### Tier 2: Review for Redundancy

| Component | Location | Potential Replacement | Action |
|-----------|----------|----------------------|--------|
| `devenv.nix` | Root | `devenv-bootstrap` flake | Review - may still be useful for quick `nix-shell` |
| `shell.nix` | Root | `devenv-bootstrap` flake | Review - may still be useful |
| `secrets-manager.sh` | `scripts/` | `nixos-secrets` workflow | Review - check if still needed |
| `scripts/bootstrap/devenv-bootstrap/` | Nested dir | `devenv-bootstrap` flake | Remove if duplicate |

### Tier 3: Documentation Updates Required

| Document | Issues | Updates Needed |
|----------|--------|----------------|
| `BOOTSTRAP.md` | References `scripts/fleet.sh` | Update to nixos-fleet CLI |
| `FLEET-MANAGEMENT.md` | References local fleet scripts | Major rewrite for nixos-fleet |
| `PROJECT-OVERVIEW.md` | Outdated structure, references legacy scripts | Update repository structure section |
| `README.md` | May reference legacy workflows | Full review needed |
| `SECRETS.md` | May reference pre-sops patterns | Review for nixos-secrets |

### Tier 4: Archive (Historical Value Only)

| Document | Reason | Action |
|----------|--------|--------|
| `DEPLOYMENT-PAINPOINTS.md` | Pre-migration historical context | Move to `docs/archive/` |
| `COMMIT-PLAN.md` | One-time planning document | Move to `docs/archive/` |
| `JUSTFILE-MIGRATION.md` | Migration complete | Move to `docs/archive/` |
| `docs/archive/ANALYSIS-SUMMARY.md` | Already archived | Keep in archive |

---

## Migration Mapping

### Fleet Management Commands

| Legacy Command | New Command | Notes |
|----------------|-------------|-------|
| `./scripts/fleet.sh list` | `nix run github:sygint/nixos-fleet#fleet -- list` | Or `just list` |
| `./scripts/fleet.sh build <host>` | `nix run github:sygint/nixos-fleet#fleet -- build <host>` | Or `just build <host>` |
| `./scripts/fleet.sh check <host>` | `nix run github:sygint/nixos-fleet#fleet -- check <host>` | Or `just check <host>` |
| `./scripts/fleet.sh update <host>` | `nix run github:sygint/nixos-fleet#fleet -- update <host>` | Or `just push <host>` |
| `./scripts/fleet.sh exec <host>` | `nix run github:sygint/nixos-fleet#fleet -- exec <host>` | Or `just ssh <host>` |

### Secrets Management Commands

| Legacy Pattern | New Pattern | Notes |
|----------------|-------------|-------|
| Manual age key handling | `nixos-secrets` flake input | Automatic via sops-nix |
| `../nixos-secrets/` relative path | `inputs.nixos-secrets` flake input | Declarative |
| Manual `.sops.yaml` editing | Still manual, but integrated | Works with bootstrap scripts |

### Dev Environment

| Legacy Pattern | New Pattern | Notes |
|----------------|-------------|-------|
| `nix-shell devenv.nix` | `nix develop github:sygint/devenv-bootstrap` | Or keep local for convenience |
| `nix-shell shell.nix` | `nix develop` | Default flake devShell |

---

## Requirements

### R1: Code Cleanup

| ID | Requirement | Priority |
|----|-------------|----------|
| R1.1 | Archive `scripts/fleet/` directory to `scripts/fleet.archived/` | High |
| R1.2 | Remove or archive `scripts/bootstrap/devenv-bootstrap/` if duplicate | Medium |
| R1.3 | Review and update `secrets-manager.sh` or archive if obsolete | Medium |
| R1.4 | Clean up any remaining references to legacy fleet scripts in codebase | High |

### R2: Documentation Updates

| ID | Requirement | Priority |
|----|-------------|----------|
| R2.1 | Update `BOOTSTRAP.md` to remove legacy script references | High |
| R2.2 | Rewrite `FLEET-MANAGEMENT.md` for nixos-fleet CLI | High |
| R2.3 | Update `PROJECT-OVERVIEW.md` repository structure section | Medium |
| R2.4 | Review and update `README.md` for accuracy | High |
| R2.5 | Review `SECRETS.md` for nixos-secrets patterns | Medium |
| R2.6 | Archive historical docs to `docs/archive/` | Low |

### R3: Consistency

| ID | Requirement | Priority |
|----|-------------|----------|
| R3.1 | All docs should reference `nixos-fleet` CLI as primary fleet tool | High |
| R3.2 | All docs should use consistent date format and "Last Updated" dates | Low |
| R3.3 | Remove or update any "TODO" items that are complete | Medium |
| R3.4 | Ensure justfile commands align with documented workflows | High |

### R4: Testing & Validation

| ID | Requirement | Priority |
|----|-------------|----------|
| R4.1 | Verify all documented commands work as described | High |
| R4.2 | Test bootstrap workflow end-to-end | Medium |
| R4.3 | Validate secrets workflow with sops-nix | Medium |

---

## Implementation Plan

### Phase 1: Inventory & Archive (Week 1)

- [ ] Create `scripts/fleet.archived/` directory
- [ ] Move `scripts/fleet/*` to archive
- [ ] Move `DEPLOYMENT-PAINPOINTS.md` to `docs/archive/`
- [ ] Move `COMMIT-PLAN.md` to `docs/archive/`
- [ ] Move `JUSTFILE-MIGRATION.md` to `docs/archive/`
- [ ] Review `scripts/bootstrap/devenv-bootstrap/` for removal

### Phase 2: Documentation Updates (Week 2)

- [ ] Update `BOOTSTRAP.md`
  - [ ] Remove references to `./scripts/fleet.sh`
  - [ ] Update "Last Updated" date
  - [ ] Verify nixos-fleet CLI examples work
- [ ] Rewrite `FLEET-MANAGEMENT.md`
  - [ ] Focus on nixos-fleet CLI as primary tool
  - [ ] Update all command examples
  - [ ] Remove references to local fleet scripts
- [ ] Update `PROJECT-OVERVIEW.md`
  - [ ] Update repository structure diagram
  - [ ] Remove references to `scripts/fleet.sh`
- [ ] Update `README.md`
  - [ ] Verify quick start commands
  - [ ] Update tool references

### Phase 3: Codebase Cleanup (Week 3)

- [ ] Search for and remove all references to legacy patterns:
  - [ ] `./scripts/fleet.sh`
  - [ ] `scripts/fleet/`
  - [ ] `packages/fleet-cli/` (if exists)
  - [ ] Pre-nixos-secrets patterns
- [ ] Update any inline comments referencing legacy tools
- [ ] Review justfile for consistency with docs

### Phase 4: Validation (Week 4)

- [ ] Test documented bootstrap workflow
- [ ] Test documented fleet management commands
- [ ] Test documented secrets workflow
- [ ] Verify all cross-references between docs are valid
- [ ] Final review of all changed files

---

## Acceptance Criteria

### AC1: No Legacy References
- [ ] `grep -r "scripts/fleet.sh"` returns no results (except archives)
- [ ] `grep -r "scripts/fleet/"` returns no results (except archives)
- [ ] `grep -r "../nixos-secrets"` returns no results in active docs (only in bootstrap scripts where needed)

### AC2: Documentation Accuracy
- [ ] All documented commands execute successfully
- [ ] All "Last Updated" dates reflect actual update date
- [ ] No broken internal links between documents

### AC3: Clean Directory Structure
- [ ] `scripts/fleet/` either archived or removed
- [ ] `scripts/fleet.archived/` contains legacy scripts (if keeping for reference)
- [ ] `docs/archive/` contains all historical-only documents

### AC4: Consistent Tooling References
- [ ] All docs reference `nixos-fleet` CLI for fleet operations
- [ ] All docs reference `nixos-secrets` flake for secrets
- [ ] Justfile commands match documented workflows

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking working workflows | High | Low | Test all documented workflows before finalizing |
| Losing historical context | Medium | Low | Archive rather than delete legacy components |
| Incomplete migration | Medium | Medium | Use grep/search to find all legacy references |
| Documentation drift | Medium | High | Establish single source of truth pattern |

---

## Appendix A: Files to Review

### Scripts to Review

```bash
# Check for legacy fleet references
grep -r "fleet.sh" scripts/
grep -r "scripts/fleet" .

# Check for legacy secrets patterns
grep -r "nixos-secrets" . --include="*.md"
grep -r "../nixos-secrets" .

# Check for devenv patterns
grep -r "devenv.nix" . --include="*.md"
grep -r "nix-shell" . --include="*.md"
```

### Documentation Cross-Reference Check

```bash
# Find all internal doc links
grep -r "\[.*\](.*\.md)" docs/
grep -r "\[.*\](.*\.md)" *.md

# Find all TODO items
grep -r "TODO\|FIXME\|- \[ \]" docs/ *.md
```

---

## Appendix B: Command Quick Reference

### Current (Post-Migration) Commands

```bash
# Fleet Management (nixos-fleet)
nix run github:sygint/nixos-fleet#fleet -- list
nix run github:sygint/nixos-fleet#fleet -- build <host>
nix run github:sygint/nixos-fleet#fleet -- check <host>
nix run github:sygint/nixos-fleet#fleet -- update <host>

# Or via justfile
just list
just build <host>
just check <host>
just push <host>

# Secrets (sops-nix + nixos-secrets)
just secrets edit
just secrets validate
just secrets rekey

# Bootstrap (still local scripts)
./scripts/bootstrap/bootstrap-automated.sh <hostname> <ip>
./scripts/bootstrap/bootstrap-nixos.sh -n <hostname> -d <destination>

# Dev Environment
nix develop  # Uses flake devShell
nix-shell devenv.nix  # Legacy but still works
```

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2025-12-03 | AI-Assisted | Initial draft |

---

**End of PRD**
