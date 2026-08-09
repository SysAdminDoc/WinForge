<p align="center"><img src="icon.svg" width="128" height="128" alt="WinForge"></p>

# WinForge

![Version](https://img.shields.io/badge/version-v0.1.0-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Platform](https://img.shields.io/badge/platform-PowerShell-lightgrey)

All-in-one Windows provisioning and configuration utility with a premium dark WPF GUI. Inspired by Chris Titus Tech's WinUtil -- rebuilt from scratch with a polished aesthetic.

## Features

### System Info Header
Compact 2-column grid showing Computer Name, OS/Build, CPU, RAM, User, Domain/Workgroup, and Storage (type + free space).

### Install
Multi-source app installer with 95+ apps organized by category: Browsers, Communications, Development, Documents, Gaming, Multimedia, Pro Tools, Utilities. Winget is preferred, with Scoop and Chocolatey fallback when a package cannot be resolved. Choose up to four concurrent install lanes, monitor per-app output, pass custom arguments per package, and verify installs against executable/registry/package-manager state. Presets are available for Developer, Gamer, Productivity, and Essentials workflows, and search tolerates typos.

### Tweaks
Checkbox-driven system modifications with descriptions and tooltips:
- **Essential** - Telemetry, temp files, hibernation, services, Widgets
- **Advanced** - Cortana, GameDVR, Copilot, Recall, Bing search, classic context menu, Ultimate Performance plan
- **Privacy** - Advertising ID, app launch tracking, diagnostic data, clipboard history, speech recognition

Every run shows a registry delta preview and saves a restore snapshot under `%LOCALAPPDATA%\WinForge\history\`. The Tweaks page also provides audit, dry-run script, and ADMX export actions, risk/revert guidance, third-party conflict warnings, and an enterprise-management guard for policy paths.
The **Safe Preset** action additionally creates a Windows Restore Point and exports existing registry paths before applying the selected tweaks under `%LOCALAPPDATA%\WinForge\safe-presets\`.
Telemetry controls expose Off, Basic, Enhanced, and Full levels with an explanation of the diagnostic-data tradeoff.

### Config
Windows optional features and system fixes (.NET 3.5, Hyper-V, WSL, SFC, DISM, network reset). Legacy control panel shortcuts.

### Updates
DNS configuration (Google, Cloudflare, Quad9, OpenDNS, AdGuard), Windows Update policy management, pause/reset.

### Config Profiles
Export and import your selections (apps + tweaks) as JSON files, or export/import a DSC v3 `.winget` package bundle for replay through `winget configure`. Share configurations between machines or save favorite setups.

### Deployment
Export a `FirstLogonCommands` XML block with a companion PowerShell payload for MDT or Autounattend workflows. The Deployment page can audit or apply the selected apps and tweaks to a WinRM/PSRemoting target using the current Windows credentials, load a JSON fleet preset from a local path, SMB share, or HTTPS Git URL, and discover local SysAdminDoc plugin manifests without executing them automatically. Set `WINFORGE_PRESET_SOURCE` to load a preset at startup.

### Appearance and Crash Reports
Switch between Dark, Light, and High Contrast modes from the sidebar. Unhandled UI and application exceptions are recorded locally, without telemetry, at `%LOCALAPPDATA%\WinForge\crash.log`; use **Copy Crash Report** only when you choose to review or share the report.

## Usage

```powershell
# Auto-elevates to Administrator
.\WinForge.ps1
```

For a PowerShell 7 console workflow, use `pwsh .\WinForge.ps1 -Tui`. The TUI uses `Out-ConsoleGridView` when Microsoft.PowerShell.ConsoleGuiTools is installed and otherwise falls back to a numbered console selector. On ARM64 Windows, WinForge warns that package architecture support is resolved by the selected package manager.

Support and feature requests: [GitHub Issues](https://github.com/SysAdminDoc/WinForge/issues)

## Requirements

- Windows 10/11
- PowerShell 5.1+
- winget (for app installation)
