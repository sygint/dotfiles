# Power & Idle Management

Scripts for managing system power states and idle behavior.

## Scripts

### dpms-off-if-locked.sh
Smart DPMS control that only turns off monitors when the screen is locked.

**Features:**
- Called automatically by hypridle
- Logs activity to systemd journal (viewable with `journalctl -t dpms-lock-aware`)
- Prevents monitors from turning off during active use
- Only activates when screen is actually locked

**Usage:**
```bash
./scripts/power/dpms-off-if-locked.sh
```

**Note:** This script is automatically called by hypridle. Manual invocation is rarely needed.

**Configuration:** See `modules/home/programs/hypridle.nix`

### check-idle-blockers.sh
Diagnostic tool for troubleshooting idle/sleep issues.

**Features:**
- Shows systemd inhibitors
- Lists running processes that may block idle
- Displays lock state
- Shows hypridle status
- Color-coded output for easy scanning

**Usage:**
```bash
./scripts/power/check-idle-blockers.sh
```

**When to use:**
- Before going to bed to verify sleep will work correctly
- When system isn't suspending as expected
- When troubleshooting power management issues
- To check what's preventing idle state

**Example output:**
```
=== System Idle Blockers Check ===

[1/4] Systemd Inhibitors:
  ✅ No blocking inhibitors

[2/4] Running Media Players:
  ⚠️  Found: brave (playing audio)

[3/4] Lock State:
  ✅ Screen locked

[4/4] Hypridle Status:
  ✅ Active and running
```

## Configuration

Idle and power settings are managed through:
- `modules/home/programs/hypridle.nix` - Idle daemon configuration
- `modules/system/power.nix` - System-level power management

## See Also
- [ISSUES.md](../../ISSUES.md#issue-8-monitors-turning-off-during-youtube-video) - Monitor blanking solutions
