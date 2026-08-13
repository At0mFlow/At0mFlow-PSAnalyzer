[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$script:FailureCount = 0

function Assert-That {
    param(
        [Parameter(Mandatory)]
        [bool] $Condition,

        [Parameter(Mandatory)]
        [string] $Message
    )

    if ($Condition) {
        Write-Host "PASS: $Message" -ForegroundColor Green
    }
    else {
        $script:FailureCount++
        Write-Host "FAIL: $Message" -ForegroundColor Red
    }
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repositoryRoot 'src/At0mFlow.PSAnalyzer/At0mFlow.PSAnalyzer.psd1'
$entryPoint = Join-Path $repositoryRoot 'src/Invoke-At0mFlowPSAnalyzer.ps1'
$reviewExample = Join-Path $repositoryRoot 'examples/NeedsReview.ps1'
$examplesFolder = Join-Path $repositoryRoot 'examples'

Import-Module $modulePath -Force

$report = Invoke-At0mFlowPSAnalyzer -Path $reviewExample
Assert-That ($report.FilesScanned -eq 1) 'A single file is counted once.'
Assert-That ($report.FindingCount -gt 0) 'Known analyser findings are returned.'
Assert-That ($report.Findings[0].PSObject.Properties.Name -contains 'RuleName') 'Findings have a stable RuleName property.'
Assert-That ($report.Findings[0].PSObject.Properties.Name -contains 'RelativePath') 'Findings include a readable relative path.'

$folderReport = Invoke-At0mFlowPSAnalyzer -Path $examplesFolder -Recurse $true
Assert-That ($folderReport.FilesScanned -eq 2) 'Folder analysis includes both example scripts.'

$jsonText = & $entryPoint -Path $reviewExample -Format Json | Out-String
$jsonExitCode = $LASTEXITCODE
$jsonReport = $jsonText | ConvertFrom-Json
Assert-That ($jsonExitCode -eq 0) 'JSON output exits successfully when no failure threshold is set.'
Assert-That ($jsonReport.FilesScanned -eq 1) 'JSON output contains the report summary.'
Assert-That ($jsonReport.Findings.Count -gt 0) 'JSON output contains findings.'

$consoleText = & $entryPoint -Path $reviewExample -Format Console 6>&1 | Out-String
Assert-That ($consoleText -match 'PowerShell clarity\.') 'Console output includes the At0mFlow wordmark.'
Assert-That ($consoleText -match 'https://at0mflow\.com') 'Console output includes the At0mFlow link.'

& $entryPoint -Path $reviewExample -Format Object -FailOnFindings | Out-Null
Assert-That ($LASTEXITCODE -eq 1) 'FailOnFindings returns exit code 1 when findings exist.'

if ($script:FailureCount -gt 0) {
    throw "$script:FailureCount test assertion(s) failed."
}

Write-Host 'All tests passed.' -ForegroundColor Cyan
exit 0
