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
