# WinForge

All-in-one Windows provisioning and configuration utility with a premium dark WPF GUI. Inspired by Chris Titus Tech's WinUtil -- rebuilt from scratch with a polished aesthetic.

## Tabs

### Install
Winget-based app installer with 90+ apps organized by category: Browsers, Communications, Development, Documents, Gaming, Multimedia, Pro Tools, Utilities.

### Tweaks
Checkbox-driven system modifications in three groups:
- **Essential** - Telemetry, temp files, hibernation, services, Widgets
- **Advanced** - Cortana, GameDVR, Copilot, Recall, Bing search, classic context menu, Ultimate Performance plan
- **Privacy** - Advertising ID, app launch tracking, diagnostic data, clipboard history, speech recognition

### Features
Windows optional features and capabilities management (.NET 3.5, Hyper-V, WSL, etc.).

### Updates
Windows Update configuration and management.

## Usage

```powershell
# Auto-elevates to Administrator
.\WinForge.ps1
```

## Requirements

- Windows 10/11
- PowerShell 5.1+
- winget (for app installation)
