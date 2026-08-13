@{
    RootModule        = 'At0mFlow.PSAnalyzer.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'c846781f-c036-4a58-8bcc-20430daf4127'
    Author            = 'At0mFlow'
    CompanyName       = 'At0mFlow'
    Copyright         = '(c) 2026 At0mFlow. All rights reserved.'
    Description       = 'A small, readable wrapper around PSScriptAnalyzer for files, folders and CI.'
    PowerShellVersion = '5.1'

    RequiredModules = @(
        @{
            ModuleName    = 'PSScriptAnalyzer'
            ModuleVersion = '1.24.0'
        }
    )

    FunctionsToExport = @(
        'Invoke-At0mFlowPSAnalyzer'
        'Write-At0mFlowPSAnalyzerReport'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('PowerShell', 'PSScriptAnalyzer', 'Linting', 'StaticAnalysis', 'CI')
            LicenseUri = 'https://github.com/At0mFlow/At0mFlow-PSAnalyzer/blob/main/LICENSE'
            ProjectUri = 'https://github.com/At0mFlow/At0mFlow-PSAnalyzer'
        }
    }
}
