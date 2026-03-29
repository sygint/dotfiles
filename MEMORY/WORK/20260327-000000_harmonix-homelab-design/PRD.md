---
task: Design harmonix homelab manager
slug: 20260327-000000_harmonix-homelab-design
effort: extended
phase: complete
progress: 16/16
mode: interactive
started: 2026-03-27T00:00:00Z
updated: 2026-03-27T00:00:00Z
---

## Context

**What is this?** A homelab management tool called "harmonix" to manage multiple HP/Mini PCs and other machines with secrets management, config deployment, and orchestration.

**Why it matters:** User wants to avoid "screwing up and rotating credentials wrong" - security-first approach to homelab management. Also wants to dogfood the tool during development.

**Hardware:**
- Intel i7 12700k + RTX 5090 + 64GB (Gaming/AI)
- AMD 5900x + RTX 3080 + 64GB (Homelab/AI)
- Ryzen 5 3600x + 40GB + GPU (Homelab/Streaming)
- HP EliteDesk G3 6500t (Worker - needs RAM)
- HP EliteDesk G4 8500t + 32GB (Worker)
- Framework 13 laptop (Workstation)

**Key constraints:**
- Nix-first approach - define everything in Nix/Flakes
- Split repo model: public configs + private secrets repo
- Pull-based by default, push for emergencies
- Community contribution is important
- Full verification before trusting with real secrets

## Criteria

- [x] ISC-1: Architecture document with component diagram created
- [x] ISC-2: Secrets management workflow defined (create, assign, verify, rotate, rollback)
- [x] ISC-3: Tiered secrets strategy documented
- [x] ISC-4: Machine registry and discovery mechanism defined
- [x] ISC-5: Pull-based deployment flow documented
- [x] ISC-6: Push capability for emergency/provisioning documented
- [x] ISC-7: MVP phases prioritized with scope
- [x] ISC-8: Dogfooding strategy defined
- [x] ISC-9: Public/private repo structure documented
- [x] ISC-10: Verification/testing strategy for secrets defined
- [x] ISC-11: Community contribution path considered
- [x] ISC-12: Integration points with sops-nix/age-nix documented
- [x] ISC-13: Machine lifecycle (provision, update, decomission) defined
- [x] ISC-14: Authentication mechanism for pull/push defined
- [x] ISC-15: Rollback strategy for failed deployments
- [x] ISC-16: Nix flake outputs structure designed

## Decisions

**Architectural Approach:** Flake-centric with controller pattern for orchestration

**Secrets Strategy:** Tiered (Global → Type → Per-machine)

**Pull Model:** Git-based with deploy keys, machines clone private repo

**Push Model:** Signed flakes for verification, SSH-based for emergency

## Verification

- All 16 ISC criteria completed
- Full spec document created at harmonix-spec.md
- Covers: architecture, secrets strategy, machine lifecycle, repo structure, MVP phases
- User confirmed ready to start implementation
