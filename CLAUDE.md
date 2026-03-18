# CLAUDE.md - WinForge

## Overview
All-in-one Windows provisioning and configuration utility. Inspired by Chris Titus Tech's WinUtil, rebuilt with a premium dark WPF GUI. v0.1.0.

## Tech Stack
- PowerShell 5.1, WPF GUI (sidebar nav + tabbed pages)
- winget for package management
- Console hidden via P/Invoke
- `[PowerShell]::Create()` + `BeginInvoke()` + `DispatcherTimer` for async operations

## Key Details
- Single-file (~1700 lines)
- Sidebar navigation: Install, Tweaks, Config, Updates + Quick Actions (Export/Import)
- System info header: Computer, OS/Build, CPU, RAM, User, Domain, Storage
- Install tab: 95+ winget apps across 8 categories with presets, search, sequential install progress
- Tweaks tab: Essential, Advanced, Privacy checkbox groups with descriptions and tooltips
- Config tab: Windows features, system fixes, legacy panels
- Updates tab: DNS config, update policies, pause/reset
- Config export/import (JSON profiles) via sidebar Quick Actions
- Auto-elevates to admin

## Build/Run
```powershell
# Auto-elevates
.\WinForge.ps1
```

## Version
0.1.0

## Version History
- 0.1.0 - System info header panel, sequential install progress with counters, Zen Browser + Element added, version bump
- 0.0.1 - Initial release

## Gotchas
- Requires winget installed for app installation tab
- Sequential install (not parallel) to avoid winget conflicts
- No emoji/unicode in PowerShell output (encoding errors)
