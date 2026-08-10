# Changelog

All notable changes to WinForge will be documented in this file.

## [v0.2.0] - 2026-08-09

- Added multi-source package installation with Scoop and Chocolatey fallback.
- Added bounded concurrent install lanes, per-package custom arguments, live output, and post-install verification.
- Added typo-tolerant application search and portable custom-argument profile export/import.
- Added WinGet DSC v3 `.winget` configuration import/export for replayable package bundles.
- Added tweak change previews, registry history restore, audit mode, dry-run scripts, ADMX export, risk guidance, conflict detection, and enterprise policy safeguards.
- Added MDT/Autounattend FirstLogonCommands export, WinRM/PSRemoting deployment, and local/SMB/HTTPS fleet preset loading.
- Added runtime Dark, Light, and High Contrast themes plus local-only crash logging with opt-in clipboard copying.
- Added an explicit Safe Preset action that creates a Restore Point and registry exports before applying tweaks.
- Added a PowerShell 7 TUI, optional ConsoleGuiTools selection, companion-plugin discovery, telemetry-level controls, ARM64 guidance, daily package-upgrade scheduling, and WinGet repair actions.

## [v0.1.0] - %Y->- (HEAD -> main, tag: v0.1.0, origin/main, origin/HEAD)

- Removed: Delete screenshot.png
- Changed: Update README.md
- Added: Add project icon to README
- Added: Add screenshot to README
- v0.1.0 - System info, config profiles, install progress, expanded app catalog
- Initial commit - WinForge

## Roadmap archive — 2026-08-10 — ROADMAP.md

<details>
<summary>Original roadmap snapshot</summary>

```markdown
# WinForge Roadmap

Forward-looking scope for the all-in-one Windows provisioning utility. WinUtil-style footprint, premium dark WPF aesthetic.

## Planned Features

### Tweaks Engine

### Deployment

### UX

## Competitive Research
- **Chris Titus Tech WinUtil** — the reference point; WinForge should match its MicroWin image-slimming feature for a true 1:1.
- **UniGetUI** — strongest GUI for multi-source package management (winget/scoop/choco/pip/npm); WinForge's installer should adopt the same multi-source catalog rather than staying winget-only.
- **Atlas OS / ReviOS config scripts** — referenced for tweak depth; cherry-pick audio stutter + network latency tweaks with clear warnings.

## Nice-to-Haves

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

### Patterns & Architectures Worth Studying
- SophiApp's strong-typed settings manifest — each tweak has Apply/Revert/Check triples, GUI binds generically
- WinUtil's single-file runspace model keeps the script irm-able while still threading (ChrisTitusTech)
- Config-as-code: tweaks live in JSON/YAML, PS code is generic executor (Win-Debloat-Tools)
- ModernWpf theming over stock WPF controls for Fluent look without heavy deps (FreeTimeTech)
- Elevation split: non-elevated launcher checks state, elevates only when a mutating action is chosen
```

</details>
