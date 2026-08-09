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
}
