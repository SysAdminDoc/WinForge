<p align="center"><img src="icon.svg" width="128" height="128" alt="WinForge"></p>

# WinForge

All-in-one Windows provisioning and configuration utility with a premium dark WPF GUI. Inspired by Chris Titus Tech's WinUtil -- rebuilt from scratch with a polished aesthetic.


![Screenshot](screenshot.png)

## Features

### System Info Header
Compact 2-column grid showing Computer Name, OS/Build, CPU, RAM, User, Domain/Workgroup, and Storage (type + free space).

### Install
Winget-based app installer with 95+ apps organized by category: Browsers, Communications, Development, Documents, Gaming, Multimedia, Pro Tools, Utilities. Sequential install with progress counters and log output. Presets for Developer, Gamer, Productivity, and Essentials workflows.

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
Export and import your selections (apps + tweaks) as JSON files. Share configurations between machines or save favorite setups.

## Usage

```powershell
# Auto-elevates to Administrator
.\WinForge.ps1
```

## Requirements

- Windows 10/11
- PowerShell 5.1+
- winget (for app installation)
