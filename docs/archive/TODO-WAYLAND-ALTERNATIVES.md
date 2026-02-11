# TODO: Explore Alternative Wayland Compositors and Shells

**Date Created**: 2026-01-22  
**Status**: Research Phase  
**Priority**: Low (Exploratory)

---

## Overview

Explore modern Wayland compositors and shell frameworks as potential alternatives or complements to the current Hyprland setup. Focus on innovative UI/UX approaches and unique features.

---

## Projects to Evaluate

### 1. Niri
**Repository**: https://github.com/YaLTeR/niri  
**Type**: Scrollable-tiling Wayland compositor

#### Key Features
- Scrollable tiling: windows arranged in columns that can be scrolled infinitely
- Written in Rust
- Inspired by PaperWM (GNOME Shell extension)
- Dynamic workspaces
- Built on Smithay (Wayland compositor library)

#### Why Interesting
- Novel window management paradigm (horizontal scrolling instead of traditional tiling)
- Modern Rust codebase
- Might suit ultra-wide displays well
- Different mental model from Hyprland's traditional tiling

#### Questions to Answer
- [ ] How does scrollable tiling compare to traditional tiling for productivity?
- [ ] Does it work well with multi-monitor setups?
- [ ] What's the learning curve compared to Hyprland?
- [ ] Is it stable enough for daily use?
- [ ] Does it have feature parity with Hyprland (animations, blur, etc.)?

#### NixOS Integration
- [ ] Check nixpkgs for `niri` package availability
- [ ] Look for existing NixOS modules or flakes
- [ ] Assess configuration approach (config files vs NixOS options)

---

### 2. Noctalia Shell
**Repository**: (Need to verify exact project)  
**Type**: Desktop shell/environment

#### Research Needed
- [ ] Find official repository/documentation
- [ ] Determine project status (active/abandoned)
- [ ] Identify key differentiators
- [ ] Check if it's a full compositor or just a shell layer
- [ ] Verify Wayland compatibility

#### Questions
- [ ] Is this a complete desktop environment or modular shell?
- [ ] What compositor does it use (or is it its own)?
- [ ] Target audience/use case?

---

### 3. QuickShell
**Repository**: https://git.outfoxxed.me/outfoxxed/quickshell  
**Type**: QtQuick-based Wayland shell toolkit

#### Key Features
- Uses QtQuick/QML for shell components
- Modular approach to building custom shells
- Declarative UI with QML
- Hot-reloadable configurations
- Compositor-agnostic (works with any wlroots-based compositor)

#### Why Interesting
- Similar concept to Ags (Aylur's GTK Shell) but with Qt instead of GTK
- QML provides powerful UI capabilities
- Could create custom bars, panels, widgets with familiar tech stack
- Hot-reload during development

#### Questions to Answer
- [ ] How mature is the project?
- [ ] Performance compared to Waybar/Ags?
- [ ] What's the learning curve for QML?
- [ ] Can it integrate with existing Hyprland setup?
- [ ] Does it have good documentation/examples?

#### Use Cases
- Custom status bars with rich widgets
- Dynamic notification systems
- App launchers with custom UIs
- System monitors with data visualization

#### NixOS Integration
- [ ] Check if packaged in nixpkgs
- [ ] Look for community flakes
- [ ] Assess if it can be packaged easily
- [ ] Test alongside current Waybar setup

---

### 4. Mangowc (Mango Wayland Compositor)
**Repository**: (Need to verify - possibly MangoHud related or separate project)  
**Type**: Unclear - needs research

#### Research Needed
- [ ] Verify this is a real project (might be confused with MangoHud?)
- [ ] Find official repository
- [ ] Determine scope and goals
- [ ] Check project status and activity
- [ ] Identify if related to MangoHud (performance overlay tool)

#### Possibilities
- Could be a performance-focused compositor?
- Might be a gaming-oriented Wayland compositor?
- May have special integration with MangoHud overlay?

**Note**: This needs immediate clarification - searching for "mangowc" yields unclear results. Might need to:
- Check if this was a typo or misremembered name
- Look for similar-sounding projects
- Verify in Wayland compositor listings

---

## Evaluation Criteria

When testing each project, assess:

### Technical
- [ ] **Stability**: Crash frequency, memory leaks, performance
- [ ] **Feature completeness**: Gaps compared to Hyprland
- [ ] **Performance**: Frame times, latency, resource usage
- [ ] **Multi-monitor support**: How well does it handle multiple displays?
- [ ] **HiDPI support**: Scaling on mixed-DPI setups

### Usability
- [ ] **Configuration**: Declarative vs imperative, restart required?
- [ ] **Keybindings**: Flexibility, conflicts with existing muscle memory
- [ ] **Customization**: Theming, plugins, extensibility
- [ ] **Documentation**: Quality, completeness, examples

### Ecosystem
- [ ] **NixOS integration**: Packaged? Module available? Flake support?
- [ ] **Community**: Active development, responsive maintainers
- [ ] **Compatibility**: Works with existing tools (Waybar, rofi, etc.)

### Migration
- [ ] **Learning curve**: Time to productivity
- [ ] **Config migration**: Can existing configs be adapted?
- [ ] **Fallback plan**: Easy to revert to Hyprland?

---

## Testing Strategy

### Phase 1: Research (1-2 hours per project)
1. Read documentation and READMEs
2. Watch demo videos/screenshots
3. Check issue trackers for known problems
4. Review NixOS community discussions
5. Assess project health (last commit, release cadence)

### Phase 2: VM Testing (2-4 hours per project)
1. Set up test VM with minimal NixOS config
2. Install compositor/shell
3. Test basic functionality
4. Document pain points and highlights
5. Screenshot/record interesting features

### Phase 3: Evaluation (1 hour per project)
1. Score against evaluation criteria
2. Document pros/cons vs Hyprland
3. Identify potential integration opportunities
4. Decide: adopt, integrate partially, or skip

### Phase 4: Integration (if promising)
1. Create feature module in `modules/features/`
2. Add to appropriate system (Orion for testing)
3. Run in parallel with Hyprland for comparison
4. Iterate on configuration

---

## Current Stack Context

### What We Use Now
- **Compositor**: Hyprland (feature-rich, animated, tiling)
- **Bar**: Waybar (customizable, well-integrated)
- **Launcher**: Rofi (Wayland fork)
- **Notifications**: Mako
- **Lock screen**: Hyprlock
- **Idle management**: Hypridle

### Integration Considerations
- Can new tools work alongside Hyprland? (e.g., QuickShell replacing Waybar)
- Do we need to replace entire compositor or just components?
- Will existing keybindings/workflows transfer?
- How much config work is required?

---

## Success Criteria

A project is worth deeper integration if it:

1. **Solves a current pain point** or provides meaningful improvement
2. **Maintains stability** (no frequent crashes or data loss)
3. **Has active development** (commits in last 3 months)
4. **Integrates with NixOS** (packaged or easily packageable)
5. **Offers unique value** (not just "different but equal")

---

## Resources

### General Wayland Resources
- [Awesome Wayland](https://github.com/natpen/awesome-wayland) - Curated list
- [Are We Wayland Yet?](https://arewewaylandyet.com/) - Compatibility tracker
- [Wayland Book](https://wayland-book.com/) - Protocol deep dive

### Community
- r/Hyprland - May have comparison discussions
- r/NixOS - NixOS-specific integration help
- Various project Discord servers (check each repo)

### Testing Infrastructure
- Use `systemd-nspawn` or VMs for isolated testing
- Keep Hyprland as default, test alternatives in secondary sessions
- Document configs in `modules/features/` even if not enabled

---

## Next Steps

1. **Immediate** (30 min):
   - [ ] Verify "mangowc" is the correct project name
   - [ ] Find correct URLs for all projects
   - [ ] Check nixpkgs for existing packages: `nix search nixpkgs niri quickshell`

2. **This Week** (2-4 hours):
   - [ ] Phase 1 research for Niri (most promising based on initial interest)
   - [ ] Phase 1 research for QuickShell (could complement Hyprland)

3. **This Month** (4-8 hours):
   - [ ] VM testing for 1-2 most promising options
   - [ ] Document findings in this file
   - [ ] Create feature module if something is production-ready

4. **Future**:
   - [ ] Consider blog post or documentation comparing options
   - [ ] Share findings with NixOS community
   - [ ] Contribute nixpkgs packages if needed

---

## Notes

- This is exploratory research, not a commitment to switch
- Hyprland is working well; this is about learning alternatives
- May discover tools useful for specific systems (e.g., kiosk on Nexus, minimal shell on Axon)
- QuickShell might be most immediately useful (custom widgets without changing compositor)

---

## Updates

**2026-01-22**: Initial research doc created. Need to verify project URLs and start Phase 1 research.
