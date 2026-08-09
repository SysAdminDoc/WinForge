#Requires -Version 5.1
<#
.SYNOPSIS
    WinForge v0.2.0 - Premium Windows System Utility
.DESCRIPTION
    All-in-one Windows utility: Install programs, apply system tweaks,
    configure features, and manage Windows Updates.
    Inspired by Chris Titus Tech's WinUtil - rebuilt with a premium UI.
.NOTES
    Run as Administrator for full functionality.
    Uses winget for package management.
#>

[CmdletBinding()]
param(
    [switch]$NoLaunch,
    [switch]$NoElevation,
    [switch]$Tui,
    [string[]]$RunTweaks
)

$script:WinForgeVersion = '0.2.0'
$script:WinForgeNoLaunch = $NoLaunch

# ── Auto-Elevate ───────────────────────────────────────────────────────────────
if (-not $NoElevation -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $elevationArgs = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($NoLaunch) { $elevationArgs += ' -NoLaunch' }
    if ($Tui) { $elevationArgs += ' -Tui' }
    if ($RunTweaks.Count -gt 0) { $elevationArgs += ' -RunTweaks ' + ($RunTweaks -join ',') }
    $elevationHost = if ($Tui) { Join-Path $PSHOME 'pwsh.exe' } else { 'powershell.exe' }
    $elevationWindowStyle = if ($Tui) { 'Normal' } else { 'Hidden' }
    Start-Process $elevationHost -Verb RunAs -WindowStyle $elevationWindowStyle -ArgumentList $elevationArgs
    exit
}

# ── Assemblies ─────────────────────────────────────────────────────────────────
if (-not $Tui) {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Windows.Forms
}

# ── Hide Console ───────────────────────────────────────────────────────────────
if (-not $Tui) {
    Add-Type -Name Win -Namespace Native -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
    [Native.Win]::ShowWindow([Native.Win]::GetConsoleWindow(), 0) | Out-Null
}

# ── App Data ───────────────────────────────────────────────────────────────────
$script:AppCategories = [ordered]@{
    'Browsers' = @(
        @{Name='Google Chrome';         Id='Google.Chrome'}
        @{Name='Mozilla Firefox';       Id='Mozilla.Firefox'}
        @{Name='Brave Browser';         Id='Brave.Brave'}
        @{Name='Microsoft Edge';        Id='Microsoft.Edge'}
        @{Name='Vivaldi';               Id='VivaldiTechnologies.Vivaldi'}
        @{Name='Opera';                 Id='Opera.Opera'}
        @{Name='Waterfox';              Id='Waterfox.Waterfox'}
        @{Name='Tor Browser';           Id='TorProject.TorBrowser'}
        @{Name='LibreWolf';             Id='LibreWolf.LibreWolf'}
        @{Name='Ungoogled Chromium';    Id='eloston.ungoogled-chromium'}
        @{Name='Zen Browser';           Id='zen-team.Zen'}
    )
    'Communications' = @(
        @{Name='Discord';               Id='Discord.Discord'}
        @{Name='Zoom';                  Id='Zoom.Zoom'}
        @{Name='Microsoft Teams';       Id='Microsoft.Teams'}
        @{Name='Slack';                 Id='SlackTechnologies.Slack'}
        @{Name='Telegram';              Id='Telegram.TelegramDesktop'}
        @{Name='Signal';                Id='OpenWhisperSystems.Signal'}
        @{Name='Thunderbird';           Id='Mozilla.Thunderbird'}
        @{Name='Skype';                 Id='Microsoft.Skype'}
        @{Name='Element';               Id='Element.Element'}
    )
    'Development' = @(
        @{Name='Visual Studio Code';    Id='Microsoft.VisualStudioCode'}
        @{Name='Git';                   Id='Git.Git'}
        @{Name='Node.js LTS';           Id='OpenJS.NodeJS.LTS'}
        @{Name='Python 3';              Id='Python.Python.3.12'}
        @{Name='Windows Terminal';      Id='Microsoft.WindowsTerminal'}
        @{Name='PowerShell 7';          Id='Microsoft.PowerShell'}
        @{Name='Notepad++';             Id='Notepad++.Notepad++'}
        @{Name='Sublime Text';          Id='SublimeHQ.SublimeText.4'}
        @{Name='Docker Desktop';        Id='Docker.DockerDesktop'}
        @{Name='Postman';               Id='Postman.Postman'}
        @{Name='WinSCP';                Id='WinSCP.WinSCP'}
        @{Name='PuTTY';                 Id='PuTTY.PuTTY'}
        @{Name='FileZilla';             Id='TimKosse.FileZilla.Client'}
        @{Name='GitHub Desktop';        Id='GitHub.GitHubDesktop'}
    )
    'Documents' = @(
        @{Name='Adobe Acrobat Reader';  Id='Adobe.Acrobat.Reader.64-bit'}
        @{Name='LibreOffice';           Id='TheDocumentFoundation.LibreOffice'}
        @{Name='Obsidian';              Id='Obsidian.Obsidian'}
        @{Name='Notion';                Id='Notion.Notion'}
        @{Name='SumatraPDF';            Id='SumatraPDF.SumatraPDF'}
        @{Name='Calibre';               Id='calibre.calibre'}
    )
    'Gaming' = @(
        @{Name='Steam';                 Id='Valve.Steam'}
        @{Name='Epic Games Launcher';   Id='EpicGames.EpicGamesLauncher'}
        @{Name='GOG Galaxy';            Id='GOG.Galaxy'}
        @{Name='EA App';                Id='ElectronicArts.EADesktop'}
        @{Name='Prism Launcher';        Id='PrismLauncher.PrismLauncher'}
    )
    'Multimedia' = @(
        @{Name='VLC Media Player';      Id='VideoLAN.VLC'}
        @{Name='Spotify';               Id='Spotify.Spotify'}
        @{Name='Audacity';              Id='Audacity.Audacity'}
        @{Name='OBS Studio';            Id='OBSProject.OBSStudio'}
        @{Name='HandBrake';             Id='HandBrake.HandBrake'}
        @{Name='GIMP';                  Id='GIMP.GIMP'}
        @{Name='Inkscape';              Id='Inkscape.Inkscape'}
        @{Name='paint.net';             Id='dotPDN.PaintDotNet'}
        @{Name='foobar2000';            Id='PeterPawlowski.foobar2000'}
        @{Name='MusicBee';              Id='MusicBee.MusicBee'}
        @{Name='ShareX';                Id='ShareX.ShareX'}
        @{Name='Greenshot';             Id='Greenshot.Greenshot'}
        @{Name='FFmpeg';                Id='Gyan.FFmpeg'}
        @{Name='ImageMagick';           Id='ImageMagick.ImageMagick'}
    )
    'Pro Tools' = @(
        @{Name='PowerToys';             Id='Microsoft.PowerToys'}
        @{Name='Sysinternals Suite';    Id='Microsoft.Sysinternals'}
        @{Name='Wireshark';             Id='WiresharkFoundation.Wireshark'}
        @{Name='VMware Workstation Player'; Id='VMware.WorkstationPlayer'}
        @{Name='VirtualBox';            Id='Oracle.VirtualBox'}
        @{Name='WinDbg Preview';        Id='Microsoft.WinDbg'}
        @{Name='HWiNFO';                Id='REALiX.HWiNFO'}
        @{Name='CPU-Z';                 Id='CPUID.CPU-Z'}
    )
    'Utilities' = @(
        @{Name='7-Zip';                 Id='7zip.7zip'}
        @{Name='WinRAR';                Id='RARLab.WinRAR'}
        @{Name='Everything Search';     Id='voidtools.Everything'}
        @{Name='TreeSize Free';         Id='JAMSoftware.TreeSize.Free'}
        @{Name='Bitwarden';             Id='Bitwarden.Bitwarden'}
        @{Name='KeePassXC';             Id='KeePassXCTeam.KeePassXC'}
        @{Name='qBittorrent';           Id='qBittorrent.qBittorrent'}
        @{Name='NanaZip';               Id='M2Team.NanaZip'}
        @{Name='Revo Uninstaller';      Id='VS Reckoning.RevoUninstaller'}
        @{Name='BleachBit';             Id='BleachBit.BleachBit'}
        @{Name='Rufus';                 Id='Rufus.Rufus'}
        @{Name='Etcher';                Id='Balena.Etcher'}
        @{Name='WizTree';               Id='AntibodySoftware.WizTree'}
        @{Name='CrystalDiskInfo';       Id='CrystalDewWorld.CrystalDiskInfo'}
        @{Name='CrystalDiskMark';       Id='CrystalDewWorld.CrystalDiskMark'}
    )
}

$script:TweakCategories = [ordered]@{
    'Essential Tweaks' = @(
        @{Name='Create Restore Point';              Key='RestorePoint';       Desc='Creates a system restore point before making changes'}
        @{Name='Delete Temporary Files';             Key='TempFiles';          Desc='Removes temporary files to free disk space'}
        @{Name='Disable Telemetry';                  Key='Telemetry';          Desc='Disables Windows telemetry and data collection'}
        @{Name='Disable Activity History';           Key='ActivityHistory';    Desc='Prevents Windows from tracking your activity history'}
        @{Name='Disable Location Tracking';          Key='LocationTracking';   Desc='Disables location tracking services'}
        @{Name='Disable Hibernation';                Key='Hibernation';        Desc='Disables hibernation to free disk space'}
        @{Name='Disable ConsumerFeatures';           Key='ConsumerFeatures';   Desc='Removes suggested apps and consumer features'}
        @{Name='Set Services to Manual';             Key='ServicesManual';     Desc='Sets non-essential services to manual start'}
        @{Name='Disable PowerShell 7 Telemetry';    Key='PS7Telemetry';       Desc='Disables PowerShell 7 telemetry collection'}
        @{Name='Remove Widgets';                     Key='Widgets';            Desc='Removes the Windows 11 Widgets feature'}
        @{Name='Enable End Task in Taskbar';         Key='EndTask';            Desc='Adds End Task option to taskbar right-click'}
        @{Name='Run Disk Cleanup';                   Key='DiskCleanup';        Desc='Runs Windows Disk Cleanup utility'}
    )
    'Advanced Tweaks' = @(
        @{Name='Disable Cortana';                    Key='Cortana';            Desc='Disables Cortana assistant'}
        @{Name='Disable Xbox GameDVR';               Key='GameDVR';            Desc='Disables Xbox Game DVR and Game Bar'}
        @{Name='Disable WiFi Sense';                 Key='WiFiSense';          Desc='Disables WiFi Sense (auto-connect to open hotspots)'}
        @{Name='Disable Storage Sense';              Key='StorageSense';       Desc='Disables automatic storage management'}
        @{Name='Disable Copilot';                    Key='Copilot';            Desc='Disables Windows Copilot AI assistant'}
        @{Name='Disable Recall';                     Key='Recall';             Desc='Disables Windows Recall feature'}
        @{Name='Disable News and Interests';         Key='NewsInterests';      Desc='Removes News and Interests from taskbar'}
        @{Name='Disable Bing Search in Start';       Key='BingSearch';         Desc='Removes Bing web results from Start Menu search'}
        @{Name='Disable Search Highlights';          Key='SearchHighlights';   Desc='Removes search highlights from Start Menu'}
        @{Name='Show File Extensions';               Key='FileExtensions';     Desc='Shows file extensions in Explorer'}
        @{Name='Show Hidden Files';                  Key='HiddenFiles';        Desc='Shows hidden files and folders in Explorer'}
        @{Name='Disable Mouse Acceleration';         Key='MouseAccel';         Desc='Disables mouse acceleration for precision'}
        @{Name='Classic Right-Click Menu (W11)';     Key='ClassicContext';     Desc='Restores the classic right-click context menu'}
        @{Name='Ultimate Performance Power Plan';    Key='UltimatePower';      Desc='Enables the Ultimate Performance power plan'}
    )
    'Privacy Tweaks' = @(
        @{Name='Disable Advertising ID';             Key='AdvertisingID';      Desc='Prevents apps from using your Advertising ID'}
        @{Name='Disable App Launch Tracking';        Key='AppLaunchTracking';  Desc='Stops Windows from tracking which apps you launch'}
        @{Name='Disable Feedback Requests';          Key='FeedbackRequests';   Desc='Disables Windows feedback notifications'}
        @{Name='Disable Tailored Experiences';       Key='TailoredExp';        Desc='Stops personalized tips and suggestions'}
        @{Name='Disable Diagnostic Data';            Key='DiagnosticData';     Desc='Sets diagnostic data to minimum required'}
        @{Name='Disable Clipboard History';          Key='ClipboardHistory';   Desc='Disables cloud clipboard syncing'}
        @{Name='Disable Online Speech Recognition';  Key='SpeechRecognition';  Desc='Disables cloud-based speech recognition'}
        @{Name='Disable Input Personalization';      Key='InputPersonal';      Desc='Stops Windows from learning your typing/inking'}
    )
}

$script:ConfigFeatures = [ordered]@{
    'Windows Features' = @(
        @{Name='.NET Framework 3.5';         Key='NetFX3';         Feature='NetFx3'}
        @{Name='Hyper-V';                    Key='HyperV';         Feature='Microsoft-Hyper-V-All'}
        @{Name='Windows Sandbox';            Key='Sandbox';        Feature='Containers-DisposableClientVM'}
        @{Name='WSL (Linux Subsystem)';      Key='WSL';            Feature='Microsoft-Windows-Subsystem-Linux;VirtualMachinePlatform'}
        @{Name='NFS Client';                 Key='NFS';            Feature='ServicesForNFS-ClientOnly;ClientForNFS-Infrastructure'}
        @{Name='Windows Media Player';       Key='WMP';            Feature='WindowsMediaPlayer'}
        @{Name='DirectPlay';                 Key='DirectPlay';     Feature='DirectPlay'}
    )
    'System Fixes' = @(
        @{Name='Reset Windows Update';       Key='ResetWU';        Fix='WindowsUpdate'}
        @{Name='System File Checker (SFC)';  Key='SFC';            Fix='SFC'}
        @{Name='DISM Repair Image';          Key='DISM';           Fix='DISM'}
        @{Name='Reset Network Stack';        Key='ResetNetwork';   Fix='Network'}
        @{Name='Clear DNS Cache';            Key='ClearDNS';       Fix='DNS'}
        @{Name='Set Up Autologon';           Key='Autologon';      Fix='Autologon'}
    )
    'Legacy Panels' = @(
        @{Name='Control Panel';              Key='CtrlPanel';      Panel='control'}
        @{Name='Network Connections';        Key='NetConn';        Panel='ncpa.cpl'}
        @{Name='Power Options';              Key='PowerOpt';       Panel='powercfg.cpl'}
        @{Name='System Properties';          Key='SysProp';        Panel='sysdm.cpl'}
        @{Name='Sound Settings';             Key='Sound';          Panel='mmsys.cpl'}
        @{Name='Device Manager';             Key='DevMgr';         Panel='devmgmt.msc'}
        @{Name='Disk Management';            Key='DiskMgmt';       Panel='diskmgmt.msc'}
        @{Name='User Accounts';              Key='UserAccts';      Panel='netplwiz'}
        @{Name='Programs and Features';      Key='ProgFeat';       Panel='appwiz.cpl'}
        @{Name='Windows Features';           Key='WinFeat';        Panel='optionalfeatures'}
        @{Name='Services';                   Key='Services';       Panel='services.msc'}
        @{Name='Group Policy Editor';        Key='GroupPolicy';    Panel='gpedit.msc'}
        @{Name='Event Viewer';               Key='EventViewer';    Panel='eventvwr.msc'}
        @{Name='Task Scheduler';             Key='TaskSched';      Panel='taskschd.msc'}
    )
}

# ── Tweak metadata and registry model ─────────────────────────────────────────
$script:TweakMetadata = @{
    RestorePoint      = @{ Risk = 'Green';  Revert = 'Restore points do not change a setting.' }
    TempFiles         = @{ Risk = 'Green';  Revert = 'Deleted temporary files cannot be restored.' }
    Telemetry         = @{ Risk = 'Red';    Revert = 'Re-enable telemetry and restore the DiagTrack service.' }
    ActivityHistory   = @{ Risk = 'Yellow'; Revert = 'Re-enable activity feed and publishing policies.' }
    LocationTracking  = @{ Risk = 'Yellow'; Revert = 'Set the location consent value back to Allow.' }
    Hibernation       = @{ Risk = 'Yellow'; Revert = 'Run powercfg /h on to restore hibernation.' }
    ConsumerFeatures  = @{ Risk = 'Yellow'; Revert = 'Allow Windows consumer features again.' }
    ServicesManual    = @{ Risk = 'Red';    Revert = 'Restore affected services to Automatic and start them.' }
    PS7Telemetry      = @{ Risk = 'Green';  Revert = 'Set POWERSHELL_TELEMETRY_OPTOUT back to 0.' }
    Widgets           = @{ Risk = 'Yellow'; Revert = 'Allow Windows Widgets again.' }
    EndTask           = @{ Risk = 'Green';  Revert = 'Remove the taskbar End Task policy value.' }
    DiskCleanup       = @{ Risk = 'Green';  Revert = 'Disk Cleanup is an action with no persistent setting.' }
    Cortana           = @{ Risk = 'Yellow'; Revert = 'Allow Cortana through the Windows Search policy.' }
    GameDVR           = @{ Risk = 'Yellow'; Revert = 'Re-enable Game DVR in the user and machine policies.' }
    WiFiSense         = @{ Risk = 'Yellow'; Revert = 'Allow OEM Wi-Fi auto-connect behavior again.' }
    StorageSense      = @{ Risk = 'Yellow'; Revert = 'Re-enable Storage Sense policy value.' }
    Copilot           = @{ Risk = 'Yellow'; Revert = 'Remove the Windows Copilot block.' }
    Recall            = @{ Risk = 'Red';    Revert = 'Remove the Recall data-analysis block.' }
    NewsInterests     = @{ Risk = 'Green';  Revert = 'Re-enable News and Interests policy.' }
    BingSearch        = @{ Risk = 'Yellow'; Revert = 'Allow web suggestions in Start search.' }
    SearchHighlights  = @{ Risk = 'Green';  Revert = 'Re-enable search highlights.' }
    FileExtensions    = @{ Risk = 'Green';  Revert = 'Restore hidden file extensions.' }
    HiddenFiles       = @{ Risk = 'Yellow'; Revert = 'Hide protected/hidden files again.' }
    MouseAccel        = @{ Risk = 'Green';  Revert = 'Restore standard mouse acceleration values.' }
    ClassicContext    = @{ Risk = 'Green';  Revert = 'Remove the classic context-menu override.' }
    UltimatePower     = @{ Risk = 'Yellow'; Revert = 'Switch back to the Balanced power plan.' }
    AdvertisingID     = @{ Risk = 'Green';  Revert = 'Re-enable the Advertising ID.' }
    AppLaunchTracking = @{ Risk = 'Green';  Revert = 'Re-enable app launch tracking.' }
    FeedbackRequests  = @{ Risk = 'Green';  Revert = 'Allow feedback request notifications.' }
    TailoredExp       = @{ Risk = 'Green';  Revert = 'Re-enable tailored experiences.' }
    DiagnosticData    = @{ Risk = 'Red';    Revert = 'Restore the diagnostic-data policy to Full.' }
    ClipboardHistory  = @{ Risk = 'Yellow'; Revert = 'Re-enable clipboard history.' }
    SpeechRecognition = @{ Risk = 'Yellow'; Revert = 'Allow online speech recognition.' }
    InputPersonal     = @{ Risk = 'Yellow'; Revert = 'Allow input personalization.' }
}

function Get-WinForgeTweakInfo {
    param([Parameter(Mandatory)][string]$Key)
    if ($script:TweakMetadata.ContainsKey($Key)) { return $script:TweakMetadata[$Key] }
    return @{ Risk = 'Yellow'; Revert = 'Use the Restore Last Set action to restore the previous snapshot.' }
}

function Get-WinForgeTweakRegistryDefinition {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Key)

    $definitions = New-Object System.Collections.ArrayList
    $add = {
        param($Path, $Name, $Apply, $Undo, $Type = 'DWord', $Kind = 'Registry')
        [void]$definitions.Add([pscustomobject]@{
            Key = $Key; Path = $Path; Name = $Name; Apply = $Apply; Undo = $Undo
            Type = $Type; Kind = $Kind
        })
    }
    switch ($Key) {
        'Telemetry'       { & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 3 }
        'ActivityHistory' { & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0 1; & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0 1 }
        'LocationTracking'{ & $add 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'Deny' 'Allow' 'String' }
        'ConsumerFeatures' { & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1 0 }
        'Widgets'         { & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0 1 }
        'EndTask'         { & $add 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' 'TaskbarEndTask' 1 0 }
        'Cortana'         { & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 0 1 }
        'GameDVR'         { & $add 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 1; & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0 1 }
        'WiFiSense'       { & $add 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' 'AutoConnectAllowedOEM' 0 1 }
        'StorageSense'    { & $add 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '01' 0 1 }
        'Copilot'         { & $add 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1 0 }
        'Recall'          { & $add 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1 0 }
        'NewsInterests'   { & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds' 0 1 }
        'BingSearch'      { & $add 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1 0 }
        'SearchHighlights'{ & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'EnableDynamicContentInWSB' 0 1 }
        'FileExtensions'  { & $add 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0 1 }
        'HiddenFiles'     { & $add 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Hidden' 1 2 }
        'MouseAccel'      { & $add 'HKCU:\Control Panel\Mouse' 'MouseSpeed' 0 1 'String'; & $add 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' 0 1 'String'; & $add 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' 0 1 'String' }
        'ClassicContext'  { & $add 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '(key)' 'exists' 'absent' 'Path' 'RegistryPath' }
        'AdvertisingID'   { & $add 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 1 }
        'AppLaunchTracking' { & $add 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0 1 }
        'FeedbackRequests'{ & $add 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0 1 }
        'TailoredExp'     { & $add 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0 1 }
        'DiagnosticData'  { & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 3 }
        'ClipboardHistory'{ & $add 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowClipboardHistory' 0 1 }
        'SpeechRecognition' { & $add 'HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 0 1 }
        'InputPersonal'   { & $add 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1 0; & $add 'HKCU:\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1 0 }
    }
    return $definitions
}

function Get-WinForgeTweakChangeSet {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Key, [bool]$Undo = $false)

    $definitions = @(Get-WinForgeTweakRegistryDefinition -Key $Key)
    if ($definitions.Count -eq 0) {
        $description = switch ($Key) {
            'RestorePoint' { 'Create a system restore point' }
            'TempFiles' { 'Delete temporary files' }
            'Hibernation' { 'Run powercfg /h off' }
            'ServicesManual' { 'Change selected Windows services to Manual' }
            'PS7Telemetry' { 'Set the machine PowerShell telemetry opt-out variable' }
            'DiskCleanup' { 'Launch Windows Disk Cleanup' }
            'UltimatePower' { 'Activate the Ultimate Performance power plan' }
            default { 'Run the selected system action' }
        }
        return [pscustomobject]@{ Key = $Key; Kind = 'Action'; Path = ''; Name = $description; Current = 'not evaluated'; Target = $(if ($Undo) { 'restore' } else { 'run' }); CurrentExists = $false; Type = 'Action' }
    }

    $changes = @()
    foreach ($definition in $definitions) {
        $exists = Test-Path -LiteralPath $definition.Path
        $current = $null
        if ($exists -and $definition.Kind -eq 'RegistryPath') {
            $current = 'exists'
        } elseif ($exists) {
            $property = Get-ItemProperty -LiteralPath $definition.Path -Name $definition.Name -ErrorAction SilentlyContinue
            if ($property) { $current = $property.PSObject.Properties[$definition.Name].Value }
        }
        $target = if ($Undo) { $definition.Undo } else { $definition.Apply }
        $changes += [pscustomobject]@{
            Key = $Key; Kind = $definition.Kind; Path = $definition.Path; Name = $definition.Name
            Current = $current; CurrentExists = ($null -ne $current)
            Target = $target; Undo = $definition.Undo; Type = $definition.Type
        }
    }
    return $changes
}

function Get-WinForgeTweakRiskBrush {
    param([Parameter(Mandatory)][string]$Risk)
    switch ($Risk) {
        'Green' { return '#4ade80' }
        'Red' { return '#f87171' }
        default { return '#facc15' }
    }
}

function Get-WinForgeThirdPartyTweakConflict {
    [CmdletBinding()]
    param()

    $markers = @(
        @{ Name = 'O&O ShutUp10++'; Paths = @('HKCU:\SOFTWARE\O&O\ShutUp10', 'HKLM:\SOFTWARE\O&O\ShutUp10') }
        @{ Name = 'WPD'; Paths = @('HKCU:\SOFTWARE\WPD', 'HKLM:\SOFTWARE\WPD') }
        @{ Name = 'Bloatynosy'; Paths = @('HKCU:\SOFTWARE\Bloatynosy', 'HKLM:\SOFTWARE\Bloatynosy') }
        @{ Name = 'Win11Debloat'; Paths = @('HKCU:\SOFTWARE\Win11Debloat', 'HKLM:\SOFTWARE\Win11Debloat') }
    )
    $foundConflicts = @()
    foreach ($marker in $markers) {
        foreach ($path in $marker.Paths) {
            if (Test-Path -LiteralPath $path) {
                $foundConflicts += [pscustomobject]@{ Name = $marker.Name; Path = $path }
                break
            }
        }
    }
    return $foundConflicts
}

function Get-WinForgeEnterpriseState {
    [CmdletBinding()]
    param()

    $markers = @(
        @{ Name = 'MDM policy store'; Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device' }
        @{ Name = 'Enrollment records'; Path = 'HKLM:\SOFTWARE\Microsoft\Enrollments' }
        @{ Name = 'Enterprise management'; Path = 'HKLM:\SOFTWARE\Microsoft\EnterpriseResourceManager' }
    )
    $sources = @($markers | Where-Object { Test-Path -LiteralPath $_.Path })
    return [pscustomobject]@{ IsManaged = ($sources.Count -gt 0); Sources = $sources }
}

function Write-WinForgeTui {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message, [ConsoleColor]$Color = [ConsoleColor]::Gray)

    $null = $Color
    Write-Information -MessageData $Message -InformationAction Continue
}

function Select-WinForgeTuiItem {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Items, [Parameter(Mandatory)][string]$Title)

    if (Get-Command Out-ConsoleGridView -ErrorAction SilentlyContinue) {
        return @($Items | Out-ConsoleGridView -Title $Title -OutputMode Multiple)
    }
    Write-WinForgeTui -Message "`n$Title" -Color Cyan
    for ($index = 0; $index -lt $Items.Count; $index++) {
        $item = $Items[$index]
        $label = if ($item.Id) { "{0} [{1}]" -f $item.Name, $item.Id } else { "{0} [{1}]" -f $item.Name, $item.Key }
        Write-WinForgeTui -Message ("  {0}. {1}" -f ($index + 1), $label)
    }
    $raw = Read-Host 'Enter comma-separated numbers (or press Enter to cancel)'
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    $selectedIndexes = @($raw -split ',' | ForEach-Object { [int]$number = 0; if ([int]::TryParse($_.Trim(), [ref]$number)) { $number - 1 } })
    return @($selectedIndexes | Where-Object { $_ -ge 0 -and $_ -lt $Items.Count } | ForEach-Object { $Items[$_] })
}

function Invoke-WinForgeTuiTweak {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Key)

    foreach ($change in @(Get-WinForgeTweakChangeSet -Key $Key)) {
        if ($change.Kind -eq 'RegistryPath') {
            if ($change.Target -eq 'exists') { New-Item -Path $change.Path -Force | Out-Null }
            else { Remove-Item -LiteralPath $change.Path -Recurse -Force -ErrorAction SilentlyContinue }
        } elseif ($change.Kind -eq 'Registry') {
            if (-not (Test-Path -LiteralPath $change.Path)) { New-Item -Path $change.Path -Force | Out-Null }
            $property = Get-ItemProperty -LiteralPath $change.Path -Name $change.Name -ErrorAction SilentlyContinue
            if ($property) { Set-ItemProperty -LiteralPath $change.Path -Name $change.Name -Value $change.Target -Force }
            else { New-ItemProperty -LiteralPath $change.Path -Name $change.Name -Value $change.Target -PropertyType $change.Type -Force | Out-Null }
        }
    }
    switch ($Key) {
        'RestorePoint' { Checkpoint-Computer -Description 'WinForge Restore Point' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop }
        'Telemetry' { Stop-Service -Name 'DiagTrack' -Force -ErrorAction SilentlyContinue; Set-Service -Name 'DiagTrack' -StartupType Disabled -ErrorAction SilentlyContinue }
        'Hibernation' { & powercfg /h off 2>$null }
        'PS7Telemetry' { [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine') }
        'TempFiles' { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item 'C:\Windows\Temp\*' -Recurse -Force -ErrorAction SilentlyContinue }
        'ServicesManual' { foreach ($service in @('DiagTrack','dmwappushservice','SysMain','WSearch','MapsBroker','lfsvc','RetailDemo','wisvc')) { Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue; Stop-Service -Name $service -Force -ErrorAction SilentlyContinue } }
        'DiskCleanup' { Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/sagerun:1' -ErrorAction SilentlyContinue }
        'UltimatePower' { & powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null }
    }
}

function Start-WinForgeTui {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()

    if (-not $PSCmdlet.ShouldProcess('PowerShell 7 TUI', 'start interactive console')) { return }

    if (@($RunTweaks).Count -gt 0) {
        foreach ($key in @($RunTweaks)) { Invoke-WinForgeTuiTweak -Key $key }
        return
    }
    $apps = @($script:AppCategories.GetEnumerator() | ForEach-Object {
        $category = $_.Key
        $_.Value | ForEach-Object { [pscustomobject]@{ Category = $category; Name = $_.Name; Id = $_.Id } }
    })
    $tweaks = @($script:TweakCategories.GetEnumerator() | ForEach-Object {
        $category = $_.Key
        $_.Value | ForEach-Object {
            if ($_.Key -eq 'Recall' -and [System.Environment]::OSVersion.Version.Build -lt 26100) { return }
            [pscustomobject]@{ Category = $category; Name = $_.Name; Key = $_.Key }
        }
    })
    Write-WinForgeTui -Message 'WinForge PowerShell 7 TUI' -Color Magenta
    Write-WinForgeTui -Message 'ConsoleGuiTools is used automatically when Out-ConsoleGridView is available.' -Color DarkGray
    while ($true) {
        Write-WinForgeTui -Message "`n1. Install applications`n2. Apply tweaks`n3. Exit" -Color Cyan
        switch (Read-Host 'Choose an action') {
            '1' {
                $selectedApps = @(Select-WinForgeTuiItem -Items $apps -Title 'Select applications')
                if ($selectedApps.Count -eq 0) { continue }
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Warning 'winget is unavailable.'; continue }
                foreach ($app in $selectedApps) {
                    Write-WinForgeTui -Message ("Installing {0} ({1})..." -f $app.Name, $app.Id) -Color Yellow
                    & winget install --id $app.Id --exact --accept-source-agreements --accept-package-agreements
                }
            }
            '2' {
                $selectedTweaks = @(Select-WinForgeTuiItem -Items $tweaks -Title 'Select tweaks')
                if ($selectedTweaks.Count -eq 0) { continue }
                foreach ($tweak in $selectedTweaks) {
                    try { Invoke-WinForgeTuiTweak -Key $tweak.Key; Write-WinForgeTui -Message ("Applied: {0}" -f $tweak.Name) -Color Green }
                    catch { Write-Warning ("{0}: {1}" -f $tweak.Name, $_.Exception.Message) }
                }
            }
            '3' { return }
            default { Write-Warning 'Choose 1, 2, or 3.' }
        }
    }
}

if ($Tui) {
    Start-WinForgeTui
    exit
}

function Get-WinForgePlatformInfo {
    [CmdletBinding()]
    param()

    $build = [System.Environment]::OSVersion.Version.Build
    $caption = 'Windows'
    $edition = 'Unknown'
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $caption = [string]$os.Caption
        if ($os.BuildNumber) { $build = [int]$os.BuildNumber }
    } catch { Write-Debug ("Operating system query failed: {0}" -f $_.Exception.Message) }
    try {
        $currentVersion = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        if ($currentVersion.EditionID) { $edition = [string]$currentVersion.EditionID }
    } catch { Write-Debug ("Windows edition query failed: {0}" -f $_.Exception.Message) }
    $architecture = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    $isArm64 = $architecture -eq 'ARM64'
    $isWindows11 = ($build -ge 22000) -or ($caption -match 'Windows 11')
    [pscustomobject]@{
        Caption = $caption
        Edition = $edition
        Build = $build
        Architecture = $architecture
        IsWindows11 = $isWindows11
        IsArm64 = $isArm64
        RecallApplicable = ($isWindows11 -and $build -ge 26100)
    }
}

$script:PlatformInfo = Get-WinForgePlatformInfo

function Test-WinForgeTweakApplicable {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Key)

    if ($Key -eq 'Recall') { return [bool]$script:PlatformInfo.RecallApplicable }
    return $true
}

function New-WinForgeFirstLogonScript {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([string[]]$PackageIds, [string[]]$TweakKeys)
    if (-not $PSCmdlet.ShouldProcess('FirstLogonCommands payload', 'generate')) { return }

    $PackageIds = @($PackageIds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $TweakKeys = @($TweakKeys | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    $lines = @(
        '# WinForge FirstLogonCommands payload'
        '# Copy this file to %SystemDrive%\WinForge before applying the XML block.'
        '$ErrorActionPreference = ''Continue'''
        ''
    )
    if (@($PackageIds).Count -gt 0) {
        $lines += 'if (Get-Command winget -ErrorAction SilentlyContinue) {'
        foreach ($packageId in @($PackageIds)) {
            $safeId = $packageId.Replace("'", "''")
            $lines += ("    winget install --id '{0}' --exact --accept-source-agreements --accept-package-agreements --silent" -f $safeId)
        }
        $lines += '} else { Write-Warning ''winget is unavailable; package installation was skipped.'' }'
        $lines += ''
    }
    if (@($TweakKeys).Count -gt 0) {
        $tweakList = ($TweakKeys -join ',')
        $lines += ("`$winForgePath = Join-Path `$PSScriptRoot 'WinForge.ps1'")
        $lines += ("if (Test-Path -LiteralPath `$winForgePath) {{ & `$winForgePath -NoLaunch -RunTweaks {0} }} else {{ Write-Warning 'WinForge.ps1 was not copied beside this deployment script.' }}" -f $tweakList)
    }
    return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

function ConvertTo-WinForgeFirstLogonXml {
    [CmdletBinding()]
    param([string]$ScriptPath = '%SystemDrive%\WinForge\WinForge-FirstLogon.ps1')

    $escapedPath = [System.Security.SecurityElement]::Escape($ScriptPath)
    $command = '&quot;PowerShell.exe&quot; -NoProfile -ExecutionPolicy Bypass -File &quot;{0}&quot;' -f $escapedPath
    $xmlLines = @(
        '<?xml version="1.0" encoding="utf-8"?>'
        '<FirstLogonCommands xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">'
        '  <SynchronousCommand wcm:action="add">'
        '    <Order>1</Order>'
        '    <Description>Run WinForge provisioning payload</Description>'
        ("    <CommandLine>{0}</CommandLine>" -f $command)
        '  </SynchronousCommand>'
        '</FirstLogonCommands>'
    )
    return (($xmlLines -join [Environment]::NewLine) + [Environment]::NewLine)
}

function Export-WinForgeFirstLogonCommand {
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = 'Unattend XML block|*.xml'
    $dlg.FileName = 'WinForge-FirstLogonCommands.xml'
    if (-not $dlg.ShowDialog()) { return }
    $packageIds = @(Get-SelectedApps)
    $tweakKeys = @($script:TweakCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked -eq $true } | ForEach-Object { $_.Key })
    $folder = Split-Path -Parent $dlg.FileName
    $scriptPath = Join-Path $folder 'WinForge-FirstLogon.ps1'
    (New-WinForgeFirstLogonScript -PackageIds $packageIds -TweakKeys $tweakKeys) | Set-Content -LiteralPath $scriptPath -Encoding UTF8
    (ConvertTo-WinForgeFirstLogonXml) | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
    Write-Log ("[OK] FirstLogonCommands exported to {0}; companion script: {1}" -f $dlg.FileName, $scriptPath)
    Write-Log 'Copy the companion script and WinForge.ps1 to %SystemDrive%\WinForge on the target image.'
}

function Set-WinForgeConfigObject {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Config)

    foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
    foreach ($cb in $script:TweakCheckboxes.Values) { $cb.IsChecked = $false }
    if ($Config.WFApps) {
        foreach ($id in @($Config.WFApps)) {
            if ($script:AppCheckboxes.ContainsKey([string]$id)) { $script:AppCheckboxes[[string]$id].IsChecked = $true }
        }
    }
    if ($Config.WFTweaks) {
        foreach ($key in @($Config.WFTweaks)) {
            if ($script:TweakCheckboxes.ContainsKey([string]$key)) { $script:TweakCheckboxes[[string]$key].IsChecked = $true }
        }
    }
    $txtCustomArgs.Text = ''
    if ($Config.WFCustomArgs) {
        $customLines = foreach ($property in $Config.WFCustomArgs.PSObject.Properties) { "{0}={1}" -f $property.Name, $property.Value }
        $txtCustomArgs.Text = $customLines -join '; '
    }
}

function Get-WinForgeFleetPresetContent {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Source)

    if ($Source -match '^https?://') {
        return (Invoke-WebRequest -UseBasicParsing -Uri $Source -TimeoutSec 30 -ErrorAction Stop).Content
    }
    if (-not (Test-Path -LiteralPath $Source)) { throw "Fleet preset was not found: $Source" }
    return Get-Content -LiteralPath $Source -Raw -ErrorAction Stop
}

function Import-WinForgeFleetPreset {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Source)

    try {
        $config = Get-WinForgeFleetPresetContent -Source $Source | ConvertFrom-Json
        if (-not $config.WFApps -and -not $config.WFTweaks) { throw 'The preset does not contain WFApps or WFTweaks.' }
        Set-WinForgeConfigObject -Config $config
        if ($txtFleetPresetSource) { $txtFleetPresetSource.Text = $Source }
        Write-Log ("[OK] Fleet preset loaded from {0}." -f $Source)
        return $true
    } catch {
        Write-Log ("[!] Fleet preset load failed: {0}" -f $_.Exception.Message)
        return $false
    }
}

function Get-WinForgeRemoteTweakSelection {
    [CmdletBinding()]
    param([switch]$Audit)

    $keys = @($script:TweakCheckboxes.GetEnumerator() |
        Where-Object { $_.Value.IsChecked -eq $true } |
        ForEach-Object { $_.Key })
    if ($keys.Count -gt 0) { return $keys }
    if ($Audit) { return @(Get-WinForgeTweakKey) }
    return @()
}

function Invoke-WinForgeRemoteMachine {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ComputerName, [switch]$Audit)

    $keys = @(Get-WinForgeRemoteTweakSelection -Audit:$Audit)
    $changes = @($keys | ForEach-Object { Get-WinForgeTweakChangeSet -Key $_ } | Where-Object { $_.Kind -ne 'Action' })
    $packageIds = @(Get-SelectedApps)
    if (-not $Audit -and $keys.Count -eq 0 -and $packageIds.Count -eq 0) {
        Write-Log 'Select at least one application or tweak before applying to a remote machine.'
        return $false
    }
    try {
        Write-Log ("Connecting to {0} using current credentials..." -f $ComputerName)
        $session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
        if ($Audit) {
            $results = Invoke-Command -Session $session -ScriptBlock {
                param($RemoteChanges)
                foreach ($change in $RemoteChanges) {
                    $current = $null
                    $exists = Test-Path -LiteralPath $change.Path
                    if ($exists -and $change.Kind -eq 'RegistryPath') { $current = 'exists' }
                    elseif ($exists) {
                        $property = Get-ItemProperty -LiteralPath $change.Path -Name $change.Name -ErrorAction SilentlyContinue
                        if ($property) { $current = $property.PSObject.Properties[$change.Name].Value }
                    }
                    [pscustomobject]@{ Path = $change.Path; Name = $change.Name; Current = $current; Target = $change.Target; Applied = ($null -ne $current -and [string]$current -eq [string]$change.Target) }
                }
            } -ArgumentList (,$changes)
            foreach ($result in @($results)) { Write-Log ("[{0}] {1}\{2}: {3} (target {4})" -f (if ($result.Applied) { 'APPLIED' } else { 'NOT APPLIED' }), $result.Path, $result.Name, $result.Current, $result.Target) }
            Write-Log ("[OK] Remote audit complete for {0}." -f $ComputerName)
        } else {
            $remoteOutput = @(Invoke-Command -Session $session -ScriptBlock {
                param($RemotePackages, $RemoteChanges, $RemoteKeys)
                $ErrorActionPreference = 'Continue'
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    foreach ($id in $RemotePackages) { & winget install --id $id --exact --accept-source-agreements --accept-package-agreements --silent }
                }
                foreach ($change in $RemoteChanges) {
                    try {
                        if ($change.Kind -eq 'RegistryPath') {
                            if ($change.Target -eq 'exists') { New-Item -Path $change.Path -Force | Out-Null }
                            else { Remove-Item -LiteralPath $change.Path -Recurse -Force -ErrorAction SilentlyContinue }
                        } elseif ($null -ne $change.Target) {
                            if (-not (Test-Path -LiteralPath $change.Path)) { New-Item -Path $change.Path -Force | Out-Null }
                            if (Get-ItemProperty -LiteralPath $change.Path -Name $change.Name -ErrorAction SilentlyContinue) { Set-ItemProperty -LiteralPath $change.Path -Name $change.Name -Value $change.Target -Force }
                            else { New-ItemProperty -LiteralPath $change.Path -Name $change.Name -Value $change.Target -PropertyType $change.Type -Force | Out-Null }
                        }
                    } catch { Write-Warning ("Registry change failed for {0}\{1}: {2}" -f $change.Path, $change.Name, $_.Exception.Message) }
                }
                foreach ($key in $RemoteKeys) {
                    switch ($key) {
                        'RestorePoint' { try { Checkpoint-Computer -Description 'WinForge Restore Point' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop } catch { Write-Warning ("Restore point failed: {0}" -f $_.Exception.Message) } }
                        'Telemetry' { Stop-Service -Name 'DiagTrack' -Force -ErrorAction SilentlyContinue; Set-Service -Name 'DiagTrack' -StartupType Disabled -ErrorAction SilentlyContinue }
                        'Hibernation' { & powercfg /h off 2>$null }
                        'PS7Telemetry' { [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','1','Machine') }
                        'TempFiles' { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item 'C:\Windows\Temp\*' -Recurse -Force -ErrorAction SilentlyContinue }
                        'ServicesManual' { foreach ($service in @('DiagTrack','dmwappushservice','SysMain','WSearch','MapsBroker','lfsvc','RetailDemo','wisvc')) { Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue; Stop-Service -Name $service -Force -ErrorAction SilentlyContinue } }
                        'DiskCleanup' { Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/sagerun:1' -WindowStyle Hidden -ErrorAction SilentlyContinue }
                        'UltimatePower' { & powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null; $plans = & powercfg /list 2>$null | Out-String; if ($plans -match '([0-9a-f-]{36}).*Ultimate') { & powercfg /setactive $Matches[1] 2>$null } }
                    }
                }
            } -ArgumentList (,$packageIds), (,$changes), (,$keys))
            foreach ($line in $remoteOutput) { if ($line) { Write-Log ("[remote] {0}" -f $line) } }
            Write-Log ("[OK] Remote apply completed for {0}." -f $ComputerName)
        }
        Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        return $true
    } catch {
        if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
        Write-Log ("[!] Remote operation failed: {0}" -f $_.Exception.Message)
        return $false
    }
}

function Register-WinForgeDailyUpgradeTask {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()
    if (-not $PSCmdlet.ShouldProcess('WinForge Daily Package Upgrade', 'register scheduled task')) { return }
    $taskCommand = 'PowerShell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "& { winget upgrade --all --accept-source-agreements --accept-package-agreements --silent; if (Get-Command choco -ErrorAction SilentlyContinue) { choco upgrade all --yes --no-progress } }"'
    $taskArgs = @('/Create','/TN','WinForge Daily Package Upgrade','/SC','DAILY','/ST','12:00','/RU','SYSTEM','/RL','HIGHEST','/TR',$taskCommand,'/F')
    try {
        $process = Start-Process -FilePath 'schtasks.exe' -ArgumentList $taskArgs -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop
        if ($process.ExitCode -eq 0) { Write-Log '[OK] Daily package upgrade task registered for 12:00.' }
        else { Write-Log ("[!] Scheduled task registration returned exit code {0}." -f $process.ExitCode) }
    } catch { Write-Log ("[!] Could not register scheduled task: {0}" -f $_.Exception.Message) }
}

function Repair-WinForgeWinget {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()
    if (-not $PSCmdlet.ShouldProcess('Microsoft Desktop App Installer', 're-register App Installer')) { return }
    try {
        $packages = @(Get-AppxPackage -Name 'Microsoft.DesktopAppInstaller' -AllUsers -ErrorAction Stop)
        if ($packages.Count -eq 0) { throw 'Microsoft.DesktopAppInstaller was not found.' }
        foreach ($package in $packages) {
            $manifest = Join-Path $package.InstallLocation 'AppXManifest.xml'
            if (Test-Path -LiteralPath $manifest) {
                Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop
            }
        }
        Write-Log '[OK] App Installer was re-registered. Restart WinForge and retry winget.'
    } catch { Write-Log ("[!] Winget repair failed: {0}" -f $_.Exception.Message) }
}

function Start-WinForgeHealthCheck {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()
    if (-not $PSCmdlet.ShouldProcess('local Windows installation', 'run health check')) { return }
    if ($script:HealthJob) { Write-Log 'A health check is already running.'; return }
    Write-Log 'Starting post-install health check (SFC verify, DISM CheckHealth, firewall audit)...'
    $script:HealthJob = Start-Job -ScriptBlock {
        $report = @('WinForge Post-install Health Report', ('Generated: {0}' -f (Get-Date).ToString('o')), '')
        $report += '=== SFC /verifyonly ==='
        try { $report += (& sfc /verifyonly 2>&1 | Out-String).Trim() } catch { $report += $_.Exception.Message }
        $report += ''; $report += '=== DISM /CheckHealth ==='
        try { $report += (& DISM /Online /Cleanup-Image /CheckHealth 2>&1 | Out-String).Trim() } catch { $report += $_.Exception.Message }
        $report += ''; $report += '=== Firewall Profiles ==='
        try { $report += (Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction | Format-Table -AutoSize | Out-String).Trim() } catch { $report += $_.Exception.Message }
        return $report
    }
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(750)
    $timer.Tag = @{ Job = $script:HealthJob; Timer = $timer }
    $timer.Add_Tick({
        if ($this.Tag.Job.State -in @('Completed','Failed','Stopped')) {
            $this.Stop()
            $report = @(Receive-Job -Job $this.Tag.Job -ErrorAction SilentlyContinue)
            Remove-Job -Job $this.Tag.Job -Force -ErrorAction SilentlyContinue
            $directory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinForge'
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
            $path = Join-Path $directory ('health-report-{0:yyyyMMdd-HHmmss}.txt' -f (Get-Date))
            $report | Set-Content -LiteralPath $path -Encoding UTF8
            foreach ($line in $report | Select-Object -First 30) { if ($line) { Write-Log ([string]$line) } }
            Write-Log ("[OK] Health report saved to {0}" -f $path)
            $script:HealthJob = $null
        }
    }.GetNewClosure())
    $timer.Start()
}

function Get-WinForgeCrashLogPath {
    [CmdletBinding()]
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path)) { return $Path }
    return (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinForge\crash.log')
}

function Write-WinForgeCrashLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Exception]$Exception,
        [string]$Context = 'Unhandled exception',
        [string]$Path
    )

    $logPath = Get-WinForgeCrashLogPath -Path $Path
    try {
        $directory = Split-Path -Parent $logPath
        if (-not [string]::IsNullOrWhiteSpace($directory)) { New-Item -Path $directory -ItemType Directory -Force | Out-Null }
        $entry = @(
            '=== WinForge crash report ==='
            ('Timestamp: {0}' -f (Get-Date).ToString('o'))
            ('Version: {0}' -f $script:WinForgeVersion)
            ('Context: {0}' -f $Context)
            ('Computer: {0}' -f $env:COMPUTERNAME)
            ('User: {0}\{1}' -f $env:USERDOMAIN, $env:USERNAME)
            ''
            $Exception.ToString()
            ''
        ) -join [Environment]::NewLine
        Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8
        if ((Get-Item -LiteralPath $logPath).Length -gt 5MB) {
            $tail = @(Get-Content -LiteralPath $logPath -Tail 4000)
            $tail | Set-Content -LiteralPath $logPath -Encoding UTF8
        }
        return $logPath
    } catch {
        Write-Debug ("WinForge crash log write failed: {0}" -f $_.Exception.Message)
        return $false
    }
}

function Get-WinForgeCrashReport {
    [CmdletBinding()]
    param([string]$Path)

    $logPath = Get-WinForgeCrashLogPath -Path $Path
    if (-not (Test-Path -LiteralPath $logPath)) { return $null }
    try { return (Get-Content -LiteralPath $logPath -Raw -ErrorAction Stop) }
    catch {
        Write-Debug ("WinForge crash log read failed: {0}" -f $_.Exception.Message)
        return $null
    }
}

function Copy-WinForgeCrashReport {
    [CmdletBinding()]
    param([string]$Path)

    $report = Get-WinForgeCrashReport -Path $Path
    if ([string]::IsNullOrWhiteSpace($report)) {
        if ($txtLog) { Write-Log 'No crash report is available to copy.' }
        return $false
    }
    try {
        [System.Windows.Clipboard]::SetText($report)
        if ($txtLog) { Write-Log 'Crash report copied to the clipboard. Review it before sharing.' }
        return $true
    } catch {
        if ($txtLog) { Write-Log ("[!] Could not copy the crash report: {0}" -f $_.Exception.Message) }
        return $false
    }
}

# ── Core helpers ──────────────────────────────────────────────────────────────
# These helpers intentionally avoid WPF state so they can be exercised by the
# headless test harness and reused by background package workers.
function ConvertFrom-WinForgeCustomArgument {
    [CmdletBinding()]
    param([AllowNull()][string]$Text)

    $result = @{}
    if ([string]::IsNullOrWhiteSpace($Text)) { return $result }

    foreach ($entry in ($Text -split '\r?\n|;')) {
        $line = $entry.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
        $parts = $line -split '\s*=\s*', 2
        if ($parts.Count -eq 2 -and -not [string]::IsNullOrWhiteSpace($parts[0])) {
            $result[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
    return $result
}

function Get-WinForgeLevenshteinDistance {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Left, [Parameter(Mandatory)][string]$Right)

    $leftValue = $Left.ToLowerInvariant()
    $rightValue = $Right.ToLowerInvariant()
    $previous = [int[]](0..$rightValue.Length)

    for ($i = 1; $i -le $leftValue.Length; $i++) {
        $current = [int[]]::new($rightValue.Length + 1)
        $current[0] = $i
        for ($j = 1; $j -le $rightValue.Length; $j++) {
            $cost = if ($leftValue[$i - 1] -eq $rightValue[$j - 1]) { 0 } else { 1 }
            $insert = $current[$j - 1] + 1
            $delete = $previous[$j] + 1
            $replace = $previous[$j - 1] + $cost
            $current[$j] = [math]::Min($insert, [math]::Min($delete, $replace))
        }
        $previous = $current
    }
    return $previous[$rightValue.Length]
}

function Get-WinForgeFuzzyScore {
    [CmdletBinding()]
    param([AllowNull()][string]$Text, [AllowNull()][string]$Query)

    if ([string]::IsNullOrWhiteSpace($Text) -or [string]::IsNullOrWhiteSpace($Query)) { return 0.0 }
    $candidate = $Text.ToLowerInvariant().Trim()
    $queryValue = $Query.ToLowerInvariant().Trim()
    if ($candidate.Contains($queryValue)) { return 1.0 }

    $candidateTokens = @($candidate -split '[^a-z0-9]+') | Where-Object { $_.Length -gt 0 }
    $queryTokens = @($queryValue -split '[^a-z0-9]+') | Where-Object { $_.Length -gt 0 }
    $best = 0.0
    foreach ($queryToken in $queryTokens) {
        if ($queryToken.Length -lt 2) { continue }
        foreach ($candidateToken in $candidateTokens) {
            if ($candidateToken.Contains($queryToken) -or $queryToken.Contains($candidateToken)) {
                $score = [math]::Min($queryToken.Length, $candidateToken.Length) /
                    [double][math]::Max($queryToken.Length, $candidateToken.Length)
            } else {
                $length = [math]::Max($queryToken.Length, $candidateToken.Length)
                $score = if ($length -eq 0) { 0.0 } else {
                    1.0 - (Get-WinForgeLevenshteinDistance $queryToken $candidateToken) / [double]$length
                }
            }
            if ($score -gt $best) { $best = $score }
        }
    }
    return [math]::Round($best, 3)
}

function Get-WinForgePackageManagerOrder {
    return @('winget', 'scoop', 'choco')
}

function ConvertTo-WinForgeWingetConfiguration {
    [CmdletBinding()]
    param([string[]]$PackageIds)

    $lines = @(
        '$schema: https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2023/08/config/document.json'
        'metadata:'
        '  winget:'
        '    processor:'
        '      identifier: dscv3'
        'resources:'
    )
    $index = 0
    foreach ($packageId in @($PackageIds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        $index++
        $safeName = ($packageId -replace '[^A-Za-z0-9_-]', '-')
        if ([string]::IsNullOrWhiteSpace($safeName)) { $safeName = "Package$index" }
        $lines += @(
            ("- type: Microsoft.WinGet/Package"),
            ("  name: {0}-{1}" -f $safeName, $index),
            '  properties:',
            ("    id: {0}" -f $packageId),
            '    source: winget',
            '    useLatest: true',
            '  metadata:',
            ("    description: Install {0}" -f $packageId)
        )
    }
    return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

function ConvertFrom-WinForgeWingetConfiguration {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Content)

    $ids = @()
    foreach ($line in ($Content -split '\r?\n')) {
        # Support both DSC v3 (id) and older WinGet configuration exports
        # (packageIdentifier) so existing profiles remain portable.
        if ($line -match '^\s+(?:id|packageIdentifier):\s*["'']?([^"''\s]+)["'']?\s*$') {
            $value = $Matches[1].Trim()
            if ($value -and $ids -notcontains $value) { $ids += $value }
        }
    }
    return $ids
}

# The worker is self-contained because Start-Job serializes the script into a
# separate PowerShell process. It emits LOG records while running and one final
# RESULT object, allowing the UI to show per-package output as it arrives.
$script:PackageInstallWorker = {
    param(
        [string]$PackageName,
        [string]$PackageId,
        [string]$CustomArgs,
        [string[]]$ManagerOrder
    )

    function Write-WorkerLog {
        param([string]$Message)
        Write-Output ("LOG|{0}" -f $Message)
    }

    function Get-CustomToken {
        param([string]$Text)
        if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
        $tokens = @()
        foreach ($match in [regex]::Matches($Text.Trim(), '"(?:\\.|[^"])*"|\S+')) {
            $tokens += $match.Value.Trim('"')
        }
        return $tokens
    }

    function Get-Verification {
        param([string]$Name, [string]$Id)
        $safeName = [regex]::Escape($Name)
        $uninstallRoots = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
        foreach ($root in $uninstallRoots) {
            $match = Get-ItemProperty -Path $root -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -and $_.DisplayName -match $safeName } |
                Select-Object -First 1
            if ($match) { return 'registry' }
        }

        $exeCandidates = @()
        switch -Regex ($Id) {
            'Google\.Chrome' { $exeCandidates += 'chrome.exe' }
            'Mozilla\.Firefox' { $exeCandidates += 'firefox.exe' }
            'Brave\.Brave' { $exeCandidates += 'brave.exe' }
            'Microsoft\.Edge' { $exeCandidates += 'msedge.exe' }
            'VideoLAN\.VLC' { $exeCandidates += 'vlc.exe' }
            '7zip\.7zip' { $exeCandidates += @('7zFM.exe','7z.exe') }
            'Git\.Git' { $exeCandidates += 'git.exe' }
            'Microsoft\.VisualStudioCode' { $exeCandidates += 'code.exe' }
            'Microsoft\.PowerShell' { $exeCandidates += 'pwsh.exe' }
            'GIMP\.GIMP' { $exeCandidates += 'gimp.exe' }
            'OBSProject\.OBSStudio' { $exeCandidates += 'obs64.exe' }
            'Valve\.Steam' { $exeCandidates += 'steam.exe' }
        }
        foreach ($candidate in $exeCandidates) {
            if (Get-Command $candidate -ErrorAction SilentlyContinue) { return 'executable' }
            $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)
            foreach ($root in $roots) {
                if ($root -and (Test-Path (Join-Path $root $candidate))) { return 'executable' }
            }
        }

        # A package-manager record is still useful for Store/MSIX packages that
        # do not expose a conventional uninstall entry or PATH executable.
        $listed = & winget list --id $Id --exact --accept-source-agreements 2>$null | Out-String
        if ($LASTEXITCODE -eq 0 -and $listed -match [regex]::Escape($Id)) { return 'package-manager' }
        return 'unverified'
    }

    if (-not $ManagerOrder -or $ManagerOrder.Count -eq 0) {
        $ManagerOrder = @('winget', 'scoop', 'choco')
    }
    $customValue = if ([string]::IsNullOrWhiteSpace($CustomArgs)) { $null } else { $CustomArgs.Trim() }
    $customTokens = Get-CustomToken $customValue
    $attempts = @()
    foreach ($manager in $ManagerOrder) {
        $command = Get-Command $manager -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $command) {
            Write-WorkerLog ("{0} is not installed; skipping." -f $manager)
            continue
        }

        $commandArgs = @()
        if ($manager -eq 'winget') {
            Write-WorkerLog ("Checking {0} in winget..." -f $PackageId)
            $probeOutput = & $command.Source show --id $PackageId --exact --accept-source-agreements 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($probeOutput)) {
                Write-WorkerLog ("winget could not resolve {0}; trying the next provider." -f $PackageId)
                $attempts += 'winget:unresolved'
                continue
            }
            $commandArgs = @('install','--id',$PackageId,'--exact','--accept-source-agreements','--accept-package-agreements','--silent')
            if ($customValue) { $commandArgs += @('--custom', $customValue) }
        } elseif ($manager -eq 'scoop') {
            $commandArgs = @('install', $PackageId)
            if ($customTokens.Count -gt 0) { $commandArgs += $customTokens }
        } elseif ($manager -eq 'choco') {
            $commandArgs = @('install', $PackageId, '--yes', '--no-progress')
            if ($customTokens.Count -gt 0) { $commandArgs += $customTokens }
        } else {
            continue
        }

        Write-WorkerLog ("Installing via {0}..." -f $manager)
        $lines = & $command.Source @commandArgs 2>&1
        foreach ($line in $lines) { Write-WorkerLog ([string]$line) }
        $exitCode = $LASTEXITCODE
        $attempts += ("{0}:{1}" -f $manager, $exitCode)
        if ($exitCode -eq 0) {
            $verification = Get-Verification $PackageName $PackageId
            Write-WorkerLog ("Verification: {0}." -f $verification)
            Write-Output ([pscustomobject]@{
                Kind = 'Result'
                Success = $true
                PackageName = $PackageName
                PackageId = $PackageId
                Provider = $manager
                Verification = $verification
                Attempts = ($attempts -join ', ')
            })
            return
        }
        Write-WorkerLog ("{0} failed with exit code {1}; trying the next provider." -f $manager, $exitCode)
    }

    Write-Output ([pscustomobject]@{
        Kind = 'Result'
        Success = $false
        PackageName = $PackageName
        PackageId = $PackageId
        Provider = ''
        Verification = 'failed'
        Attempts = ($attempts -join ', ')
    })
}

# ── XAML ───────────────────────────────────────────────────────────────────────
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinForge v0.2.0" Width="1100" Height="740" MinWidth="900" MinHeight="600"
        WindowStartupLocation="CenterScreen" Background="{DynamicResource Theme.Window}"
        FontFamily="Segoe UI" FontSize="13">
    <Window.Resources>
        <!-- Theme brushes are replaced at runtime by Set-WinForgeTheme. -->
        <SolidColorBrush x:Key="Theme.Window" Color="#0d0d12"/>
        <SolidColorBrush x:Key="Theme.Shell" Color="#0a0a14"/>
        <SolidColorBrush x:Key="Theme.ShellDeep" Color="#08080e"/>
        <SolidColorBrush x:Key="Theme.Surface" Color="#0d0d16"/>
        <SolidColorBrush x:Key="Theme.Card" Color="#12121e"/>
        <SolidColorBrush x:Key="Theme.Toolbar" Color="#0b0b14"/>
        <SolidColorBrush x:Key="Theme.LogHeader" Color="#0c0c16"/>
        <SolidColorBrush x:Key="Theme.Input" Color="#1e1e2e"/>
        <SolidColorBrush x:Key="Theme.InputPopup" Color="#1a1a2e"/>
        <SolidColorBrush x:Key="Theme.Border" Color="#333346"/>
        <SolidColorBrush x:Key="Theme.Divider" Color="#1e1e36"/>
        <SolidColorBrush x:Key="Theme.Hover" Color="#282840"/>
        <SolidColorBrush x:Key="Theme.PanelPressed" Color="#282844"/>
        <SolidColorBrush x:Key="Theme.NavHover" Color="#18182a"/>
        <SolidColorBrush x:Key="Theme.Panel" Color="#16162a"/>
        <SolidColorBrush x:Key="Theme.PanelBorder" Color="#2a2a42"/>
        <SolidColorBrush x:Key="Theme.Text" Color="#d4d4e8"/>
        <SolidColorBrush x:Key="Theme.TextBright" Color="#e8e8f0"/>
        <SolidColorBrush x:Key="Theme.TextMuted" Color="#8888a0"/>
        <SolidColorBrush x:Key="Theme.TextSubtle" Color="#666680"/>
        <SolidColorBrush x:Key="Theme.TextFaint" Color="#555570"/>
        <SolidColorBrush x:Key="Theme.Label" Color="#444460"/>
        <SolidColorBrush x:Key="Theme.Arrow" Color="#9999aa"/>
        <SolidColorBrush x:Key="Theme.Accent" Color="#6c5ce7"/>
        <SolidColorBrush x:Key="Theme.AccentHover" Color="#7c6ff0"/>
        <SolidColorBrush x:Key="Theme.AccentPressed" Color="#5a4bd4"/>
        <SolidColorBrush x:Key="Theme.AccentText" Color="#a78bfa"/>
        <SolidColorBrush x:Key="Theme.White" Color="#ffffff"/>
        <SolidColorBrush x:Key="Theme.Danger" Color="#dc2626"/>
        <SolidColorBrush x:Key="Theme.DangerHover" Color="#ef4444"/>
        <SolidColorBrush x:Key="Theme.DangerPressed" Color="#b91c1c"/>
        <SolidColorBrush x:Key="Theme.SuccessButton" Color="#16a34a"/>
        <SolidColorBrush x:Key="Theme.SuccessButtonHover" Color="#22c55e"/>
        <SolidColorBrush x:Key="Theme.SuccessButtonPressed" Color="#15803d"/>
        <SolidColorBrush x:Key="Theme.Log" Color="#4ade80"/>
        <SolidColorBrush x:Key="Theme.Warning" Color="#facc15"/>
        <SolidColorBrush x:Key="Theme.RiskRed" Color="#f87171"/>

        <!-- ComboBox Toggle Button Template -->
        <ControlTemplate x:Key="ComboBoxToggleButton" TargetType="ToggleButton">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition/>
                    <ColumnDefinition Width="20"/>
                </Grid.ColumnDefinitions>
                <Border x:Name="Border" Grid.ColumnSpan="2" Background="{DynamicResource Theme.Input}" BorderBrush="{DynamicResource Theme.Border}" BorderThickness="1" CornerRadius="4"/>
                <Border Grid.Column="0" Background="{DynamicResource Theme.Input}" BorderBrush="Transparent" BorderThickness="0" CornerRadius="4,0,0,4" Margin="1"/>
                <Path x:Name="Arrow" Grid.Column="1" Fill="{DynamicResource Theme.Arrow}" HorizontalAlignment="Center" VerticalAlignment="Center" Data="M0,0 L4,4 L8,0 Z"/>
            </Grid>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="Border" Property="Background" Value="{DynamicResource Theme.Hover}"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>
        <ControlTemplate x:Key="ComboBoxTemplate" TargetType="ComboBox">
            <Grid>
                <ToggleButton Name="ToggleButton" Template="{StaticResource ComboBoxToggleButton}"
                              Focusable="False" ClickMode="Press"
                              IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"/>
                <ContentPresenter Name="ContentSite" IsHitTestVisible="False"
                                  Content="{TemplateBinding SelectionBoxItem}"
                                  ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                  Margin="8,3,25,3" VerticalAlignment="Center" HorizontalAlignment="Left"/>
                <Popup Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}"
                       AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                    <Grid Name="DropDown" SnapsToDevicePixels="True"
                          MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}">
                        <Border x:Name="DropDownBorder" Background="{DynamicResource Theme.InputPopup}" BorderThickness="1" BorderBrush="{DynamicResource Theme.Border}" CornerRadius="4">
                            <Border.Effect>
                                <DropShadowEffect Color="Black" BlurRadius="12" ShadowDepth="3" Opacity="0.6"/>
                            </Border.Effect>
                        </Border>
                        <ScrollViewer Margin="4,6,4,6" SnapsToDevicePixels="True">
                            <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                        </ScrollViewer>
                    </Grid>
                </Popup>
            </Grid>
        </ControlTemplate>
        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
            <Setter Property="Background" Value="{DynamicResource Theme.Input}"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="Template" Value="{StaticResource ComboBoxTemplate}"/>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}" CornerRadius="3" Margin="0,1">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Theme.Hover}"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Theme.Hover}"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Theme.Accent}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <!-- Global Styles -->
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{DynamicResource Theme.Input}"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource Theme.Border}"/>
            <Setter Property="CaretBrush" Value="{DynamicResource Theme.White}"/>
            <Setter Property="SelectionBrush" Value="{DynamicResource Theme.Accent}"/>
            <Setter Property="Padding" Value="8,6"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
            <Setter Property="Margin" Value="0,3"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
        </Style>
        <Style TargetType="ToolTip">
            <Setter Property="Background" Value="{DynamicResource Theme.InputPopup}"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource Theme.Border}"/>
        </Style>
        <Style x:Key="AccentBtn" TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource Theme.Accent}"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.White}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="20,10"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.AccentHover}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.AccentPressed}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="SecondaryBtn" TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource Theme.Input}"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="{DynamicResource Theme.Border}"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.Hover}"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource Theme.Accent}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.Border}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="DangerBtn" TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource Theme.Danger}"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.White}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.DangerHover}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.DangerPressed}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="SuccessBtn" TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource Theme.SuccessButton}"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.White}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.SuccessButtonHover}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.SuccessButtonPressed}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="NavBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.TextMuted}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="18,12"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Medium"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}" Margin="4,1">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.NavHover}"/>
                                <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="NavBtnActive" TargetType="Button" BasedOn="{StaticResource NavBtn}">
            <Setter Property="Background" Value="{DynamicResource Theme.Divider}"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.AccentText}"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>
        <Style x:Key="PanelBtn" TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource Theme.Panel}"/>
            <Setter Property="Foreground" Value="{DynamicResource Theme.Text}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="{DynamicResource Theme.PanelBorder}"/>
            <Setter Property="Padding" Value="14,10"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.Divider}"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource Theme.Accent}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="{DynamicResource Theme.PanelPressed}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="8"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="200"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Left Sidebar -->
        <Border Grid.Column="0" Background="{DynamicResource Theme.Shell}" BorderBrush="{DynamicResource Theme.InputPopup}" BorderThickness="0,0,1,0">
            <DockPanel>
                <!-- Logo Area -->
                <Border DockPanel.Dock="Top" Padding="16,20,16,16">
                    <StackPanel>
                        <TextBlock Text="WINFORGE" FontSize="20" FontWeight="Bold" Foreground="{DynamicResource Theme.AccentText}" Margin="0,0,0,2"/>
                        <TextBlock Text="v0.2.0" FontSize="10" Foreground="{DynamicResource Theme.TextFaint}"/>
                        <Border Height="1" Background="{DynamicResource Theme.Divider}" Margin="0,14,0,10"/>
                    </StackPanel>
                </Border>

                <!-- Version Info at Bottom -->
                <Border DockPanel.Dock="Bottom" Padding="16,10" Background="{DynamicResource Theme.ShellDeep}">
                    <StackPanel>
                        <TextBlock x:Name="txtSysInfo" Text="" FontSize="10" Foreground="{DynamicResource Theme.TextFaint}" TextWrapping="Wrap"/>
                    </StackPanel>
                </Border>

                <!-- Navigation -->
                <StackPanel Margin="6,0">
                    <TextBlock Text="NAVIGATION" FontSize="9" Foreground="{DynamicResource Theme.Label}" FontWeight="Bold" Margin="14,4,0,8"/>
                    <Button x:Name="navInstall" Content="  Install" Style="{StaticResource NavBtnActive}"/>
                    <Button x:Name="navTweaks"  Content="  Tweaks" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navConfig"  Content="  Config" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navDeploy"  Content="  Deploy" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navUpdates" Content="  Updates" Style="{StaticResource NavBtn}"/>
                    <Border Height="1" Background="{DynamicResource Theme.Divider}" Margin="8,12"/>
                    <TextBlock Text="QUICK ACTIONS" FontSize="9" Foreground="{DynamicResource Theme.Label}" FontWeight="Bold" Margin="14,4,0,8"/>
                    <Button x:Name="navExport"  Content="  Export Config" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navImport"  Content="  Import Config" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navExportWinget" Content="  Export WinGet" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="navImportWinget" Content="  Import WinGet" Style="{StaticResource NavBtn}"/>
                    <Button x:Name="btnCopyCrashReport" Content="  Copy Crash Report" Style="{StaticResource NavBtn}"/>
                    <TextBlock Text="APPEARANCE" FontSize="9" Foreground="{DynamicResource Theme.Label}" FontWeight="Bold" Margin="14,12,0,6"/>
                    <ComboBox x:Name="cmbTheme" Width="160" Margin="10,0,10,8">
                        <ComboBoxItem Content="Dark" IsSelected="True"/>
                        <ComboBoxItem Content="Light"/>
                        <ComboBoxItem Content="High Contrast"/>
                    </ComboBox>
                </StackPanel>
            </DockPanel>
        </Border>

        <!-- Main Content -->
        <DockPanel Grid.Column="1">

            <!-- System Info Header -->
            <Border DockPanel.Dock="Top" Background="{DynamicResource Theme.Shell}" BorderBrush="{DynamicResource Theme.InputPopup}" BorderThickness="0,0,0,1" Padding="20,12">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Grid.RowDefinitions>
                        <RowDefinition/>
                        <RowDefinition/>
                    </Grid.RowDefinitions>
                    <StackPanel Grid.Column="0" Grid.Row="0" Margin="0,0,16,4">
                        <TextBlock Text="COMPUTER" FontSize="9" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold"/>
                        <TextBlock x:Name="infoComputer" Text="..." FontSize="11.5" Foreground="{DynamicResource Theme.TextBright}"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Grid.Row="0" Margin="0,0,16,4">
                        <TextBlock Text="OS / BUILD" FontSize="9" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold"/>
                        <TextBlock x:Name="infoOS" Text="..." FontSize="11.5" Foreground="{DynamicResource Theme.TextBright}"/>
                    </StackPanel>
                    <StackPanel Grid.Column="2" Grid.Row="0" Margin="0,0,16,4">
                        <TextBlock Text="CPU" FontSize="9" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold"/>
                        <TextBlock x:Name="infoCPU" Text="..." FontSize="11.5" Foreground="{DynamicResource Theme.TextBright}" TextTrimming="CharacterEllipsis"/>
                    </StackPanel>
                    <StackPanel Grid.Column="3" Grid.Row="0" Margin="0,0,0,4">
                        <TextBlock Text="RAM" FontSize="9" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold"/>
                        <TextBlock x:Name="infoRAM" Text="..." FontSize="11.5" Foreground="{DynamicResource Theme.TextBright}"/>
                    </StackPanel>
                    <StackPanel Grid.Column="0" Grid.Row="1" Margin="0,4,16,0">
                        <TextBlock Text="USER" FontSize="9" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold"/>
                        <TextBlock x:Name="infoUser" Text="..." FontSize="11.5" Foreground="{DynamicResource Theme.TextBright}"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Grid.Row="1" Margin="0,4,16,0">
                        <TextBlock Text="DOMAIN / WORKGROUP" FontSize="9" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold"/>
                        <TextBlock x:Name="infoDomain" Text="..." FontSize="11.5" Foreground="{DynamicResource Theme.TextBright}"/>
                    </StackPanel>
                    <StackPanel Grid.Column="2" Grid.Row="1" Margin="0,4,16,0" Grid.ColumnSpan="2">
                        <TextBlock Text="STORAGE" FontSize="9" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold"/>
                        <TextBlock x:Name="infoStorage" Text="..." FontSize="11.5" Foreground="{DynamicResource Theme.TextBright}"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- Bottom Log Panel -->
            <Border DockPanel.Dock="Bottom" Background="{DynamicResource Theme.ShellDeep}" BorderBrush="{DynamicResource Theme.InputPopup}" BorderThickness="0,1,0,0" MaxHeight="160">
                <DockPanel>
                    <Border DockPanel.Dock="Top" Padding="12,6" Background="{DynamicResource Theme.LogHeader}">
                        <DockPanel>
                            <TextBlock Text="OUTPUT LOG" FontSize="10" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold" VerticalAlignment="Center"/>
                            <Button x:Name="btnClearLog" Content="Clear" Style="{StaticResource SecondaryBtn}" Padding="10,3" FontSize="10" HorizontalAlignment="Right" DockPanel.Dock="Right"/>
                        </DockPanel>
                    </Border>
                    <TextBox x:Name="txtLog" IsReadOnly="True" Background="Transparent"
                             Foreground="{DynamicResource Theme.Log}" FontFamily="Cascadia Mono,Consolas" FontSize="11"
                             TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"
                             BorderThickness="0" Padding="12,6" AcceptsReturn="True"/>
                </DockPanel>
            </Border>

            <!-- Page Container -->
            <Grid x:Name="pageContainer" Margin="0">

                <!-- INSTALL PAGE -->
                <Grid x:Name="pageInstall" Visibility="Visible">
                    <DockPanel>
                        <!-- Top Bar -->
                        <Border DockPanel.Dock="Top" Padding="24,18,24,14" Background="{DynamicResource Theme.Surface}">
                            <DockPanel>
                                <StackPanel>
                                    <TextBlock Text="Install Programs" FontSize="22" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}"/>
                                    <TextBlock Text="Select applications and install them with one click via winget" FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" Margin="0,4,0,0"/>
                                </StackPanel>
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" DockPanel.Dock="Right" VerticalAlignment="Center">
                                    <TextBox x:Name="txtSearch" Width="220" Height="32" Tag="Search applications..."
                                             VerticalContentAlignment="Center" Margin="0,0,10,0"/>
                                    <Button x:Name="btnSelectAll" Content="Select All" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnDeselectAll" Content="Clear All" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnInstallSelected" Content="  Install Selected" Style="{StaticResource AccentBtn}"/>
                                </StackPanel>
                            </DockPanel>
                        </Border>
                        <!-- Preset Buttons -->
                        <Border DockPanel.Dock="Top" Padding="24,8,24,8" Background="{DynamicResource Theme.Toolbar}">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Text="PRESETS:" FontSize="10" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                <Button x:Name="btnPresetDev" Content="Developer" Style="{StaticResource SecondaryBtn}" Padding="12,5" FontSize="11" Margin="0,0,6,0"/>
                                <Button x:Name="btnPresetGamer" Content="Gamer" Style="{StaticResource SecondaryBtn}" Padding="12,5" FontSize="11" Margin="0,0,6,0"/>
                                <Button x:Name="btnPresetProd" Content="Productivity" Style="{StaticResource SecondaryBtn}" Padding="12,5" FontSize="11" Margin="0,0,6,0"/>
                                <Button x:Name="btnPresetBasic" Content="Essentials" Style="{StaticResource SecondaryBtn}" Padding="12,5" FontSize="11" Margin="0,0,6,0"/>
                                <Border Width="1" Background="{DynamicResource Theme.Border}" Margin="8,2"/>
                                <Button x:Name="btnUpgradeAll" Content="  Upgrade All" Style="{StaticResource SuccessBtn}" Padding="12,5" FontSize="11" Margin="6,0,0,0"/>
                                <Button x:Name="btnUninstallSelected" Content="  Uninstall Selected" Style="{StaticResource DangerBtn}" Padding="12,5" FontSize="11" Margin="6,0,0,0"/>
                                <Button x:Name="btnGetInstalled" Content="  Get Installed" Style="{StaticResource SecondaryBtn}" Padding="12,5" FontSize="11" Margin="6,0,0,0"/>
                                <Border Width="1" Background="{DynamicResource Theme.Border}" Margin="10,2"/>
                                <TextBlock Text="LANES:" FontSize="10" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                <ComboBox x:Name="cmbInstallConcurrency" Width="58" Height="28" VerticalAlignment="Center" ToolTip="Number of concurrent package installs">
                                    <ComboBoxItem Content="1" IsSelected="True"/>
                                    <ComboBoxItem Content="2"/>
                                    <ComboBoxItem Content="3"/>
                                    <ComboBoxItem Content="4"/>
                                </ComboBox>
                                <TextBlock Text="CUSTOM:" FontSize="10" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold" VerticalAlignment="Center" Margin="12,0,6,0"/>
                                <TextBox x:Name="txtCustomArgs" Width="330" Height="28" VerticalContentAlignment="Center"
                                         ToolTip="Per-package arguments: package.id=--location &quot;D:\Apps&quot;; another.id=--scope user"
                                         Tag="package.id=--custom-args"/>
                            </StackPanel>
                        </Border>
                        <!-- App Grid -->
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,10">
                            <WrapPanel x:Name="pnlApps" Orientation="Horizontal"/>
                        </ScrollViewer>
                    </DockPanel>
                </Grid>

                <!-- TWEAKS PAGE -->
                <Grid x:Name="pageTweaks" Visibility="Collapsed">
                    <DockPanel>
                        <Border DockPanel.Dock="Top" Padding="24,18,24,14" Background="{DynamicResource Theme.Surface}">
                            <DockPanel>
                                <StackPanel>
                                    <TextBlock Text="System Tweaks" FontSize="22" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}"/>
                                    <TextBlock Text="Optimize Windows for performance, privacy, and usability" FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" Margin="0,4,0,0"/>
                                    <TextBlock x:Name="txtEnterpriseBanner" Text="" Visibility="Collapsed" FontSize="11" Foreground="{DynamicResource Theme.Warning}" TextWrapping="Wrap" Margin="0,6,0,0"/>
                                </StackPanel>
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" DockPanel.Dock="Right" VerticalAlignment="Center">
                                    <Button x:Name="btnTweakPresetEssential" Content="Essential Preset" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnTweakPresetPrivacy" Content="Privacy Preset" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnAuditTweaks" Content="Audit" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnDryRunTweaks" Content="Dry Run" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnExportADMX" Content="Export ADMX" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnTweakSelectAll" Content="Select All" Style="{StaticResource SecondaryBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnTweakDeselectAll" Content="Clear All" Style="{StaticResource SecondaryBtn}" Margin="0,0,10,0"/>
                                    <Button x:Name="btnSafePreset" Content="Safe Preset" Style="{StaticResource SuccessBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnRunTweaks" Content="  Run Tweaks" Style="{StaticResource AccentBtn}" Margin="0,0,6,0"/>
                                    <Button x:Name="btnUndoTweaks" Content="  Restore Last Set" Style="{StaticResource DangerBtn}"/>
                                </StackPanel>
                            </DockPanel>
                        </Border>
                        <Border DockPanel.Dock="Top" Padding="24,8,24,8" Background="{DynamicResource Theme.Toolbar}">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Text="TELEMETRY LEVEL:" FontSize="10" Foreground="{DynamicResource Theme.TextFaint}" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                <ComboBox x:Name="cmbTelemetryLevel" Width="110" Height="28" VerticalAlignment="Center" Margin="0,0,8,0">
                                    <ComboBoxItem Content="Off"/>
                                    <ComboBoxItem Content="Basic"/>
                                    <ComboBoxItem Content="Enhanced" IsSelected="True"/>
                                    <ComboBoxItem Content="Full"/>
                                </ComboBox>
                                <Button x:Name="btnApplyTelemetryLevel" Content="Apply Level" Style="{StaticResource SecondaryBtn}" Padding="12,5" FontSize="11" Margin="0,0,10,0"/>
                                <TextBlock x:Name="txtTelemetryDescription" Text="" FontSize="11" Foreground="{DynamicResource Theme.TextSubtle}" VerticalAlignment="Center" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,14">
                            <StackPanel x:Name="pnlTweaks"/>
                        </ScrollViewer>
                    </DockPanel>
                </Grid>

                <!-- CONFIG PAGE -->
                <Grid x:Name="pageConfig" Visibility="Collapsed">
                    <DockPanel>
                        <Border DockPanel.Dock="Top" Padding="24,18,24,14" Background="{DynamicResource Theme.Surface}">
                            <StackPanel>
                                <TextBlock Text="System Configuration" FontSize="22" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}"/>
                                <TextBlock Text="Windows features, system fixes, and legacy control panels" FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" Margin="0,4,0,0"/>
                            </StackPanel>
                        </Border>
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,14">
                            <StackPanel x:Name="pnlConfig"/>
                        </ScrollViewer>
                    </DockPanel>
                </Grid>

                <!-- DEPLOYMENT PAGE -->
                <Grid x:Name="pageDeploy" Visibility="Collapsed">
                    <DockPanel>
                        <Border DockPanel.Dock="Top" Padding="24,18,24,14" Background="{DynamicResource Theme.Surface}">
                            <StackPanel>
                                <TextBlock Text="Deployment" FontSize="22" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}"/>
                                <TextBlock Text="Export repeatable setup blocks, reach remote machines, and load fleet presets" FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" Margin="0,4,0,0"/>
                            </StackPanel>
                        </Border>
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,14">
                            <StackPanel MaxWidth="760" HorizontalAlignment="Left">
                        <Border Background="{DynamicResource Theme.Card}" CornerRadius="8" Padding="20" Margin="0,0,0,14" BorderBrush="{DynamicResource Theme.Divider}" BorderThickness="1">
                                    <StackPanel>
                                        <TextBlock Text="MDT / Autounattend" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}" Margin="0,0,0,8"/>
                                        <TextBlock Text="Export a FirstLogonCommands XML block and a companion script for the current selections." FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" TextWrapping="Wrap" Margin="0,0,0,14"/>
                                        <WrapPanel>
                                            <Button x:Name="btnExportMDT" Content="Export FirstLogonCommands" Style="{StaticResource AccentBtn}" Margin="0,0,8,8"/>
                                            <Button x:Name="btnHealthCheck" Content="Post-install Health Check" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,8"/>
                                        </WrapPanel>
                                    </StackPanel>
                                </Border>
                        <Border Background="{DynamicResource Theme.Card}" CornerRadius="8" Padding="20" Margin="0,0,0,14" BorderBrush="{DynamicResource Theme.Divider}" BorderThickness="1">
                                    <StackPanel>
                                        <TextBlock Text="Remote PowerShell" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}" Margin="0,0,0,8"/>
                                        <TextBlock Text="Uses the current Windows credentials and an existing WinRM/PSRemoting configuration." FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" TextWrapping="Wrap" Margin="0,0,0,14"/>
                                        <StackPanel Orientation="Horizontal">
                                            <TextBox x:Name="txtRemoteComputer" Width="250" Height="32" VerticalContentAlignment="Center" Tag="Computer name or FQDN" ToolTip="Remote computer name or FQDN" Margin="0,0,8,0"/>
                                            <Button x:Name="btnRemoteAudit" Content="Audit Remote" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,0"/>
                                            <Button x:Name="btnRemoteApply" Content="Apply Remote" Style="{StaticResource AccentBtn}"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>
                        <Border Background="{DynamicResource Theme.Card}" CornerRadius="8" Padding="20" Margin="0,0,0,14" BorderBrush="{DynamicResource Theme.Divider}" BorderThickness="1">
                                    <StackPanel>
                                        <TextBlock Text="Fleet Preset Library" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}" Margin="0,0,0,8"/>
                                        <TextBlock Text="Load a JSON profile from a local path, SMB share, or HTTPS Git URL. Set WINFORGE_PRESET_SOURCE to load it automatically at startup." FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" TextWrapping="Wrap" Margin="0,0,0,14"/>
                                        <StackPanel Orientation="Horizontal">
                                            <TextBox x:Name="txtFleetPresetSource" Width="500" Height="32" VerticalContentAlignment="Center" ToolTip="C:\\Profiles\\WinForge.json, \\server\\share\\profile.json, or https://..." Margin="0,0,8,0"/>
                                            <Button x:Name="btnLoadFleetPreset" Content="Load Preset" Style="{StaticResource SecondaryBtn}"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>
                                <Border Background="{DynamicResource Theme.Card}" CornerRadius="8" Padding="20" Margin="0,0,0,14" BorderBrush="{DynamicResource Theme.Divider}" BorderThickness="1">
                                    <StackPanel>
                                        <TextBlock Text="Companion Tools" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}" Margin="0,0,0,8"/>
                                        <TextBlock Text="Discover installed SysAdminDoc tools or local plugin manifests without executing them automatically." FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" TextWrapping="Wrap" Margin="0,0,0,10"/>
                                        <TextBox x:Name="txtCompanionPlugins" IsReadOnly="True" Height="70" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Margin="0,0,0,8"/>
                                        <Button x:Name="btnRefreshPlugins" Content="Refresh Plugins" Style="{StaticResource SecondaryBtn}" HorizontalAlignment="Left"/>
                                    </StackPanel>
                                </Border>
                            </StackPanel>
                        </ScrollViewer>
                    </DockPanel>
                </Grid>

                <!-- UPDATES PAGE -->
                <Grid x:Name="pageUpdates" Visibility="Collapsed">
                    <DockPanel>
                        <Border DockPanel.Dock="Top" Padding="24,18,24,14" Background="{DynamicResource Theme.Surface}">
                            <StackPanel>
                                <TextBlock Text="Windows Updates" FontSize="22" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}"/>
                                <TextBlock Text="Control how and when Windows installs updates" FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" Margin="0,4,0,0"/>
                            </StackPanel>
                        </Border>
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="24,14">
                            <StackPanel x:Name="pnlUpdates" MaxWidth="700" HorizontalAlignment="Left">
                                <!-- DNS Section -->
                        <Border Background="{DynamicResource Theme.Card}" CornerRadius="8" Padding="20" Margin="0,0,0,14" BorderBrush="{DynamicResource Theme.Divider}" BorderThickness="1">
                                    <StackPanel>
                                        <TextBlock Text="DNS Configuration" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}" Margin="0,0,0,10"/>
                                        <TextBlock Text="Select a DNS provider to optimize speed and privacy" FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" Margin="0,0,0,14"/>
                                        <StackPanel Orientation="Horizontal">
                                            <ComboBox x:Name="cmbDNS" Width="250" Margin="0,0,10,0">
                                                <ComboBoxItem Content="Default (DHCP)" IsSelected="True"/>
                                                <ComboBoxItem Content="Google (8.8.8.8)"/>
                                                <ComboBoxItem Content="Cloudflare (1.1.1.1)"/>
                                                <ComboBoxItem Content="Quad9 (9.9.9.9)"/>
                                                <ComboBoxItem Content="OpenDNS (208.67.222.222)"/>
                                                <ComboBoxItem Content="AdGuard (94.140.14.14)"/>
                                            </ComboBox>
                                            <Button x:Name="btnApplyDNS" Content="Apply DNS" Style="{StaticResource AccentBtn}" Padding="16,6"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>
                                <!-- Update Policies -->
                        <Border Background="{DynamicResource Theme.Card}" CornerRadius="8" Padding="20" Margin="0,0,0,14" BorderBrush="{DynamicResource Theme.Divider}" BorderThickness="1">
                                    <StackPanel>
                                        <TextBlock Text="Windows Update Policy" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}" Margin="0,0,0,10"/>
                                        <TextBlock Text="Choose how Windows handles updates on this system" FontSize="12" Foreground="{DynamicResource Theme.TextSubtle}" Margin="0,0,0,14"/>
                                        <WrapPanel>
                                            <Button x:Name="btnUpdateDefault" Content="  Default (Recommended)" Style="{StaticResource SuccessBtn}" Margin="0,0,8,8" Padding="14,10"/>
                                            <Button x:Name="btnUpdateSecurity" Content="  Security Only" Style="{StaticResource AccentBtn}" Margin="0,0,8,8" Padding="14,10"/>
                                            <Button x:Name="btnUpdateDisable" Content="  Disable Updates" Style="{StaticResource DangerBtn}" Margin="0,0,8,8" Padding="14,10"/>
                                        </WrapPanel>
                                    </StackPanel>
                                </Border>
                                <!-- Update Actions -->
                        <Border Background="{DynamicResource Theme.Card}" CornerRadius="8" Padding="20" Margin="0,0,0,14" BorderBrush="{DynamicResource Theme.Divider}" BorderThickness="1">
                                    <StackPanel>
                                        <TextBlock Text="Update Actions" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource Theme.TextBright}" Margin="0,0,0,10"/>
                                        <WrapPanel>
                                            <Button x:Name="btnCheckUpdates" Content="Check for Updates" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,8"/>
                                            <Button x:Name="btnPauseUpdates" Content="Pause Updates (35 days)" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,8"/>
                                            <Button x:Name="btnResetWU" Content="Reset Windows Update" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,8"/>
                                            <Button x:Name="btnSchedulePackageUpgrades" Content="Schedule Daily Package Upgrades" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,8"/>
                                            <Button x:Name="btnRepairWinget" Content="Repair WinGet" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,8"/>
                                        </WrapPanel>
                                    </StackPanel>
                                </Border>
                            </StackPanel>
                        </ScrollViewer>
                    </DockPanel>
                </Grid>
            </Grid>
        </DockPanel>
    </Grid>
</Window>
'@

# ── Parse XAML & Build Window ──────────────────────────────────────────────────
try { $window = [System.Windows.Markup.XamlReader]::Parse($xaml) }
catch {
    [void](Write-WinForgeCrashLog -Exception $_.Exception -Context 'XAML window construction')
    throw
}

$script:WinForgeThemePalettes = @{
    Dark = [ordered]@{
        Window = '#0d0d12'; Shell = '#0a0a14'; ShellDeep = '#08080e'; Surface = '#0d0d16'; Card = '#12121e'; Toolbar = '#0b0b14'; LogHeader = '#0c0c16'
        Input = '#1e1e2e'; InputPopup = '#1a1a2e'; Border = '#333346'; Divider = '#1e1e36'; Hover = '#282840'; PanelPressed = '#282844'; NavHover = '#18182a'; Panel = '#16162a'; PanelBorder = '#2a2a42'
        Text = '#d4d4e8'; TextBright = '#e8e8f0'; TextMuted = '#8888a0'; TextSubtle = '#666680'; TextFaint = '#555570'; Label = '#444460'; Arrow = '#9999aa'
        Accent = '#6c5ce7'; AccentHover = '#7c6ff0'; AccentPressed = '#5a4bd4'; AccentText = '#a78bfa'; White = '#ffffff'; Danger = '#dc2626'; DangerHover = '#ef4444'; DangerPressed = '#b91c1c'
        SuccessButton = '#16a34a'; SuccessButtonHover = '#22c55e'; SuccessButtonPressed = '#15803d'; Log = '#4ade80'; Warning = '#facc15'; RiskRed = '#f87171'
    }
    Light = [ordered]@{
        Window = '#f3f4f6'; Shell = '#ffffff'; ShellDeep = '#e5e7eb'; Surface = '#f9fafb'; Card = '#ffffff'; Toolbar = '#eef2f7'; LogHeader = '#e5e7eb'
        Input = '#ffffff'; InputPopup = '#ffffff'; Border = '#cbd5e1'; Divider = '#dbe3ec'; Hover = '#e5e7eb'; PanelPressed = '#dbe4ee'; NavHover = '#eef2f7'; Panel = '#f8fafc'; PanelBorder = '#cbd5e1'
        Text = '#1f2937'; TextBright = '#111827'; TextMuted = '#4b5563'; TextSubtle = '#64748b'; TextFaint = '#6b7280'; Label = '#475569'; Arrow = '#475569'
        Accent = '#5b4bc4'; AccentHover = '#4c3db5'; AccentPressed = '#3d319d'; AccentText = '#4c3db5'; White = '#ffffff'; Danger = '#b91c1c'; DangerHover = '#dc2626'; DangerPressed = '#991b1b'
        SuccessButton = '#15803d'; SuccessButtonHover = '#16a34a'; SuccessButtonPressed = '#166534'; Log = '#166534'; Warning = '#a16207'; RiskRed = '#b91c1c'
    }
    'High Contrast' = [ordered]@{
        Window = '#000000'; Shell = '#000000'; ShellDeep = '#000000'; Surface = '#000000'; Card = '#000000'; Toolbar = '#000000'; LogHeader = '#000000'
        Input = '#000000'; InputPopup = '#000000'; Border = '#ffffff'; Divider = '#ffffff'; Hover = '#1f1f1f'; PanelPressed = '#333333'; NavHover = '#1f1f1f'; Panel = '#000000'; PanelBorder = '#ffffff'
        Text = '#ffffff'; TextBright = '#ffffff'; TextMuted = '#ffffff'; TextSubtle = '#ffff00'; TextFaint = '#ffff00'; Label = '#00ffff'; Arrow = '#ffffff'
        Accent = '#00ffff'; AccentHover = '#ffffff'; AccentPressed = '#00aaaa'; AccentText = '#00ffff'; White = '#000000'; Danger = '#ff0000'; DangerHover = '#ff6666'; DangerPressed = '#990000'
        SuccessButton = '#00aa00'; SuccessButtonHover = '#00ff00'; SuccessButtonPressed = '#006600'; Log = '#00ff00'; Warning = '#ffff00'; RiskRed = '#ff6666'
    }
}

function Set-WinForgeTheme {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory)][ValidateSet('Dark','Light','High Contrast')][string]$Theme)

    if (-not $PSCmdlet.ShouldProcess($Theme, 'apply appearance theme')) { return $false }
    $palette = $script:WinForgeThemePalettes[$Theme]
    if (-not $palette) { return $false }
    foreach ($entry in $palette.GetEnumerator()) {
        $resourceKey = 'Theme.{0}' -f $entry.Key
        $brush = New-Object System.Windows.Media.SolidColorBrush
        $brush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString($entry.Value)
        $brush.Freeze()
        if ($window.Resources.Contains($resourceKey)) { [void]$window.Resources.Remove($resourceKey) }
        [void]$window.Resources.Add($resourceKey, $brush)
    }
    $script:WinForgeTheme = $Theme
    return $true
}

# codex-branding:start
                try {
                    $brandingIconPath = Join-Path $PSScriptRoot 'icon.ico'
                    if (Test-Path $brandingIconPath) {
                        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.Uri($brandingIconPath)))
                    }
                } catch {
                }
                # codex-branding:end
# ── Find Controls ──────────────────────────────────────────────────────────────
$txtLog             = $window.FindName('txtLog')
$btnClearLog        = $window.FindName('btnClearLog')
$txtSearch          = $window.FindName('txtSearch')
$pnlApps            = $window.FindName('pnlApps')
$pnlTweaks          = $window.FindName('pnlTweaks')
$pnlConfig          = $window.FindName('pnlConfig')
$pnlUpdates         = $window.FindName('pnlUpdates')
$txtSysInfo         = $window.FindName('txtSysInfo')
$infoComputer       = $window.FindName('infoComputer')
$infoOS             = $window.FindName('infoOS')
$infoCPU            = $window.FindName('infoCPU')
$infoRAM            = $window.FindName('infoRAM')
$infoUser           = $window.FindName('infoUser')
$infoDomain         = $window.FindName('infoDomain')
$infoStorage        = $window.FindName('infoStorage')
$cmbInstallConcurrency = $window.FindName('cmbInstallConcurrency')
$txtCustomArgs      = $window.FindName('txtCustomArgs')

# Pages
$pageInstall = $window.FindName('pageInstall')
$pageTweaks  = $window.FindName('pageTweaks')
$pageConfig  = $window.FindName('pageConfig')
$pageDeploy  = $window.FindName('pageDeploy')
$pageUpdates = $window.FindName('pageUpdates')
$txtEnterpriseBanner = $window.FindName('txtEnterpriseBanner')
$btnAuditTweaks = $window.FindName('btnAuditTweaks')
$btnDryRunTweaks = $window.FindName('btnDryRunTweaks')
$btnExportADMX = $window.FindName('btnExportADMX')
$cmbTelemetryLevel = $window.FindName('cmbTelemetryLevel')
$btnApplyTelemetryLevel = $window.FindName('btnApplyTelemetryLevel')
$txtTelemetryDescription = $window.FindName('txtTelemetryDescription')
$btnExportMDT = $window.FindName('btnExportMDT')
$btnHealthCheck = $window.FindName('btnHealthCheck')
$txtRemoteComputer = $window.FindName('txtRemoteComputer')
$btnRemoteAudit = $window.FindName('btnRemoteAudit')
$btnRemoteApply = $window.FindName('btnRemoteApply')
$txtFleetPresetSource = $window.FindName('txtFleetPresetSource')
$btnLoadFleetPreset = $window.FindName('btnLoadFleetPreset')
$txtCompanionPlugins = $window.FindName('txtCompanionPlugins')
$btnRefreshPlugins = $window.FindName('btnRefreshPlugins')

# Nav buttons
$navInstall = $window.FindName('navInstall')
$navTweaks  = $window.FindName('navTweaks')
$navConfig  = $window.FindName('navConfig')
$navDeploy  = $window.FindName('navDeploy')
$navUpdates = $window.FindName('navUpdates')
$navExport  = $window.FindName('navExport')
$navImport  = $window.FindName('navImport')
$navExportWinget = $window.FindName('navExportWinget')
$navImportWinget = $window.FindName('navImportWinget')
$btnCopyCrashReport = $window.FindName('btnCopyCrashReport')
$cmbTheme = $window.FindName('cmbTheme')

# ── Logging ────────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Color)
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $txtLog.Dispatcher.Invoke([Action]{
        $txtLog.AppendText("[$timestamp] $Message`r`n")
        $txtLog.ScrollToEnd()
    })
}

function Get-WinForgeCompanionPlugin {
    [CmdletBinding()]
    param()

    $directories = @(
        (Join-Path $PSScriptRoot 'plugins')
        (Join-Path $env:ProgramData 'SysAdminDoc\WinForge\plugins')
        (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinForge\plugins')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
    $plugins = @()
    $seen = @{}
    foreach ($directory in $directories) {
        foreach ($manifest in @(Get-ChildItem -LiteralPath $directory -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
            if ($seen.ContainsKey($manifest.FullName)) { continue }
            try {
                $metadata = Get-Content -LiteralPath $manifest.FullName -Raw -ErrorAction Stop | ConvertFrom-Json
                $plugins += [pscustomobject]@{
                    Name = if ($metadata.Name) { [string]$metadata.Name } else { $manifest.BaseName }
                    Description = if ($metadata.Description) { [string]$metadata.Description } else { 'Plugin manifest' }
                    Path = $manifest.FullName
                    EntryPoint = if ($metadata.EntryPoint) { [string]$metadata.EntryPoint } else { '' }
                    Source = 'Manifest'
                }
                $seen[$manifest.FullName] = $true
            } catch { Write-Debug ("Plugin manifest could not be read: {0}" -f $manifest.FullName) }
        }
        foreach ($scriptFile in @(Get-ChildItem -LiteralPath $directory -Filter '*.ps1' -File -ErrorAction SilentlyContinue)) {
            if ($seen.ContainsKey($scriptFile.FullName)) { continue }
            $plugins += [pscustomobject]@{
                Name = $scriptFile.BaseName
                Description = 'PowerShell plugin script'
                Path = $scriptFile.FullName
                EntryPoint = $scriptFile.FullName
                Source = 'Script'
            }
            $seen[$scriptFile.FullName] = $true
        }
    }
    foreach ($commandName in @('WURepair', 'DefenderShield')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) {
            $plugins += [pscustomobject]@{
                Name = $commandName
                Description = 'Installed companion command'
                Path = $command.Source
                EntryPoint = $command.Name
                Source = 'Command'
            }
        }
    }
    return $plugins
}

function Update-WinForgeCompanionPlugin {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()

    if (-not $PSCmdlet.ShouldProcess('companion plugin list', 'refresh')) { return @() }
    $plugins = @(Get-WinForgeCompanionPlugin)
    if ($plugins.Count -eq 0) {
        $txtCompanionPlugins.Text = 'No companion plugins discovered in the local plugin paths.'
    } else {
        $txtCompanionPlugins.Text = ($plugins | ForEach-Object {
            '{0} - {1} [{2}]' -f $_.Name, $_.Description, $_.Path
        }) -join [Environment]::NewLine
    }
    if ($txtLog) { Write-Log ("[OK] Discovered {0} companion plugin(s)." -f $plugins.Count) }
    return $plugins
}

Update-WinForgeCompanionPlugin | Out-Null

function Register-WinForgeCrashHandler {
    [CmdletBinding()]
    param()

    if ($script:CrashHandlersRegistered) { return }
    $window.Dispatcher.Add_UnhandledException({
        param($eventSender, $eventData)
        try {
            [void]$eventSender
            [void](Write-WinForgeCrashLog -Exception $eventData.Exception -Context 'WPF dispatcher')
            if ($btnCopyCrashReport) { $btnCopyCrashReport.IsEnabled = $true }
            Write-Log 'A crash was recorded locally. Review it before sharing.'
        } catch {
            Write-Debug ("WinForge dispatcher crash handler failed: {0}" -f $_.Exception.Message)
        } finally {
            $eventData.Handled = $true
        }
    }.GetNewClosure())
    [AppDomain]::CurrentDomain.Add_UnhandledException({
        param($eventSender, $eventData)
        try {
            [void]$eventSender
            $exception = $eventData.ExceptionObject -as [System.Exception]
            if (-not $exception) { $exception = New-Object System.Exception([string]$eventData.ExceptionObject) }
            [void](Write-WinForgeCrashLog -Exception $exception -Context 'AppDomain unhandled exception')
        } catch {
            Write-Debug ("WinForge AppDomain crash handler failed: {0}" -f $_.Exception.Message)
        }
    }.GetNewClosure())
    $script:CrashHandlersRegistered = $true
}

Register-WinForgeCrashHandler
$btnCopyCrashReport.IsEnabled = Test-Path -LiteralPath (Get-WinForgeCrashLogPath)
$btnCopyCrashReport.Add_Click({ Copy-WinForgeCrashReport })

# ── Navigation ─────────────────────────────────────────────────────────────────
$script:AllPages = @($pageInstall, $pageTweaks, $pageConfig, $pageDeploy, $pageUpdates)
$script:AllNavBtns = @($navInstall, $navTweaks, $navConfig, $navDeploy, $navUpdates)

function Switch-Page {
    param([System.Windows.UIElement]$Page, [System.Windows.Controls.Button]$NavBtn)
    foreach ($p in $script:AllPages) { $p.Visibility = 'Collapsed' }
    $Page.Visibility = 'Visible'
    $activeStyle = $window.FindResource('NavBtnActive')
    $normalStyle = $window.FindResource('NavBtn')
    foreach ($n in $script:AllNavBtns) { $n.Style = $normalStyle }
    $NavBtn.Style = $activeStyle
}

$navInstall.Add_Click({ Switch-Page $pageInstall $navInstall })
$navTweaks.Add_Click({  Switch-Page $pageTweaks  $navTweaks })
$navConfig.Add_Click({  Switch-Page $pageConfig   $navConfig })
$navDeploy.Add_Click({  Switch-Page $pageDeploy   $navDeploy })
$navUpdates.Add_Click({ Switch-Page $pageUpdates $navUpdates })
$cmbTheme.Add_SelectionChanged({
    $selectedTheme = $cmbTheme.SelectedItem
    if ($selectedTheme) {
        $themeName = [string]$selectedTheme.Content
        if (Set-WinForgeTheme -Theme $themeName) { Write-Log ("[OK] Appearance changed to {0}." -f $themeName) }
    }
})

$btnClearLog.Add_Click({ $txtLog.Text = '' })

$script:EnterpriseState = Get-WinForgeEnterpriseState
if ($script:EnterpriseState.IsManaged) {
    $txtEnterpriseBanner.Text = 'Enterprise management detected. Tweaks that write policy-managed registry paths will be blocked.'
    $txtEnterpriseBanner.Visibility = 'Visible'
}

# ── System Info ────────────────────────────────────────────────────────────────
try {
    $wmiOS   = Get-CimInstance Win32_OperatingSystem
    $wmiCS   = Get-CimInstance Win32_ComputerSystem
    $wmiCPU  = Get-CimInstance Win32_Processor | Select-Object -First 1
    $build   = [System.Environment]::OSVersion.Version.Build

    $infoComputer.Text = $env:COMPUTERNAME
    $infoOS.Text       = "$($wmiOS.Caption) (Build $build)"
    $infoCPU.Text      = ($wmiCPU.Name -replace '\s+',' ').Trim()
    $ramGB             = [math]::Round($wmiCS.TotalPhysicalMemory / 1GB, 1)
    $infoRAM.Text      = "${ramGB} GB"
    $infoUser.Text     = "$env:USERDOMAIN\$env:USERNAME"

    if ($wmiCS.PartOfDomain) {
        $infoDomain.Text = $wmiCS.Domain
    } else {
        $infoDomain.Text = $wmiCS.Workgroup
    }

    # Storage info - system drive
    $sysDrive   = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
    $totalGB    = [math]::Round($sysDrive.Size / 1GB, 0)
    $freeGB     = [math]::Round($sysDrive.FreeSpace / 1GB, 1)
    $diskType   = "HDD"
    try {
        $physDisk = Get-PhysicalDisk -ErrorAction Stop | Select-Object -First 1
        if ($physDisk.MediaType -eq 'SSD' -or $physDisk.MediaType -eq 'NVMe') { $diskType = $physDisk.MediaType }
        elseif ($physDisk.BusType -eq 'NVMe') { $diskType = "NVMe" }
        elseif ($physDisk.MediaType -match 'Solid') { $diskType = "SSD" }
    } catch {}
    $infoStorage.Text = "$($env:SystemDrive) ${diskType} ${totalGB}GB total, ${freeGB}GB free"

    $txtSysInfo.Text = "$($wmiOS.Caption)`nBuild $build | ${ramGB}GB RAM"
} catch { $txtSysInfo.Text = "Windows" }

# ── BUILD INSTALL TAB ─────────────────────────────────────────────────────────
$script:AppCheckboxes = @{}

function Build-InstallTab {
    $pnlApps.Children.Clear()
    foreach ($category in $script:AppCategories.Keys) {
        # Category card
        $card = New-Object System.Windows.Controls.Border
        $card.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Theme.Card')
        $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $card.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Theme.Divider')
        $card.BorderThickness = [System.Windows.Thickness]::new(1)
        $card.Padding = [System.Windows.Thickness]::new(14)
        $card.Margin = [System.Windows.Thickness]::new(0,0,12,12)
        $card.Width = 235

        $stack = New-Object System.Windows.Controls.StackPanel

        # Category header
        $header = New-Object System.Windows.Controls.TextBlock
        $header.Text = $category.ToUpper()
        $header.FontSize = 10
        $header.FontWeight = 'Bold'
        $header.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Theme.Accent')
        $header.Margin = [System.Windows.Thickness]::new(0,0,0,8)
        $stack.Children.Add($header)

        $sep = New-Object System.Windows.Controls.Border
        $sep.Height = 1
        $sep.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Theme.Divider')
        $sep.Margin = [System.Windows.Thickness]::new(0,0,0,8)
        $stack.Children.Add($sep)

        foreach ($app in $script:AppCategories[$category]) {
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $app.Name
            $cb.Tag = $app.Id
            $cb.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, 'Theme.Text')
            $cb.Margin = [System.Windows.Thickness]::new(0,2,0,2)
            $cb.FontSize = 12
            $stack.Children.Add($cb)
            $script:AppCheckboxes[$app.Id] = $cb
        }
        $card.Child = $stack
        $pnlApps.Children.Add($card)
    }
}
Build-InstallTab

# ── Search Filter ──────────────────────────────────────────────────────────────
$txtSearch.Add_TextChanged({
    $term = $txtSearch.Text.ToLower().Trim()
    foreach ($kvp in $script:AppCheckboxes.GetEnumerator()) {
        $cb = $kvp.Value
        if ([string]::IsNullOrEmpty($term)) {
            $cb.Visibility = 'Visible'
        } else {
            $searchText = "{0} {1}" -f $cb.Content, $cb.Tag
            $score = Get-WinForgeFuzzyScore -Text $searchText -Query $term
            if ($score -ge 0.42) {
                $cb.Visibility = 'Visible'
            } else {
                $cb.Visibility = 'Collapsed'
            }
        }
    }
})

# ── Install Actions ────────────────────────────────────────────────────────────
$window.FindName('btnSelectAll').Add_Click({
    foreach ($cb in $script:AppCheckboxes.Values) { if ($cb.Visibility -eq 'Visible') { $cb.IsChecked = $true } }
})
$window.FindName('btnDeselectAll').Add_Click({
    foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
})

function Get-SelectedApps {
    $selected = @()
    foreach ($kvp in $script:AppCheckboxes.GetEnumerator()) {
        if ($kvp.Value.IsChecked -eq $true) { $selected += $kvp.Key }
    }
    return $selected
}

function Get-SelectedAppCustomArgumentMap {
    $configured = ConvertFrom-WinForgeCustomArgument -Text $txtCustomArgs.Text
    $selected = @{}
    foreach ($id in (Get-SelectedApps)) {
        if ($configured.ContainsKey($id)) { $selected[$id] = $configured[$id] }
    }
    return $selected
}

function Complete-InstallQueue {
    if (-not $script:InstallState) { return }
    $state = $script:InstallState
    if ($script:InstallTimer) {
        $script:InstallTimer.Stop()
        $script:InstallTimer = $null
    }
    foreach ($jobId in @($state.Active.Keys)) {
        $ctx = $state.Active[$jobId]
        Stop-Job -Job $ctx.Job -ErrorAction SilentlyContinue
        Remove-Job -Job $ctx.Job -Force -ErrorAction SilentlyContinue
    }
    $state.Active.Clear()
    $window.FindName('btnInstallSelected').IsEnabled = $true
    Write-Log ("=== Install complete: {0} succeeded, {1} failed out of {2} ===" -f
        $state.Success, $state.Failed, $state.Total)
    $script:InstallState = $null
}

function Update-InstallQueue {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()
    if (-not $PSCmdlet.ShouldProcess('package queue', 'advance installation jobs')) { return }
    $state = $script:InstallState
    if (-not $state) { return }

    while ($state.Active.Count -lt $state.Concurrency -and $state.NextIndex -lt $state.Total) {
        $appId = $state.Queue[$state.NextIndex]
        $name = [string]$script:AppCheckboxes[$appId].Content
        $custom = if ($state.CustomArgs.ContainsKey($appId)) { [string]$state.CustomArgs[$appId] } else { '' }
        $position = $state.NextIndex + 1
        try {
            $job = Start-Job -ScriptBlock $script:PackageInstallWorker -ArgumentList $name, $appId, $custom
            $state.Active[$job.Id] = @{
                Job = $job
                Name = $name
                Id = $appId
                Result = $null
                Logged = @{}
            }
            Write-Log ("Installing {0} of {1}: {2} ({3}) [lane {4}]..." -f
                $position, $state.Total, $name, $appId, ($state.Active.Count))
        } catch {
            $state.Failed++
            Write-Log ("[FAIL] Could not start installer for {0}: {1}" -f $name, $_.Exception.Message)
        }
        $state.NextIndex++
    }

    foreach ($jobId in @($state.Active.Keys)) {
        $ctx = $state.Active[$jobId]
        $records = @(Receive-Job -Job $ctx.Job -ErrorAction SilentlyContinue)
        foreach ($record in $records) {
            if ($record -is [string]) {
                if ($record.StartsWith('LOG|')) {
                    Write-Log ("[{0}] {1}" -f $ctx.Name, ($record -replace '^LOG\|',''))
                } elseif (-not [string]::IsNullOrWhiteSpace($record)) {
                    Write-Log ("[{0}] {1}" -f $ctx.Name, $record)
                }
            } elseif ($record.PSObject.Properties['Kind'] -and $record.Kind -eq 'Result') {
                $ctx.Result = $record
            }
        }

        if ($ctx.Job.State -in @('Completed','Failed','Stopped')) {
            if ($ctx.Result -and $ctx.Result.Success) {
                $state.Success++
                Write-Log ("[OK] {0} installed via {1}; verified by {2}." -f
                    $ctx.Name, $ctx.Result.Provider, $ctx.Result.Verification)
            } else {
                $state.Failed++
                $attempts = if ($ctx.Result) { $ctx.Result.Attempts } else { 'worker failed before returning a result' }
                Write-Log ("[FAIL] {0}; attempts: {1}" -f $ctx.Name, $attempts)
            }
            Remove-Job -Job $ctx.Job -Force -ErrorAction SilentlyContinue
            $state.Active.Remove($jobId)
        }
    }

    if ($state.NextIndex -ge $state.Total -and $state.Active.Count -eq 0) {
        Complete-InstallQueue
    }
}

function Start-InstallQueue {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param()
    if (-not $PSCmdlet.ShouldProcess('selected packages', 'install')) { return }
    if ($script:InstallState) {
        Write-Log 'An installation is already in progress.'
        return
    }
    if ($script:PlatformInfo.IsArm64) {
        Write-Log '[!] ARM64 Windows detected. Winget will resolve architecture-specific manifests; unsupported packages may be skipped.'
    }
    $apps = @(Get-SelectedApps)
    if ($apps.Count -eq 0) { Write-Log 'No applications selected.'; return }
    $concurrency = 1
    if ($cmbInstallConcurrency -and $cmbInstallConcurrency.SelectedItem) {
        [int]::TryParse([string]$cmbInstallConcurrency.SelectedItem.Content, [ref]$concurrency) | Out-Null
    }
    $concurrency = [math]::Max(1, [math]::Min(4, $concurrency))
    $customArgs = Get-SelectedAppCustomArgumentMap
    $script:InstallState = @{
        Queue = $apps
        Total = $apps.Count
        NextIndex = 0
        Success = 0
        Failed = 0
        Concurrency = $concurrency
        CustomArgs = $customArgs
        Active = @{}
    }
    Write-Log ("=== Installing {0} application(s) with {1} concurrent lane(s) ===" -f $apps.Count, $concurrency)
    if ($customArgs.Count -gt 0) { Write-Log ("Custom arguments loaded for {0} package(s)." -f $customArgs.Count) }
    $window.FindName('btnInstallSelected').IsEnabled = $false
    $script:InstallTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:InstallTimer.Interval = [TimeSpan]::FromMilliseconds(350)
    $script:InstallTimer.Add_Tick({ Update-InstallQueue }.GetNewClosure())
    $script:InstallTimer.Start()
    Update-InstallQueue
}

$window.FindName('btnInstallSelected').Add_Click({ Start-InstallQueue })

$window.FindName('btnUpgradeAll').Add_Click({
    Write-Log "Upgrading all packages via winget..."
    $ps = [PowerShell]::Create()
    $ps.AddScript({ & winget upgrade --all --accept-source-agreements --accept-package-agreements --silent 2>&1 }) | Out-Null
    $handle = $ps.BeginInvoke()
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop()
            try { $res = $ps.EndInvoke($handle); Write-Log "[OK] Upgrade complete." } catch { Write-Log "[!] Upgrade error." }
            $ps.Dispose()
        }
    }.GetNewClosure())
    $timer.Start()
})

$window.FindName('btnUninstallSelected').Add_Click({
    $apps = Get-SelectedApps
    if ($apps.Count -eq 0) { Write-Log "No applications selected for uninstall."; return }
    Write-Log "Uninstalling $($apps.Count) application(s)..."
    foreach ($appId in $apps) {
        $name = $script:AppCheckboxes[$appId].Content
        Write-Log "Uninstalling: $name..."
        $id = $appId
        $ps = [PowerShell]::Create()
        $ps.AddScript({ param($pkgId) & winget uninstall --id $pkgId --silent 2>&1 }).AddArgument($id) | Out-Null
        $handle = $ps.BeginInvoke()
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(500)
        $timer.Tag = @{ PS=$ps; Handle=$handle; Name=$name }
        $timer.Add_Tick({
            $ctx = $this.Tag
            if ($ctx.Handle.IsCompleted) {
                $this.Stop()
                try { $ctx.PS.EndInvoke($ctx.Handle); Write-Log "[OK] $($ctx.Name) uninstalled." } catch { Write-Log "[!] $($ctx.Name) uninstall error." }
                $ctx.PS.Dispose()
            }
        }.GetNewClosure())
        $timer.Start()
    }
})

$window.FindName('btnGetInstalled').Add_Click({
    Write-Log "Scanning installed packages..."
    $ps = [PowerShell]::Create()
    $ps.AddScript({
        $list = & winget list --accept-source-agreements 2>$null
        return ($list | Out-String)
    }) | Out-Null
    $handle = $ps.BeginInvoke()
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if ($handle.IsCompleted) {
            $timer.Stop()
            try {
                $res = $ps.EndInvoke($handle) | Out-String
                $matched = 0
                foreach ($kvp in $script:AppCheckboxes.GetEnumerator()) {
                    $id = $kvp.Key
                    if ($res -match [regex]::Escape($id)) {
                        $kvp.Value.IsChecked = $true
                        $matched++
                    }
                }
                Write-Log "[OK] Found $matched installed applications from catalog."
            } catch { Write-Log "[!] Error scanning packages." }
            $ps.Dispose()
        }
    }.GetNewClosure())
    $timer.Start()
})

# ── Presets ────────────────────────────────────────────────────────────────────
$window.FindName('btnPresetDev').Add_Click({
    foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
    $devApps = @('Microsoft.VisualStudioCode','Git.Git','OpenJS.NodeJS.LTS','Python.Python.3.12',
        'Microsoft.WindowsTerminal','Microsoft.PowerShell','Docker.DockerDesktop','GitHub.GitHubDesktop',
        'Notepad++.Notepad++','7zip.7zip','Mozilla.Firefox','Postman.Postman')
    foreach ($id in $devApps) { if ($script:AppCheckboxes.ContainsKey($id)) { $script:AppCheckboxes[$id].IsChecked = $true } }
    Write-Log "Developer preset applied."
})
$window.FindName('btnPresetGamer').Add_Click({
    foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
    $gameApps = @('Valve.Steam','EpicGames.EpicGamesLauncher','GOG.Galaxy','Discord.Discord',
        'VideoLAN.VLC','7zip.7zip','Mozilla.Firefox','OBSProject.OBSStudio')
    foreach ($id in $gameApps) { if ($script:AppCheckboxes.ContainsKey($id)) { $script:AppCheckboxes[$id].IsChecked = $true } }
    Write-Log "Gamer preset applied."
})
$window.FindName('btnPresetProd').Add_Click({
    foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
    $prodApps = @('Mozilla.Firefox','TheDocumentFoundation.LibreOffice','Obsidian.Obsidian',
        'Adobe.Acrobat.Reader.64-bit','7zip.7zip','Bitwarden.Bitwarden','Zoom.Zoom',
        'Mozilla.Thunderbird','ShareX.ShareX','voidtools.Everything')
    foreach ($id in $prodApps) { if ($script:AppCheckboxes.ContainsKey($id)) { $script:AppCheckboxes[$id].IsChecked = $true } }
    Write-Log "Productivity preset applied."
})
$window.FindName('btnPresetBasic').Add_Click({
    foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
    $basicApps = @('Google.Chrome','7zip.7zip','VideoLAN.VLC','Adobe.Acrobat.Reader.64-bit',
        'voidtools.Everything','Notepad++.Notepad++')
    foreach ($id in $basicApps) { if ($script:AppCheckboxes.ContainsKey($id)) { $script:AppCheckboxes[$id].IsChecked = $true } }
    Write-Log "Essentials preset applied."
})

# ── BUILD TWEAKS TAB ──────────────────────────────────────────────────────────
$script:TweakCheckboxes = @{}

function Build-TweaksTab {
    $pnlTweaks.Children.Clear()
    foreach ($category in $script:TweakCategories.Keys) {
        $header = New-Object System.Windows.Controls.TextBlock
        $header.Text = $category.ToUpper()
        $header.FontSize = 11
        $header.FontWeight = 'Bold'
        $header.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Theme.Accent')
        $header.Margin = [System.Windows.Thickness]::new(0,10,0,8)
        $pnlTweaks.Children.Add($header)

        $grid = New-Object System.Windows.Controls.WrapPanel
        $grid.Orientation = 'Horizontal'

        foreach ($tweak in $script:TweakCategories[$category]) {
            if (-not (Test-WinForgeTweakApplicable -Key $tweak.Key)) { continue }
            $card = New-Object System.Windows.Controls.Border
            $card.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Theme.Card')
            $card.CornerRadius = [System.Windows.CornerRadius]::new(6)
            $card.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Theme.Divider')
            $card.BorderThickness = [System.Windows.Thickness]::new(1)
            $card.Padding = [System.Windows.Thickness]::new(12,8,12,8)
            $card.Margin = [System.Windows.Thickness]::new(0,0,10,8)
            $card.Width = 320

            $sp = New-Object System.Windows.Controls.StackPanel
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $tweak.Name
            $cb.Tag = $tweak.Key
            $cb.SetResourceReference([System.Windows.Controls.Control]::ForegroundProperty, 'Theme.Text')
            $cb.FontSize = 12.5
            $meta = Get-WinForgeTweakInfo -Key $tweak.Key
            $cb.ToolTip = "{0}`nRisk: {1}`nRevert: {2}" -f $tweak.Desc, $meta.Risk, $meta.Revert
            $riskRow = New-Object System.Windows.Controls.StackPanel
            $riskRow.Orientation = 'Horizontal'
            $riskPip = New-Object System.Windows.Controls.TextBlock
            $riskPip.Text = '●'
            $riskPip.FontSize = 10
            $riskPip.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom((Get-WinForgeTweakRiskBrush -Risk $meta.Risk))
            $riskPip.Margin = [System.Windows.Thickness]::new(0,1,5,0)
            $riskPip.ToolTip = "Risk: $($meta.Risk). $($meta.Revert)"
            [void]$riskRow.Children.Add($riskPip)
            [void]$riskRow.Children.Add($cb)
            [void]$sp.Children.Add($riskRow)

            $desc = New-Object System.Windows.Controls.TextBlock
            $desc.Text = $tweak.Desc
            $desc.FontSize = 10.5
            $desc.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Theme.TextSubtle')
            $desc.TextWrapping = 'Wrap'
            $desc.Margin = [System.Windows.Thickness]::new(18,2,0,0)
            $sp.Children.Add($desc)

            $card.Child = $sp
            $grid.Children.Add($card)
            $script:TweakCheckboxes[$tweak.Key] = $cb
        }
        $pnlTweaks.Children.Add($grid)
    }
}
Build-TweaksTab

$updateTelemetryDescription = {
    if ($cmbTelemetryLevel.SelectedItem) {
        $level = [string]$cmbTelemetryLevel.SelectedItem.Content
        $txtTelemetryDescription.Text = Get-WinForgeTelemetryLevelDescription -Level $level
    }
}
$cmbTelemetryLevel.Add_SelectionChanged($updateTelemetryDescription)
$txtTelemetryDescription.Text = 'Send the additional diagnostic data level selected below.'
$btnApplyTelemetryLevel.Add_Click({
    if ($cmbTelemetryLevel.SelectedItem) {
        Set-WinForgeTelemetryLevel -Level ([string]$cmbTelemetryLevel.SelectedItem.Content)
    }
})

# Tweak Presets
$window.FindName('btnTweakPresetEssential').Add_Click({
    foreach ($cb in $script:TweakCheckboxes.Values) { $cb.IsChecked = $false }
    $essential = @('RestorePoint','TempFiles','Telemetry','ActivityHistory','LocationTracking',
        'ConsumerFeatures','ServicesManual','Widgets','EndTask','DiskCleanup')
    foreach ($k in $essential) { if ($script:TweakCheckboxes.ContainsKey($k)) { $script:TweakCheckboxes[$k].IsChecked = $true } }
    Write-Log "Essential tweak preset applied."
})
$window.FindName('btnTweakPresetPrivacy').Add_Click({
    foreach ($cb in $script:TweakCheckboxes.Values) { $cb.IsChecked = $false }
    $privacy = @('Telemetry','ActivityHistory','LocationTracking','AdvertisingID','AppLaunchTracking',
        'FeedbackRequests','TailoredExp','DiagnosticData','ClipboardHistory','SpeechRecognition','InputPersonal',
        'Cortana','BingSearch')
    foreach ($k in $privacy) { if ($script:TweakCheckboxes.ContainsKey($k)) { $script:TweakCheckboxes[$k].IsChecked = $true } }
    Write-Log "Privacy tweak preset applied."
})
$window.FindName('btnTweakSelectAll').Add_Click({
    foreach ($cb in $script:TweakCheckboxes.Values) { $cb.IsChecked = $true }
})
$window.FindName('btnTweakDeselectAll').Add_Click({
    foreach ($cb in $script:TweakCheckboxes.Values) { $cb.IsChecked = $false }
})

# ── Tweak Execution Engine ────────────────────────────────────────────────────
function Invoke-Tweak {
    param([string]$Key, [bool]$Undo = $false)
    $action = if ($Undo) { "Undoing" } else { "Applying" }
    Write-Log "$action tweak: $Key"
    switch ($Key) {
        'RestorePoint' {
            if (-not $Undo) {
                try { Checkpoint-Computer -Description "WinForge Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop; Write-Log "[OK] Restore point created." }
                catch { Write-Log "[!] Could not create restore point: $_" }
            }
        }
        'TempFiles' {
            if (-not $Undo) {
                Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "[OK] Temporary files cleaned."
            }
        }
        'Telemetry' {
            $v = if ($Undo) { 3 } else { 0 }
            Set-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value $v -Type DWord -Force 2>$null
            if (-not $Undo) {
                Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
                Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
            } else {
                Set-Service -Name "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
                Start-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
            }
            Write-Log "[OK] Telemetry $(if($Undo){'enabled'}else{'disabled'})."
        }
        'ActivityHistory' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "EnableActivityFeed" -Value $v -Type DWord -Force
            Set-ItemProperty -LiteralPath $path -Name "PublishUserActivities" -Value $v -Type DWord -Force
            Write-Log "[OK] Activity History $(if($Undo){'enabled'}else{'disabled'})."
        }
        'LocationTracking' {
            $v = if ($Undo) { "Allow" } else { "Deny" }
            $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "Value" -Value $v -Force
            Write-Log "[OK] Location Tracking $(if($Undo){'enabled'}else{'disabled'})."
        }
        'Hibernation' {
            if ($Undo) { & powercfg /h on 2>$null } else { & powercfg /h off 2>$null }
            Write-Log "[OK] Hibernation $(if($Undo){'enabled'}else{'disabled'})."
        }
        'ConsumerFeatures' {
            $v = if ($Undo) { 0 } else { 1 }
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "DisableWindowsConsumerFeatures" -Value $v -Type DWord -Force
            Write-Log "[OK] Consumer Features $(if($Undo){'disabled'}else{'blocked'})."
        }
        'ServicesManual' {
            $svcs = @('DiagTrack','dmwappushservice','SysMain','WSearch','MapsBroker','lfsvc','RetailDemo','wisvc')
            foreach ($s in $svcs) {
                if ($Undo) { Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue }
                else { Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue; Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }
            }
            Write-Log "[OK] Non-essential services set to $(if($Undo){'Automatic'}else{'Manual'})."
        }
        'PS7Telemetry' {
            if ($Undo) { [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','0','Machine') }
            else { [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','1','Machine') }
            Write-Log "[OK] PS7 Telemetry $(if($Undo){'enabled'}else{'disabled'})."
        }
        'Widgets' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "AllowNewsAndInterests" -Value $v -Type DWord -Force
            Write-Log "[OK] Widgets $(if($Undo){'enabled'}else{'removed'})."
        }
        'EndTask' {
            $v = if ($Undo) { 0 } else { 1 }
            $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "TaskbarEndTask" -Value $v -Type DWord -Force
            Write-Log "[OK] End Task in taskbar $(if($Undo){'disabled'}else{'enabled'})."
        }
        'DiskCleanup' {
            if (-not $Undo) {
                Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -NoNewWindow -ErrorAction SilentlyContinue
                Write-Log "[OK] Disk Cleanup launched."
            }
        }
        'Cortana' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "AllowCortana" -Value $v -Type DWord -Force
            Write-Log "[OK] Cortana $(if($Undo){'enabled'}else{'disabled'})."
        }
        'GameDVR' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\System\GameConfigStore"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "GameDVR_Enabled" -Value $v -Type DWord -Force
            $path2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
            if (-not (Test-Path $path2)) { New-Item -Path $path2 -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path2 -Name "AllowGameDVR" -Value $v -Type DWord -Force
            Write-Log "[OK] GameDVR $(if($Undo){'enabled'}else{'disabled'})."
        }
        'WiFiSense' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "AutoConnectAllowedOEM" -Value $v -Type DWord -Force
            Write-Log "[OK] WiFi Sense $(if($Undo){'enabled'}else{'disabled'})."
        }
        'StorageSense' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "01" -Value $v -Type DWord -Force
            Write-Log "[OK] Storage Sense $(if($Undo){'enabled'}else{'disabled'})."
        }
        'Copilot' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "TurnOffWindowsCopilot" -Value $(if($Undo){0}else{1}) -Type DWord -Force
            Write-Log "[OK] Copilot $(if($Undo){'enabled'}else{'disabled'})."
        }
        'Recall' {
            $v = if ($Undo) { 0 } else { 1 }
            $path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "DisableAIDataAnalysis" -Value $v -Type DWord -Force
            Write-Log "[OK] Recall $(if($Undo){'enabled'}else{'disabled'})."
        }
        'NewsInterests' {
            $v = if ($Undo) { 1 } else { 2 }
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "EnableFeeds" -Value $(if($Undo){1}else{0}) -Type DWord -Force
            Write-Log "[OK] News and Interests $(if($Undo){'enabled'}else{'disabled'})."
        }
        'BingSearch' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "DisableSearchBoxSuggestions" -Value $(if($Undo){0}else{1}) -Type DWord -Force
            Write-Log "[OK] Bing Search $(if($Undo){'enabled'}else{'disabled'})."
        }
        'SearchHighlights' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "EnableDynamicContentInWSB" -Value $v -Type DWord -Force
            Write-Log "[OK] Search Highlights $(if($Undo){'enabled'}else{'disabled'})."
        }
        'FileExtensions' {
            $v = if ($Undo) { 1 } else { 0 }
            Set-ItemProperty -LiteralPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value $v -Type DWord -Force
            Write-Log "[OK] File extensions $(if($Undo){'hidden'}else{'visible'})."
        }
        'HiddenFiles' {
            $v = if ($Undo) { 2 } else { 1 }
            Set-ItemProperty -LiteralPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value $v -Type DWord -Force
            Write-Log "[OK] Hidden files $(if($Undo){'hidden'}else{'visible'})."
        }
        'MouseAccel' {
            if ($Undo) {
                Set-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1" -Force
            } else {
                Set-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Force
                Set-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force
                Set-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force
            }
            Write-Log "[OK] Mouse acceleration $(if($Undo){'enabled'}else{'disabled'})."
        }
        'ClassicContext' {
            if ($Undo) {
                Remove-Item -LiteralPath "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                $path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
                New-Item -Path $path -Force | Out-Null
                Set-ItemProperty -LiteralPath $path -Name "(Default)" -Value "" -Force
            }
            Write-Log "[OK] Classic context menu $(if($Undo){'reverted'}else{'enabled'}). Restart Explorer to apply."
        }
        'UltimatePower' {
            if ($Undo) {
                & powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
                Write-Log "[OK] Balanced power plan restored."
            } else {
                & powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
                $plans = & powercfg /list 2>$null | Out-String
                if ($plans -match '([0-9a-f-]{36}).*Ultimate') {
                    & powercfg /setactive $Matches[1] 2>$null
                }
                Write-Log "[OK] Ultimate Performance plan activated."
            }
        }
        'AdvertisingID' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "Enabled" -Value $v -Type DWord -Force
            Write-Log "[OK] Advertising ID $(if($Undo){'enabled'}else{'disabled'})."
        }
        'AppLaunchTracking' {
            $v = if ($Undo) { 1 } else { 0 }
            Set-ItemProperty -LiteralPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value $v -Type DWord -Force
            Write-Log "[OK] App launch tracking $(if($Undo){'enabled'}else{'disabled'})."
        }
        'FeedbackRequests' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "NumberOfSIUFInPeriod" -Value $v -Type DWord -Force
            Write-Log "[OK] Feedback requests $(if($Undo){'enabled'}else{'disabled'})."
        }
        'TailoredExp' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value $v -Type DWord -Force
            Write-Log "[OK] Tailored experiences $(if($Undo){'enabled'}else{'disabled'})."
        }
        'DiagnosticData' {
            $v = if ($Undo) { 3 } else { 0 }
            Set-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value $v -Type DWord -Force 2>$null
            Write-Log "[OK] Diagnostic data set to $(if($Undo){'Full'}else{'Minimum'})."
        }
        'ClipboardHistory' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "AllowClipboardHistory" -Value $v -Type DWord -Force
            Write-Log "[OK] Clipboard history $(if($Undo){'enabled'}else{'disabled'})."
        }
        'SpeechRecognition' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "HasAccepted" -Value $v -Type DWord -Force
            Write-Log "[OK] Online speech recognition $(if($Undo){'enabled'}else{'disabled'})."
        }
        'InputPersonal' {
            $v = if ($Undo) { 1 } else { 0 }
            $path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -LiteralPath $path -Name "RestrictImplicitTextCollection" -Value $(if($Undo){0}else{1}) -Type DWord -Force
            Set-ItemProperty -LiteralPath $path -Name "RestrictImplicitInkCollection" -Value $(if($Undo){0}else{1}) -Type DWord -Force
            Write-Log "[OK] Input personalization $(if($Undo){'enabled'}else{'disabled'})."
        }
        default { Write-Log "[?] Unknown tweak: $Key" }
    }
}

function Get-WinForgeTweakKey {
    $keys = @()
    foreach ($category in $script:TweakCategories.Keys) {
        foreach ($tweak in $script:TweakCategories[$category]) { $keys += $tweak.Key }
    }
    return $keys
}

function ConvertTo-WinForgeDisplayValue {
    param([AllowNull()]$Value, [bool]$Exists)
    if (-not $Exists) { return '(missing)' }
    if ($null -eq $Value -or [string]::IsNullOrEmpty([string]$Value)) { return '(empty)' }
    return [string]$Value
}

function Get-WinForgeTweakPreviewText {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Keys)

    $lines = @('Review the proposed changes before applying them:', '')
    foreach ($key in $Keys) {
        $meta = Get-WinForgeTweakInfo -Key $key
        $lines += ("[{0}] {1} (risk: {2})" -f $key, ($script:TweakCheckboxes[$key].Content), $meta.Risk)
        foreach ($change in @(Get-WinForgeTweakChangeSet -Key $key)) {
            if ($change.Kind -eq 'Action') {
                $lines += ("  ACTION: {0}" -f $change.Name)
            } elseif ($change.Kind -eq 'RegistryPath') {
                $lines += ("  {0}\{1}: {2} -> {3}" -f $change.Path, $change.Name,
                    (ConvertTo-WinForgeDisplayValue $change.Current $change.CurrentExists), $change.Target)
            } else {
                $lines += ("  {0} [{1}]: {2} -> {3}" -f $change.Path, $change.Name,
                    (ConvertTo-WinForgeDisplayValue $change.Current $change.CurrentExists), $change.Target)
            }
        }
        $lines += ("  Revert: {0}" -f $meta.Revert)
        $lines += ''
    }
    $conflicts = @(Get-WinForgeThirdPartyTweakConflict)
    if ($conflicts.Count -gt 0) {
        $lines += 'Warning: third-party tweak markers were detected:'
        foreach ($conflict in $conflicts) { $lines += ("  {0} ({1})" -f $conflict.Name, $conflict.Path) }
        $lines += ''
    }
    return ($lines -join [Environment]::NewLine)
}

function Confirm-WinForgeTweakChange {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Keys)

    $preview = Get-WinForgeTweakPreviewText -Keys $Keys
    foreach ($line in ($preview -split '\r?\n')) { if ($line) { Write-Log $line } }
    $message = $preview
    if ($message.Length -gt 7000) { $message = $message.Substring(0, 7000) + "`r`n... preview truncated; see the output log ..." }
    $answer = [System.Windows.MessageBox]::Show(
        $message,
        'WinForge - Review tweak changes',
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning)
    return ($answer -eq [System.Windows.MessageBoxResult]::Yes)
}

function Get-WinForgeTweakHistoryDirectory {
    [CmdletBinding()]
    param([switch]$Create)
    $root = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinForge\history'
    if ($Create -and -not (Test-Path -LiteralPath $root)) { New-Item -Path $root -ItemType Directory -Force | Out-Null }
    return $root
}

function Save-WinForgeTweakHistory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Keys)

    $snapshots = @()
    foreach ($key in $Keys) {
        foreach ($change in @(Get-WinForgeTweakChangeSet -Key $key)) {
            if ($change.Kind -eq 'Action') { continue }
            $snapshots += [pscustomobject]@{
                Key = $change.Key; Kind = $change.Kind; Path = $change.Path; Name = $change.Name
                Exists = $change.CurrentExists; Value = $change.Current; Type = $change.Type
            }
        }
    }
    $history = [ordered]@{
        SchemaVersion = 1
        Created = (Get-Date).ToString('o')
        Tweaks = @($Keys)
        Registry = @($snapshots)
    }
    $directory = Get-WinForgeTweakHistoryDirectory -Create
    $fileName = '{0:yyyyMMdd-HHmmssfff}.json' -f (Get-Date)
    $path = Join-Path $directory $fileName
    $history | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8

    $oldFiles = @(Get-ChildItem -LiteralPath $directory -Filter '*.json' -File | Sort-Object LastWriteTime -Descending | Select-Object -Skip 20)
    foreach ($oldFile in $oldFiles) { Remove-Item -LiteralPath $oldFile.FullName -Force -ErrorAction SilentlyContinue }
    return $path
}

function Get-WinForgeSafePresetDirectory {
    [CmdletBinding()]
    param([switch]$Create)

    $root = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WinForge\safe-presets'
    if ($Create -and -not (Test-Path -LiteralPath $root)) { New-Item -Path $root -ItemType Directory -Force | Out-Null }
    return $root
}

function ConvertTo-WinForgeRegistryExportPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ($Path.StartsWith('HKLM:\', [System.StringComparison]::OrdinalIgnoreCase)) { return ('HKLM\' + $Path.Substring(6)) }
    if ($Path.StartsWith('HKCU:\', [System.StringComparison]::OrdinalIgnoreCase)) { return ('HKCU\' + $Path.Substring(6)) }
    return $null
}

function New-WinForgeSafePreset {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory)][string[]]$Keys)

    $directory = Get-WinForgeSafePresetDirectory
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $presetDirectory = Join-Path $directory $stamp
    if (-not $PSCmdlet.ShouldProcess($presetDirectory, 'create restore point and registry exports')) { return $false }

    Get-WinForgeSafePresetDirectory -Create | Out-Null
    New-Item -Path $presetDirectory -ItemType Directory -Force | Out-Null
    $restorePointCreated = $false
    try {
        if (-not (Get-Command Checkpoint-Computer -ErrorAction SilentlyContinue)) { throw 'Checkpoint-Computer is unavailable.' }
        Checkpoint-Computer -Description "WinForge Safe Preset $stamp" -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        $restorePointCreated = $true
    } catch {
        Write-Log ("[!] Safe preset could not create a Restore Point: {0}" -f $_.Exception.Message)
    }

    $paths = @($Keys | ForEach-Object { Get-WinForgeTweakChangeSet -Key $_ } |
        Where-Object { $_.Kind -in @('Registry','RegistryPath') } |
        ForEach-Object { ConvertTo-WinForgeRegistryExportPath -Path $_.Path } |
        Where-Object { $_ } | Sort-Object -Unique)
    $exports = @()
    $missing = @()
    $failed = @()
    foreach ($nativePath in $paths) {
        $providerPath = $nativePath -replace '^HKLM\\', 'HKLM:\' -replace '^HKCU\\', 'HKCU:\'
        if (-not (Test-Path -LiteralPath $providerPath)) { $missing += $nativePath; continue }
        $fileName = (($nativePath -replace '[\\/:*?"<>| ]', '_') + '.reg')
        $exportPath = Join-Path $presetDirectory $fileName
        try {
            & reg.exe export $nativePath $exportPath /y 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exportPath)) { throw "reg.exe returned exit code $LASTEXITCODE." }
            $exports += $exportPath
        } catch {
            $failed += [pscustomobject]@{ Path = $nativePath; Error = $_.Exception.Message }
        }
    }

    $manifest = [ordered]@{
        SchemaVersion = 1
        Created = (Get-Date).ToString('o')
        Tweaks = @($Keys)
        RestorePointCreated = $restorePointCreated
        RegistryExports = @($exports)
        MissingRegistryPaths = @($missing)
        FailedRegistryExports = @($failed)
    }
    $manifestPath = Join-Path $presetDirectory 'manifest.json'
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    if (-not $restorePointCreated -or $failed.Count -gt 0) {
        Write-Log ("[!] Safe preset is incomplete; no tweaks were applied. Review {0}." -f $manifestPath)
        return [pscustomobject]@{ Success = $false; Directory = $presetDirectory; Manifest = $manifestPath; RestorePointCreated = $restorePointCreated; RegistryExports = @($exports) }
    }
    Write-Log ("[OK] Safe preset created at {0}; registry exports: {1}." -f $presetDirectory, $exports.Count)
    return [pscustomobject]@{ Success = $true; Directory = $presetDirectory; Manifest = $manifestPath; RestorePointCreated = $restorePointCreated; RegistryExports = @($exports) }
}

function Restore-WinForgeTweakHistory {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([string]$HistoryPath)

    if ([string]::IsNullOrWhiteSpace($HistoryPath)) {
        $HistoryPath = Get-ChildItem -LiteralPath (Get-WinForgeTweakHistoryDirectory) -Filter '*.json' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $HistoryPath -or -not (Test-Path -LiteralPath $HistoryPath)) {
        Write-Log 'No tweak history snapshot is available.'
        return $false
    }
    if (-not $PSCmdlet.ShouldProcess($HistoryPath, 'restore tweak registry snapshot')) { return $false }
    try {
        $history = Get-Content -LiteralPath $HistoryPath -Raw | ConvertFrom-Json
        foreach ($snapshot in @($history.Registry)) {
            if ($snapshot.Kind -eq 'RegistryPath') {
                if ($snapshot.Exists) {
                    New-Item -Path $snapshot.Path -Force | Out-Null
                } else {
                    Remove-Item -LiteralPath $snapshot.Path -Recurse -Force -ErrorAction SilentlyContinue
                }
                continue
            }
            if ($snapshot.Exists) {
                if (-not (Test-Path -LiteralPath $snapshot.Path)) { New-Item -Path $snapshot.Path -Force | Out-Null }
                $property = Get-ItemProperty -LiteralPath $snapshot.Path -Name $snapshot.Name -ErrorAction SilentlyContinue
                if ($property) {
                    Set-ItemProperty -LiteralPath $snapshot.Path -Name $snapshot.Name -Value $snapshot.Value -Force
                } else {
                    New-ItemProperty -LiteralPath $snapshot.Path -Name $snapshot.Name -Value $snapshot.Value -PropertyType $snapshot.Type -Force | Out-Null
                }
            } else {
                Remove-ItemProperty -LiteralPath $snapshot.Path -Name $snapshot.Name -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Log ("[OK] Restored tweak history from {0}." -f (Split-Path -Leaf $HistoryPath))
        return $true
    } catch {
        Write-Log ("[!] Failed to restore tweak history: {0}" -f $_.Exception.Message)
        return $false
    }
}

function Test-WinForgeTweakAllowed {
    param([Parameter(Mandatory)][string]$Key)
    if (-not $script:EnterpriseState -or -not $script:EnterpriseState.IsManaged) { return $true }
    foreach ($change in @(Get-WinForgeTweakChangeSet -Key $Key)) {
        if ($change.Path -match '^(HKLM|HKCU):\\SOFTWARE\\Policies\\|PolicyManager|Enrollments') { return $false }
    }
    return $true
}

function Get-WinForgeTelemetryLevelValue {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('Off','Basic','Enhanced','Full')][string]$Level)

    return @{'Off' = 0; 'Basic' = 1; 'Enhanced' = 2; 'Full' = 3}[$Level]
}

function Get-WinForgeTelemetryLevelDescription {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('Off','Basic','Enhanced','Full')][string]$Level)

    return @{
        Off = 'Turn off the Windows telemetry policy where the edition permits it.'
        Basic = 'Send the minimum diagnostic data required by Windows.'
        Enhanced = 'Send additional diagnostic data to improve Windows reliability.'
        Full = 'Use the full diagnostic data level and Windows feedback services.'
    }[$Level]
}

function Set-WinForgeTelemetryLevel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory)][ValidateSet('Off','Basic','Enhanced','Full')][string]$Level)

    if (-not (Test-WinForgeTweakAllowed -Key 'Telemetry')) {
        Write-Log 'Enterprise mode blocked the telemetry level change.'
        return $false
    }
    $path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
    if (-not $PSCmdlet.ShouldProcess($path, "set telemetry level to $Level")) { return $false }
    try {
        if (-not (Test-Path -LiteralPath $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -LiteralPath $path -Name 'AllowTelemetry' -Value (Get-WinForgeTelemetryLevelValue -Level $Level) -Type DWord -Force
        Write-Log ("[OK] Telemetry level set to {0}." -f $Level)
        return $true
    } catch {
        Write-Log ("[!] Could not set telemetry level: {0}" -f $_.Exception.Message)
        return $false
    }
}

function New-WinForgeDryRunScript {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory)][string[]]$Keys)

    if (-not $PSCmdlet.ShouldProcess('dry-run script', 'generate')) { return }

    $lines = @(
        '# WinForge dry-run script generated from the selected tweak set.'
        '# Review this file before execution. It invokes the same tweak executor as the GUI.'
        '$ErrorActionPreference = ''Stop'''
        '$winForgePath = Join-Path $PSScriptRoot ''WinForge.ps1'''
        'if (-not (Test-Path -LiteralPath $winForgePath)) { throw ''WinForge.ps1 must be beside this script.'' }'
        '. $winForgePath -NoElevation -NoLaunch'
        ''
    )
    foreach ($key in $Keys) {
        $escapedKey = $key.Replace("'", "''")
        $lines += ("# {0}" -f $key)
        $lines += ("Invoke-Tweak -Key '{0}'" -f $escapedKey)
    }
    return (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

$window.FindName('btnRunTweaks').Add_Click({
    $selected = @()
    foreach ($kvp in $script:TweakCheckboxes.GetEnumerator()) {
        if ($kvp.Value.IsChecked -eq $true) { $selected += $kvp.Key }
    }
    if ($selected.Count -eq 0) { Write-Log 'No tweaks selected.'; return }

    $blocked = @($selected | Where-Object { -not (Test-WinForgeTweakAllowed -Key $_) })
    if ($blocked.Count -gt 0) {
        Write-Log ("[!] Enterprise mode blocked: {0}" -f ($blocked -join ', '))
        $selected = @($selected | Where-Object { $blocked -notcontains $_ })
    }
    if ($selected.Count -eq 0) { Write-Log 'No permitted tweaks remain.'; return }
    if (-not (Confirm-WinForgeTweakChange -Keys $selected)) {
        Write-Log 'Tweak run cancelled after preview.'
        return
    }
    try {
        $historyPath = Save-WinForgeTweakHistory -Keys $selected
        Write-Log ("Snapshot saved to {0}." -f (Split-Path -Leaf $historyPath))
    } catch {
        Write-Log ("[!] Could not save the safety snapshot; no tweaks were applied: {0}" -f $_.Exception.Message)
        return
    }
    Write-Log "Running $($selected.Count) tweak(s)..."
    foreach ($key in $selected) { Invoke-Tweak -Key $key -Undo $false }
    Write-Log '--- Tweaks complete; use Restore Last Set to revert the snapshot. ---'
})

$window.FindName('btnSafePreset').Add_Click({
    $selected = @($script:TweakCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked -eq $true } | ForEach-Object { $_.Key })
    if ($selected.Count -eq 0) { Write-Log 'Select at least one tweak for a Safe Preset.'; return }
    $blocked = @($selected | Where-Object { -not (Test-WinForgeTweakAllowed -Key $_) })
    if ($blocked.Count -gt 0) {
        Write-Log ("[!] Enterprise mode blocked: {0}" -f ($blocked -join ', '))
        $selected = @($selected | Where-Object { $blocked -notcontains $_ })
    }
    if ($selected.Count -eq 0) { Write-Log 'No permitted tweaks remain.'; return }
    if (-not (Confirm-WinForgeTweakChange -Keys $selected)) {
        Write-Log 'Safe Preset cancelled after preview.'
        return
    }
    $safePreset = New-WinForgeSafePreset -Keys $selected
    if (-not $safePreset -or -not $safePreset.Success) { return }
    try {
        $historyPath = Save-WinForgeTweakHistory -Keys $selected
        Write-Log ("Snapshot saved to {0}." -f (Split-Path -Leaf $historyPath))
    } catch {
        Write-Log ("[!] Could not save the safety snapshot; no tweaks were applied: {0}" -f $_.Exception.Message)
        return
    }
    Write-Log "Running safe preset with $($selected.Count) tweak(s)..."
    foreach ($key in $selected) { Invoke-Tweak -Key $key -Undo $false }
    Write-Log ("--- Safe Preset complete; restore files are under {0}. ---" -f $safePreset.Directory)
})

$window.FindName('btnUndoTweaks').Add_Click({
    Restore-WinForgeTweakHistory
})

function Get-WinForgeSelectedOrAllTweakKey {
    $selected = @($script:TweakCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked -eq $true } | ForEach-Object { $_.Key })
    if ($selected.Count -gt 0) { return $selected }
    return @(Get-WinForgeTweakKey)
}

function Invoke-WinForgeTweakAudit {
    $keys = Get-WinForgeSelectedOrAllTweakKey
    Write-Log ("=== Tweak audit: {0} item(s) ===" -f $keys.Count)
    foreach ($key in $keys) {
        $changes = @(Get-WinForgeTweakChangeSet -Key $key)
        $registryChanges = @($changes | Where-Object { $_.Kind -ne 'Action' })
        if ($registryChanges.Count -eq 0) {
            Write-Log ("[?] {0}: action requires manual verification." -f $key)
            continue
        }
        $applied = $true
        foreach ($change in $registryChanges) {
            if ($change.Kind -eq 'RegistryPath') {
                $valueMatches = ($change.CurrentExists -and $change.Target -eq 'exists') -or (-not $change.CurrentExists -and $change.Target -eq 'absent')
            } else {
                $valueMatches = $change.CurrentExists -and ([string]$change.Current -eq [string]$change.Target)
            }
            if (-not $valueMatches) { $applied = $false }
            Write-Log ("  {0}: {1} -> {2}" -f $change.Name,
                (ConvertTo-WinForgeDisplayValue $change.Current $change.CurrentExists), $change.Target)
        }
        Write-Log ("[{0}] {1}" -f (if ($applied) { 'APPLIED' } else { 'NOT APPLIED' }), $key)
    }
    Write-Log '--- Tweak audit complete ---'
}

function Export-WinForgeDryRun {
    $keys = Get-WinForgeSelectedOrAllTweakKey
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = 'PowerShell Script|*.ps1'
    $dlg.FileName = 'WinForge-Tweak-DryRun.ps1'
    if ($dlg.ShowDialog()) {
        (New-WinForgeDryRunScript -Keys $keys) | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
        Write-Log ("[OK] Dry-run script exported to {0}" -f $dlg.FileName)
    }
}

function Export-WinForgeAdmx {
    $keys = Get-WinForgeSelectedOrAllTweakKey
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = 'ADMX Policy Template|*.admx'
    $dlg.FileName = 'WinForge.admx'
    if (-not $dlg.ShowDialog()) { return }

    $admx = [System.Xml.XmlDocument]::new()
    $declaration = $admx.CreateXmlDeclaration('1.0', 'utf-8', $null)
    [void]$admx.AppendChild($declaration)
    $root = $admx.CreateElement('policyDefinitions')
    $root.SetAttribute('revision', '1.0')
    $root.SetAttribute('schemaVersion', '1.0')
    [void]$admx.AppendChild($root)
    $namespaces = $admx.CreateElement('policyNamespaces')
    $target = $admx.CreateElement('targetPrefix'); $target.SetAttribute('prefix','WinForge'); $target.SetAttribute('namespace','WinForge.Policies'); [void]$namespaces.AppendChild($target)
    $using = $admx.CreateElement('using'); $using.SetAttribute('prefix','windows'); $using.SetAttribute('namespace','Microsoft.Policies.Windows'); [void]$namespaces.AppendChild($using)
    [void]$root.AppendChild($namespaces)
    $resources = $admx.CreateElement('resources'); $resources.SetAttribute('minRequiredRevision','1.0'); [void]$root.AppendChild($resources)
    $categories = $admx.CreateElement('categories'); $category = $admx.CreateElement('category'); $category.SetAttribute('name','WinForge'); $category.SetAttribute('displayName','$(string.WinForgeCategory)'); [void]$categories.AppendChild($category); [void]$root.AppendChild($categories)
    $policies = $admx.CreateElement('policies'); [void]$root.AppendChild($policies)

    $strings = @{'WinForgeCategory' = 'WinForge Tweaks'}
    $policyIndex = 0
    foreach ($key in $keys) {
        foreach ($change in @(Get-WinForgeTweakChangeSet -Key $key | Where-Object { $_.Kind -eq 'Registry' })) {
            $policyIndex++
            $policyId = "WinForge_{0}_{1}" -f ($key -replace '[^A-Za-z0-9_]','_'), $policyIndex
            $displayId = "${policyId}_Display"
            $explainId = "${policyId}_Explain"
            $strings[$displayId] = "WinForge - $key - $($change.Name)"
            $strings[$explainId] = "Sets $($change.Path)\$($change.Name) to $($change.Target); disabling the policy restores $($change.Undo)."
            $policy = $admx.CreateElement('policy')
            $policy.SetAttribute('name',$policyId)
            $policy.SetAttribute('class', (if ($change.Path -like 'HKCU:*') { 'User' } else { 'Machine' }))
            $policy.SetAttribute('displayName', "`$(string.$displayId)")
            $policy.SetAttribute('explainText', "`$(string.$explainId)")
            $policy.SetAttribute('key', ($change.Path -replace '^(HKLM|HKCU):\\',''))
            $policy.SetAttribute('valueName', $change.Name)
            $parent = $admx.CreateElement('parentCategory'); $parent.SetAttribute('ref','WinForge'); [void]$policy.AppendChild($parent)
            $enabled = $admx.CreateElement('enabledValue')
            if ($change.Type -eq 'DWord') { $node = $admx.CreateElement('decimal'); $node.SetAttribute('value',[string]$change.Target) } else { $node = $admx.CreateElement('string'); $node.SetAttribute('value',[string]$change.Target) }
            [void]$enabled.AppendChild($node); [void]$policy.AppendChild($enabled)
            $disabled = $admx.CreateElement('disabledValue')
            if ($change.Type -eq 'DWord') { $node = $admx.CreateElement('decimal'); $node.SetAttribute('value',[string]$change.Undo) } else { $node = $admx.CreateElement('string'); $node.SetAttribute('value',[string]$change.Undo) }
            [void]$disabled.AppendChild($node); [void]$policy.AppendChild($disabled)
            [void]$policies.AppendChild($policy)
        }
    }
    $admx.Save($dlg.FileName)

    $admlDirectory = Join-Path (Split-Path -Parent $dlg.FileName) 'en-US'
    New-Item -Path $admlDirectory -ItemType Directory -Force | Out-Null
    $adml = [System.Xml.XmlDocument]::new()
    [void]$adml.AppendChild($adml.CreateXmlDeclaration('1.0','utf-8',$null))
    $admlRoot = $adml.CreateElement('policyDefinitionResources'); $admlRoot.SetAttribute('revision','1.0'); $admlRoot.SetAttribute('schemaVersion','1.0'); [void]$adml.AppendChild($admlRoot)
    $admlResources = $adml.CreateElement('resources'); $stringTable = $adml.CreateElement('stringTable')
    foreach ($entry in $strings.GetEnumerator()) { $string = $adml.CreateElement('string'); $string.SetAttribute('id',$entry.Key); $string.InnerText = $entry.Value; [void]$stringTable.AppendChild($string) }
    [void]$admlResources.AppendChild($stringTable); [void]$admlRoot.AppendChild($admlResources)
    $adml.Save((Join-Path $admlDirectory 'WinForge.adml'))
    Write-Log ("[OK] ADMX and en-US ADML exported for {0} registry tweak(s)." -f $policyIndex)
}

$btnAuditTweaks.Add_Click({ Invoke-WinForgeTweakAudit })
$btnDryRunTweaks.Add_Click({ Export-WinForgeDryRun })
$btnExportADMX.Add_Click({ Export-WinForgeAdmx })

$btnExportMDT.Add_Click({ Export-WinForgeFirstLogonCommand })
$btnHealthCheck.Add_Click({ Start-WinForgeHealthCheck })
$btnRemoteAudit.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtRemoteComputer.Text)) { Write-Log 'Enter a remote computer name first.'; return }
    Invoke-WinForgeRemoteMachine -ComputerName $txtRemoteComputer.Text.Trim() -Audit
})
$btnRemoteApply.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtRemoteComputer.Text)) { Write-Log 'Enter a remote computer name first.'; return }
    Invoke-WinForgeRemoteMachine -ComputerName $txtRemoteComputer.Text.Trim()
})
$btnLoadFleetPreset.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtFleetPresetSource.Text)) { Write-Log 'Enter a fleet preset path or URL first.'; return }
    Import-WinForgeFleetPreset -Source $txtFleetPresetSource.Text.Trim()
})
$btnRefreshPlugins.Add_Click({ Update-WinForgeCompanionPlugin | Out-Null })
$txtFleetPresetSource.Text = $env:WINFORGE_PRESET_SOURCE

# ── BUILD CONFIG TAB ──────────────────────────────────────────────────────────
function Build-ConfigTab {
    $pnlConfig.Children.Clear()
    foreach ($section in $script:ConfigFeatures.Keys) {
        $header = New-Object System.Windows.Controls.TextBlock
        $header.Text = $section.ToUpper()
        $header.FontSize = 11
        $header.FontWeight = 'Bold'
        $header.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Theme.Accent')
        $header.Margin = [System.Windows.Thickness]::new(0,10,0,8)
        $pnlConfig.Children.Add($header)

        $wrap = New-Object System.Windows.Controls.WrapPanel
        $wrap.Orientation = 'Horizontal'

        foreach ($item in $script:ConfigFeatures[$section]) {
            $btn = New-Object System.Windows.Controls.Button
            $btn.Content = $item.Name
            $btn.Style = $window.FindResource('PanelBtn')
            $btn.Margin = [System.Windows.Thickness]::new(0,0,8,8)
            $btn.MinWidth = 200
            $btn.Tag = $item

            $btn.Add_Click({
                $data = $this.Tag
                if ($data.ContainsKey('Panel')) {
                    Write-Log "Opening: $($data.Name)..."
                    Start-Process $data.Panel -ErrorAction SilentlyContinue
                }
                elseif ($data.ContainsKey('Feature')) {
                    Write-Log "Installing feature: $($data.Name)..."
                    $features = $data.Feature -split ';'
                    foreach ($f in $features) {
                        try {
                            Enable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -ErrorAction Stop | Out-Null
                            Write-Log "[OK] $f enabled."
                        } catch {
                            try {
                                & dism /online /enable-feature /featurename:$f /norestart 2>$null
                                Write-Log "[OK] $f enabled via DISM."
                            } catch { Write-Log "[!] Failed to enable $f" }
                        }
                    }
                }
                elseif ($data.ContainsKey('Fix')) {
                    switch ($data.Fix) {
                        'WindowsUpdate' {
                            Write-Log "Resetting Windows Update components..."
                            $svcs = @('wuauserv','cryptSvc','bits','msiserver')
                            foreach ($s in $svcs) { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }
                            Remove-Item "$env:windir\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
                            Remove-Item "$env:windir\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue
                            foreach ($s in $svcs) { Start-Service -Name $s -ErrorAction SilentlyContinue }
                            Write-Log "[OK] Windows Update reset."
                        }
                        'SFC' {
                            Write-Log "Running System File Checker..."
                            $ps = [PowerShell]::Create()
                            $ps.AddScript({ & sfc /scannow 2>&1 | Out-String }) | Out-Null
                            $handle = $ps.BeginInvoke()
                            $t = New-Object System.Windows.Threading.DispatcherTimer
                            $t.Interval = [TimeSpan]::FromMilliseconds(1000)
                            $t.Add_Tick({
                                if ($handle.IsCompleted) { $this.Stop(); Write-Log "[OK] SFC complete."; $ps.Dispose() }
                            }.GetNewClosure())
                            $t.Start()
                        }
                        'DISM' {
                            Write-Log "Running DISM repair..."
                            $ps = [PowerShell]::Create()
                            $ps.AddScript({ & DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-String }) | Out-Null
                            $handle = $ps.BeginInvoke()
                            $t = New-Object System.Windows.Threading.DispatcherTimer
                            $t.Interval = [TimeSpan]::FromMilliseconds(1000)
                            $t.Add_Tick({
                                if ($handle.IsCompleted) { $this.Stop(); Write-Log "[OK] DISM repair complete."; $ps.Dispose() }
                            }.GetNewClosure())
                            $t.Start()
                        }
                        'Network' {
                            Write-Log "Resetting network stack..."
                            & netsh winsock reset 2>$null
                            & netsh int ip reset 2>$null
                            & ipconfig /release 2>$null
                            & ipconfig /renew 2>$null
                            Write-Log "[OK] Network stack reset. Restart recommended."
                        }
                        'DNS' {
                            & ipconfig /flushdns 2>$null
                            Write-Log "[OK] DNS cache cleared."
                        }
                        'Autologon' {
                            Start-Process "netplwiz" -ErrorAction SilentlyContinue
                            Write-Log "Autologon dialog opened."
                        }
                    }
                }
            }.GetNewClosure())

            $wrap.Children.Add($btn)
        }
        $pnlConfig.Children.Add($wrap)
    }
}
Build-ConfigTab

# Explicitly configured fleet sources are loaded once the controls and profile
# maps exist. No network source is contacted unless the operator sets this
# environment variable or presses Load Preset in the Deployment page.
if (-not [string]::IsNullOrWhiteSpace($env:WINFORGE_PRESET_SOURCE)) {
    Import-WinForgeFleetPreset -Source $env:WINFORGE_PRESET_SOURCE | Out-Null
}

# ── UPDATES TAB ────────────────────────────────────────────────────────────────
$window.FindName('btnApplyDNS').Add_Click({
    $sel = $window.FindName('cmbDNS').SelectedItem.Content.ToString()
    Write-Log "Setting DNS to: $sel"
    $dnsMap = @{
        'Default (DHCP)' = @()
        'Google (8.8.8.8)' = @('8.8.8.8','8.8.4.4')
        'Cloudflare (1.1.1.1)' = @('1.1.1.1','1.0.0.1')
        'Quad9 (9.9.9.9)' = @('9.9.9.9','149.112.112.112')
        'OpenDNS (208.67.222.222)' = @('208.67.222.222','208.67.220.220')
        'AdGuard (94.140.14.14)' = @('94.140.14.14','94.140.15.15')
    }
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($a in $adapters) {
        if ($dnsMap[$sel].Count -eq 0) {
            Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ResetServerAddresses
        } else {
            Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses $dnsMap[$sel]
        }
    }
    & ipconfig /flushdns 2>$null
    Write-Log "[OK] DNS configured to $sel on all active adapters."
})

$window.FindName('btnUpdateDefault').Add_Click({
    Write-Log "Setting Windows Update to default..."
    Remove-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
    Remove-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdates" -ErrorAction SilentlyContinue
    Remove-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdates" -ErrorAction SilentlyContinue
    Write-Log "[OK] Windows Update set to default policy."
})

$window.FindName('btnUpdateSecurity').Add_Click({
    Write-Log "Setting Windows Update to security-only..."
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    if (-not (Test-Path "$path\AU")) { New-Item -Path "$path\AU" -Force | Out-Null }
    Set-ItemProperty -LiteralPath $path -Name "DeferFeatureUpdates" -Value 1 -Type DWord -Force
    Set-ItemProperty -LiteralPath $path -Name "DeferFeatureUpdatesPeriodInDays" -Value 365 -Type DWord -Force
    Set-ItemProperty -LiteralPath $path -Name "DeferQualityUpdates" -Value 0 -Type DWord -Force
    Write-Log "[OK] Windows Update set to security-only (feature updates deferred 365 days)."
})

$window.FindName('btnUpdateDisable').Add_Click({
    Write-Log "Disabling Windows Update..."
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -LiteralPath $path -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
    Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "[OK] Windows Update disabled. Re-enable via Default policy."
})

$window.FindName('btnCheckUpdates').Add_Click({
    Write-Log "Opening Windows Update..."
    Start-Process "ms-settings:windowsupdate" -ErrorAction SilentlyContinue
})

$window.FindName('btnPauseUpdates').Add_Click({
    Write-Log "Pausing updates for 35 days..."
    $date = (Get-Date).AddDays(35).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $path = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -LiteralPath $path -Name "PauseUpdatesExpiryTime" -Value $date -Force
    Set-ItemProperty -LiteralPath $path -Name "PauseFeatureUpdatesStartTime" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") -Force
    Set-ItemProperty -LiteralPath $path -Name "PauseFeatureUpdatesEndTime" -Value $date -Force
    Set-ItemProperty -LiteralPath $path -Name "PauseQualityUpdatesStartTime" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") -Force
    Set-ItemProperty -LiteralPath $path -Name "PauseQualityUpdatesEndTime" -Value $date -Force
    Write-Log "[OK] Updates paused until $date"
})

$window.FindName('btnResetWU').Add_Click({
    Write-Log "Resetting Windows Update..."
    $svcs = @('wuauserv','cryptSvc','bits','msiserver')
    foreach ($s in $svcs) { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }
    Remove-Item "$env:windir\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:windir\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($s in $svcs) { Start-Service -Name $s -ErrorAction SilentlyContinue }
    Write-Log "[OK] Windows Update components reset."
})

$window.FindName('btnSchedulePackageUpgrades').Add_Click({ Register-WinForgeDailyUpgradeTask })
$window.FindName('btnRepairWinget').Add_Click({ Repair-WinForgeWinget })

# ── Export/Import Config ───────────────────────────────────────────────────────
function Export-WinForgeWingetConfiguration {
    $apps = @(Get-SelectedApps)
    if ($apps.Count -eq 0) { Write-Log 'No applications selected for WinGet export.'; return }
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = 'WinGet Configuration|*.winget;*.yaml;*.yml'
    $dlg.FileName = 'WinForge-Configuration.winget'
    if ($dlg.ShowDialog()) {
        $yaml = ConvertTo-WinForgeWingetConfiguration -PackageIds $apps
        $yaml | Set-Content -LiteralPath $dlg.FileName -Encoding UTF8
        Write-Log ("[OK] WinGet DSC v3 configuration exported to {0}" -f $dlg.FileName)
        $custom = ConvertFrom-WinForgeCustomArgument -Text $txtCustomArgs.Text
        if ($custom.Count -gt 0) { Write-Log '[!] DSC v3 package resources do not carry WinForge custom arguments; JSON export retains them.' }
    }
}

function Import-WinForgeWingetConfiguration {
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = 'WinGet Configuration|*.winget;*.yaml;*.yml|All files|*.*'
    if ($dlg.ShowDialog()) {
        try {
            $yaml = Get-Content -LiteralPath $dlg.FileName -Raw
            $apps = @(ConvertFrom-WinForgeWingetConfiguration -Content $yaml)
            if ($apps.Count -eq 0) { throw 'No WinGet package resources were found.' }
            foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
            $matched = 0
            foreach ($id in $apps) {
                if ($script:AppCheckboxes.ContainsKey($id)) {
                    $script:AppCheckboxes[$id].IsChecked = $true
                    $matched++
                }
            }
            Write-Log ("[OK] Imported {0} WinGet package(s); {1} matched the catalog." -f $apps.Count, $matched)
            if ($matched -lt $apps.Count) { Write-Log '[!] Some imported package IDs are not in the current WinForge catalog.' }
        } catch { Write-Log ("[!] Failed to import WinGet configuration: {0}" -f $_.Exception.Message) }
    }
}

$navExportWinget.Add_Click({ Export-WinForgeWingetConfiguration })
$navImportWinget.Add_Click({ Import-WinForgeWingetConfiguration })

$navExport.Add_Click({
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "JSON Config|*.json"
    $dlg.FileName = "WinForge-Config.json"
    if ($dlg.ShowDialog()) {
        $config = @{
            WFApps = @(foreach ($kvp in $script:AppCheckboxes.GetEnumerator()) { if ($kvp.Value.IsChecked) { $kvp.Key } })
            WFTweaks = @(foreach ($kvp in $script:TweakCheckboxes.GetEnumerator()) { if ($kvp.Value.IsChecked) { $kvp.Key } })
            WFCustomArgs = @{}
        }
        $customArgs = ConvertFrom-WinForgeCustomArgument -Text $txtCustomArgs.Text
        foreach ($entry in $customArgs.GetEnumerator()) { $config.WFCustomArgs[$entry.Key] = $entry.Value }
        $config | ConvertTo-Json | Set-Content -Path $dlg.FileName -Encoding UTF8
        Write-Log "[OK] Config exported to $($dlg.FileName)"
    }
})

$navImport.Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "JSON Config|*.json"
    if ($dlg.ShowDialog()) {
        try {
            $config = Get-Content -Path $dlg.FileName -Raw | ConvertFrom-Json
            foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
            foreach ($cb in $script:TweakCheckboxes.Values) { $cb.IsChecked = $false }
            if ($config.WFApps) {
                foreach ($id in $config.WFApps) {
                    if ($script:AppCheckboxes.ContainsKey($id)) { $script:AppCheckboxes[$id].IsChecked = $true }
                }
            }
            if ($config.WFTweaks) {
                foreach ($k in $config.WFTweaks) {
                    if ($script:TweakCheckboxes.ContainsKey($k)) { $script:TweakCheckboxes[$k].IsChecked = $true }
                }
            }
            $txtCustomArgs.Text = ''
            if ($config.WFCustomArgs) {
                $customLines = foreach ($property in $config.WFCustomArgs.PSObject.Properties) {
                    "{0}={1}" -f $property.Name, $property.Value
                }
                $txtCustomArgs.Text = $customLines -join '; '
            }
            Write-Log "[OK] Config imported from $($dlg.FileName)"
        } catch { Write-Log "[!] Failed to import config: $_" }
    }
})

# ── Launch ─────────────────────────────────────────────────────────────────────
if ($RunTweaks.Count -gt 0) {
    $requestedTweaks = @($RunTweaks | Where-Object { $script:TweakCheckboxes.ContainsKey($_) -and (Test-WinForgeTweakApplicable -Key $_) -and (Test-WinForgeTweakAllowed -Key $_) })
    if ($requestedTweaks.Count -gt 0) {
        try {
            $historyPath = Save-WinForgeTweakHistory -Keys $requestedTweaks
            Write-Log ("Deployment snapshot saved to {0}." -f (Split-Path -Leaf $historyPath))
            foreach ($key in $requestedTweaks) { Invoke-Tweak -Key $key -Undo $false }
            Write-Log '--- Headless tweak deployment complete ---'
        } catch { Write-Log ("[!] Headless tweak deployment failed: {0}" -f $_.Exception.Message) }
    }
}
Write-Log "WinForge v0.2.0 initialized. Ready."
Write-Log "System: $($txtSysInfo.Text -replace "`n",' | ')"
if (-not $NoLaunch) {
    try { $window.ShowDialog() | Out-Null }
    catch {
        [void](Write-WinForgeCrashLog -Exception $_.Exception -Context 'WinForge launch')
        throw
    }
}
