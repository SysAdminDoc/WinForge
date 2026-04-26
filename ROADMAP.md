# WinForge Roadmap

Forward-looking scope for the all-in-one Windows provisioning utility. WinUtil-style footprint, premium dark WPF aesthetic.

## Planned Features

### App Installer
- Migrate backend to Scoop + Chocolatey fallback when winget can't resolve a package.
- Winget configuration YAML import/export (DSC v3 bundles) so a WinForge preset is replayable through `winget configure`.
- Parallel install lane (up to N concurrent winget sessions) with live per-app log tails; winget 1.11+ supports `--parallel`.
- Per-app `--custom` arg passthrough (silent switches, install dir overrides).
- Post-install verification: for each app, confirm exe/registry presence instead of trusting winget's exit code.

### Tweaks Engine
- Registry diff preview: before writing a tweak, show the delta (HKCU/HKLM key, existing value, new value) and let the user veto.
- "Undo last tweak set" history stored in `%LOCALAPPDATA%\WinForge\history\` with one-click restore.
- Group Policy-equivalent ADMX export so a tweak set can be pushed via Intune/GPO instead of running WinForge on every machine.
- Detect existing third-party tweak tool state (ShutUp10 flags, O&O settings, WPD markers) and warn on conflict.

### Deployment
- MDT / autounattend integration: export the current config as a `FirstLogonCommands` block.
- Remote mode over WinRM/PSRemoting: target a remote machine's tweak surface from the same GUI.
- Fleet preset library: pull a team-shared JSON preset from a Git URL or SMB share on launch.
- "Audit mode" that reports which tweaks are already applied on the current system without changing anything.

### UX
- Per-tab search (already global) with fuzzy match scoring so "disable wdget" still hits "Widgets".
- Tweak risk ratings (green/yellow/red) surfaced as colored pips next to each checkbox with hover tooltip explaining revert steps.
- Dark/light theme toggle + high-contrast mode.
- Telemetry-free crash logging to `%LOCALAPPDATA%\WinForge\crash.log` with opt-in "Copy crash report to clipboard" button.

## Competitive Research
- **Chris Titus Tech WinUtil** — the reference point; WinForge should match its MicroWin image-slimming feature for a true 1:1.
- **UniGetUI** — strongest GUI for multi-source package management (winget/scoop/choco/pip/npm); WinForge's installer should adopt the same multi-source catalog rather than staying winget-only.
- **Atlas OS / ReviOS config scripts** — referenced for tweak depth; cherry-pick audio stutter + network latency tweaks with clear warnings.

## Nice-to-Haves
- "Safe preset" that backs up a Restore Point + registry export before applying any tweak.
- PowerShell 7 port that drops the WPF skin for a TUI using `Microsoft.PowerShell.ConsoleGuiTools`.
- Integration with the companion SysAdminDoc tools (WURepair, DefenderShield) as discoverable plugins.
- Licensed-edition detector that hides tweaks that don't apply (e.g., "disable Recall" on non-Copilot+ SKU).
- Revenue-free "donations" link replaced with a link to the GitHub issue tracker.
- ARM64 Windows 11 compatibility pass (Snapdragon X devices ship with an incomplete winget catalog).

## Open-Source Research (Round 2)

### Related OSS Projects
- https://github.com/ChrisTitusTech/winutil — reference PowerShell/WPF all-in-one
- https://github.com/Sophia-Community/SophiApp — C#/WPF Sophia Script full GUI
- https://github.com/SimonCropp/WinDebloat — dotnet tool, winget-driven uninstalls
- https://github.com/LeDragoX/Win-Debloat-Tools — scheduled winget/choco upgrades, CLI+GUI
- https://github.com/2rf/winGetDebloated — minimalist winget-batch approach
- https://github.com/Raphire/Win11Debloat — focused Win11 debloat script
- https://github.com/ShutUp10/ShutUp10 — privacy tweaks reference
- https://github.com/builtbybel/bloatynosy — modern Win11 debloater with telemetry focus
- https://github.com/UniGetUI/UniGetUI — multi-backend package manager GUI (winget/scoop/choco/pip/npm)

### Features to Borrow
- Daily upgrade scheduled task for winget + chocolatey, 12:00/13:00 slots (LeDragoX)
- "Fix Winget" recovery flow: re-register App Installer + repair DesktopAppInstaller appx (FreeTimeTech/WinUtil)
- Export/Import profile JSON — user's full tweak + install selection portable across machines (UniGetUI)
- Multi-backend package support: add Scoop + Chocolatey as alternates to winget for packages not in the MS repo (UniGetUI)
- Undo stack for every tweak with registry-based "before" snapshot (SophiApp)
- Dry-run mode with a generated PS script of exactly what will run (WinDebloat)
- Telemetry-group toggles: Basic / Enhanced / Full → Off with explanation text (ShutUp10, SophiApp)
- Post-install health check: run SFC/DISM quick scan + firewall audit + report page
- Enterprise mode: block tweaks that touch MDM-managed policies, surface a banner (SophiApp)
- MSIX-packaged release so Windows Store / winget distribution works

### Patterns & Architectures Worth Studying
- SophiApp's strong-typed settings manifest — each tweak has Apply/Revert/Check triples, GUI binds generically
- WinUtil's single-file runspace model keeps the script irm-able while still threading (ChrisTitusTech)
- Config-as-code: tweaks live in JSON/YAML, PS code is generic executor (Win-Debloat-Tools)
- ModernWpf theming over stock WPF controls for Fluent look without heavy deps (FreeTimeTech)
- Elevation split: non-elevated launcher checks state, elevates only when a mutating action is chosen
