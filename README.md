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

### Config
Windows optional features and system fixes (.NET 3.5, Hyper-V, WSL, SFC, DISM, network reset). Legacy control panel shortcuts.

### Updates
DNS configuration (Google, Cloudflare, Quad9, OpenDNS, AdGuard), Windows Update policy management, pause/reset.

### Config Profiles
Export and import your selections (apps + tweaks) as JSON files, or export/import a DSC v3 `.winget` package bundle for replay through `winget configure`. Share configurations between machines or save favorite setups.

## Usage

```powershell
# Auto-elevates to Administrator
.\WinForge.ps1
```

## Requirements

- Windows 10/11
- PowerShell 5.1+
- winget (for app installation)
