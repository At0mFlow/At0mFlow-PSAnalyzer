<#
.SYNOPSIS
Runs PSScriptAnalyzer against a PowerShell file or folder and prints a clear report.

.EXAMPLE
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./examples

.EXAMPLE
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./scripts -Format Json -OutputPath ./analysis.json

.EXAMPLE
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./scripts -FailOnSeverity Warning
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost',
    '',
    Justification = 'Host messages confirm report files written during interactive use.'
)]
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]] $Path = @('.'),

    [ValidateSet('Error', 'Warning', 'Information')]
    [string[]] $Severity = @('Error', 'Warning', 'Information'),

    [string] $Settings,

    [string[]] $ExcludePath = @(
        '*/.git/*',
        '*/node_modules/*',
        '*/vendor/*'
    ),

    [switch] $NoRecurse,

    [ValidateSet('Console', 'Object', 'Json', 'Csv')]
    [string] $Format = 'Console',

    [string] $OutputPath,

    [switch] $FailOnFindings,

    [ValidateSet('None', 'Error', 'Warning', 'Information')]
    [string] $FailOnSeverity = 'None'
)

$ErrorActionPreference = 'Stop'

try {
    $modulePath = Join-Path $PSScriptRoot 'At0mFlow.PSAnalyzer/At0mFlow.PSAnalyzer.psd1'
    Import-Module $modulePath -Force

    $invokeParameters = @{
        Path        = $Path
        Severity    = $Severity
        Recurse     = -not $NoRecurse.IsPresent
        ExcludePath = $ExcludePath
    }

    if (-not [string]::IsNullOrWhiteSpace($Settings)) {
        $invokeParameters.Settings = $Settings
    }

    $report = Invoke-At0mFlowPSAnalyzer @invokeParameters

    if (($Format -eq 'Console') -and -not [string]::IsNullOrWhiteSpace($OutputPath)) {
        throw 'OutputPath is supported with Json and Csv formats only.'
    }

    switch ($Format) {
        'Console' {
            Write-At0mFlowPSAnalyzerReport -Report $report
        }
        'Object' {
            $report
        }
        'Json' {
            $content = $report | ConvertTo-Json -Depth 6
            if ([string]::IsNullOrWhiteSpace($OutputPath)) {
                $content
            }
            else {
                $content | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                Write-Host "Wrote JSON report to $OutputPath"
            }
        }
        'Csv' {
            if ($report.FindingCount -eq 0) {
                $content = '"Severity","RuleName","Path","RelativePath","Line","Column","Message"'
            }
            else {
                $content = $report.Findings |
                    Select-Object Severity, RuleName, Path, RelativePath, Line, Column, Message |
                    ConvertTo-Csv -NoTypeInformation
            }

            if ([string]::IsNullOrWhiteSpace($OutputPath)) {
                $content
            }
            else {
                $content | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                Write-Host "Wrote CSV report to $OutputPath"
            }
        }
    }

    $shouldFail = $false
    if ($FailOnFindings.IsPresent) {
        $shouldFail = $report.FindingCount -gt 0
    }
    elseif ($FailOnSeverity -ne 'None') {
        $severityRank = @{
            Error       = 3
            Warning     = 2
            Information = 1
        }
        $threshold = $severityRank[$FailOnSeverity]
        $shouldFail = @(
            $report.Findings | Where-Object { $severityRank[$_.Severity] -ge $threshold }
        ).Count -gt 0
    }

    if ($shouldFail) {
        exit 1
    }

    exit 0
}
catch {
    Write-Error $_
    exit 2
}
