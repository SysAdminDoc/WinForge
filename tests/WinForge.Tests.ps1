Describe 'WinForge core helpers' {
    BeforeAll {
        . (Join-Path (Get-Location) 'WinForge.ps1') -NoElevation -NoLaunch
    }

    It 'parses per-package custom arguments from line and semicolon formats' {
        $parsed = ConvertFrom-WinForgeCustomArgument -Text "Google.Chrome=--scope machine; Mozilla.Firefox=--location `"D:\\Apps`""

        $parsed['Google.Chrome'] | Should -Be '--scope machine'
        $parsed['Mozilla.Firefox'] | Should -Be '--location "D:\\Apps"'
    }

    It 'ignores blank and comment custom-argument entries' {
        $parsed = ConvertFrom-WinForgeCustomArgument -Text "`n# comment`nGoogle.Chrome=--scope user"

        $parsed.Count | Should -Be 1
        $parsed.ContainsKey('Google.Chrome') | Should -BeTrue
    }

    It 'matches misspelled search terms using token fuzzy scoring' {
        $score = Get-WinForgeFuzzyScore -Text 'Remove Widgets' -Query 'disable wdget'

        $score | Should -BeGreaterOrEqual 0.42
    }

    It 'returns the supported package fallback order' {
        Get-WinForgePackageManagerOrder | Should -Be @('winget', 'scoop', 'choco')
    }

    It 'exports and imports a DSC v3 WinGet configuration' {
        $yaml = ConvertTo-WinForgeWingetConfiguration -PackageIds @('Git.Git', 'Microsoft.PowerShell')
        $yaml | Should -Match 'identifier: dscv3'
        $yaml | Should -Match 'type: Microsoft.WinGet/Package'

        $ids = @(ConvertFrom-WinForgeWingetConfiguration -Content $yaml)
        $ids | Should -Be @('Git.Git', 'Microsoft.PowerShell')
    }

    It 'provides registry definitions for multi-value tweaks' {
        $definitions = @(Get-WinForgeTweakRegistryDefinition -Key GameDVR)

        $definitions.Count | Should -Be 2
        $definitions.Name | Should -Contain 'GameDVR_Enabled'
        $definitions.Name | Should -Contain 'AllowGameDVR'
    }

    It 'generates a dry-run script that invokes the selected tweak executor' {
        $scriptText = New-WinForgeDryRunScript -Keys @('Telemetry', 'Hibernation')

        $scriptText | Should -Match "Invoke-Tweak -Key 'Telemetry'"
        $scriptText | Should -Match "Invoke-Tweak -Key 'Hibernation'"
    }

    It 'generates a first-logon payload for packages and tweaks' {
        $payload = New-WinForgeFirstLogonScript -PackageIds @('', 'Git.Git') -TweakKeys @('', 'Telemetry')

        $payload | Should -Match "winget install --id 'Git.Git'"
        $payload | Should -Match '\$winForgePath = Join-Path \$PSScriptRoot'
        $payload | Should -Match '-RunTweaks Telemetry'
    }

    It 'generates a valid FirstLogonCommands XML block' {
        $xmlText = ConvertTo-WinForgeFirstLogonXml -ScriptPath '%SystemDrive%\WinForge\payload.ps1'
        [xml]$xml = $xmlText

        $xml.FirstLogonCommands.SynchronousCommand.Order | Should -Be '1'
        $xml.FirstLogonCommands.SynchronousCommand.CommandLine | Should -Match 'PowerShell.exe'
        $xmlText | Should -Match 'FirstLogonCommands'
    }

    It 'loads a local fleet preset into the profile controls' {
        $path = Join-Path ([IO.Path]::GetTempPath()) ("winforge-fleet-{0}.json" -f [guid]::NewGuid())
        try {
            $profile = [pscustomobject]@{
                WFApps = @('Git.Git')
                WFTweaks = @('Telemetry')
                WFCustomArgs = [pscustomobject]@{ 'Git.Git' = '--scope machine' }
            }
            $profile | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path

            Import-WinForgeFleetPreset -Source $path | Should -BeTrue
            $script:AppCheckboxes['Git.Git'].IsChecked | Should -BeTrue
            $script:TweakCheckboxes['Telemetry'].IsChecked | Should -BeTrue
            $txtCustomArgs.Text | Should -Match 'Git\.Git=--scope machine'
        } finally {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
        }
    }

    It 'does not open a remote session when nothing is selected for apply' {
        foreach ($cb in $script:AppCheckboxes.Values) { $cb.IsChecked = $false }
        foreach ($cb in $script:TweakCheckboxes.Values) { $cb.IsChecked = $false }

        Invoke-WinForgeRemoteMachine -ComputerName 'unused-host' | Should -BeFalse
    }

    It 'switches between dark, light, and high-contrast palettes' {
        Set-WinForgeTheme -Theme Light | Should -BeTrue
        ([string]$window.Resources['Theme.Window'].Color) | Should -Be '#FFF3F4F6'

        Set-WinForgeTheme -Theme 'High Contrast' | Should -BeTrue
        ([string]$window.Resources['Theme.Window'].Color) | Should -Be '#FF000000'

        Set-WinForgeTheme -Theme Dark | Should -BeTrue
    }

    It 'writes and reads a telemetry-free local crash report' {
        $path = Join-Path ([IO.Path]::GetTempPath()) ("winforge-crash-{0}.log" -f [guid]::NewGuid())
        try {
            $exception = [InvalidOperationException]::new('test failure')
            Write-WinForgeCrashLog -Exception $exception -Context 'Pester test' -Path $path | Should -Be $path

            $report = Get-WinForgeCrashReport -Path $path
            $report | Should -Match 'Context: Pester test'
            $report | Should -Match 'test failure'
        } finally {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
        }
    }
}
