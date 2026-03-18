# CLAUDE.md - WinForge

## Overview
All-in-one Windows provisioning and configuration utility. Inspired by Chris Titus Tech's WinUtil, rebuilt with a premium dark WPF GUI. v0.0.1.

## Tech Stack
- PowerShell 5.1, WPF GUI (tabbed interface)
- winget for package management
- Console hidden via P/Invoke

## Key Details
- ~1,603 lines, single-file
- Tab 1 (Install): 90+ winget apps across 8 categories
- Tab 2 (Tweaks): Essential, Advanced, Privacy checkbox groups
- Tab 3 (Features): Windows optional features management
- Tab 4 (Updates): Windows Update configuration
- Auto-elevates to admin

## Build/Run
```powershell
# Auto-elevates
.\WinForge.ps1
```

## Version
0.0.1

## Gotchas
- Early stage (v0.0.1) — overlaps with MavenWinUtil in scope
- Requires winget installed for app installation tab
