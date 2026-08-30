Set-StrictMode -Version 2.0

function Get-At0mFlowDisplayPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $FullName
    )

    $currentPath = (Get-Location).ProviderPath
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $basePath = $currentPath.TrimEnd([char[]]@('/', '\')) + $separator

    try {
        $baseUri = [System.Uri]::new($basePath)
        $fileUri = [System.Uri]::new($FullName)
        $relativePath = [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($fileUri).ToString())
        return $relativePath.Replace('/', $separator)
    }
    catch {
        return $FullName
    }
}

function Test-At0mFlowExcludedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo] $File,

        [Parameter(Mandatory)]
        [string[]] $ExcludePath
    )

    $normalisedPath = $File.FullName.Replace('\', '/')

    foreach ($pattern in $ExcludePath) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }

        $normalisedPattern = $pattern.Replace('\', '/')
        if (($normalisedPath -like $normalisedPattern) -or ($File.Name -like $normalisedPattern)) {
            return $true
        }
    }

    return $false
}

function Resolve-At0mFlowAnalysisFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]] $Path,

        [Parameter(Mandatory)]
        [bool] $Recurse,

        [Parameter(Mandatory)]
        [string[]] $ExcludePath
    )

    $supportedExtensions = @('.ps1', '.psm1', '.psd1')
    $filesByPath = @{}

    foreach ($inputPath in $Path) {
        $item = Get-Item -LiteralPath $inputPath -ErrorAction Stop
        $candidateFiles = @()

        if ($item.PSIsContainer) {
            $candidateFiles = @(
                Get-ChildItem -LiteralPath $item.FullName -File -Recurse:$Recurse -ErrorAction Stop |
                    Where-Object { $supportedExtensions -contains $_.Extension.ToLowerInvariant() }
            )
        }
        elseif ($supportedExtensions -contains $item.Extension.ToLowerInvariant()) {
            $candidateFiles = @($item)
        }
        else {
            throw "Unsupported file type '$($item.Extension)'. Use a .ps1, .psm1 or .psd1 file."
        }

        foreach ($file in $candidateFiles) {
            if (-not (Test-At0mFlowExcludedPath -File $file -ExcludePath $ExcludePath)) {
                $filesByPath[$file.FullName] = $file
            }
        }
    }

    return @($filesByPath.Values | Sort-Object FullName)
}

function Invoke-At0mFlowPSAnalyzer {
    <#
    .SYNOPSIS
    Analyses PowerShell files with PSScriptAnalyzer and returns a stable report object.

    .DESCRIPTION
    Resolves one or more files or folders, invokes the installed PSScriptAnalyzer
    module and returns normalised findings plus summary counts. Source files are
    read locally and are never uploaded by this module.

    .PARAMETER Path
    One or more .ps1, .psm1 or .psd1 files, or folders containing those files.

    .PARAMETER Severity
    PSScriptAnalyzer severities to include. Defaults to Error, Warning and Information.

    .PARAMETER Settings
    Optional path to a PSScriptAnalyzer settings file.

    .PARAMETER Recurse
    Controls recursive folder scanning. Defaults to true.

    .PARAMETER ExcludePath
    Wildcard patterns matched against normalised full paths and file names.

    .EXAMPLE
    Invoke-At0mFlowPSAnalyzer -Path './scripts'

    .EXAMPLE
    Invoke-At0mFlowPSAnalyzer -Path './Build.ps1' -Severity Error, Warning
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseCmdletCorrectly',
        '',
        Justification = 'The report object is deliberately returned as one pipeline item.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Path = @('.'),

        [ValidateSet('Error', 'Warning', 'Information')]
        [string[]] $Severity = @('Error', 'Warning', 'Information'),

        [string] $Settings,

        [bool] $Recurse = $true,

        [string[]] $ExcludePath = @(
            '*/.git/*',
            '*/node_modules/*',
            '*/vendor/*'
        )
    )

    $analyzerCommand = Get-Command -Name Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue
    if ($null -eq $analyzerCommand) {
        throw 'PSScriptAnalyzer 1.24.0 or newer is required. Run: Install-Module PSScriptAnalyzer -Scope CurrentUser'
    }

    $settingsPath = $null
    if (-not [string]::IsNullOrWhiteSpace($Settings)) {
        $settingsItem = Get-Item -LiteralPath $Settings -ErrorAction Stop
        if ($settingsItem.PSIsContainer) {
            throw "Settings must point to a PSScriptAnalyzer settings file: '$Settings'."
        }
        $settingsPath = $settingsItem.FullName
    }

    $files = @(Resolve-At0mFlowAnalysisFile -Path $Path -Recurse $Recurse -ExcludePath $ExcludePath)
    $findings = New-Object 'System.Collections.Generic.List[object]'

    foreach ($file in $files) {
        $analyzerParameters = @{
            Path     = $file.FullName
            Severity = $Severity
        }

        if ($null -ne $settingsPath) {
            $analyzerParameters.Settings = $settingsPath
        }

        $diagnostics = @(Invoke-ScriptAnalyzer @analyzerParameters)
        foreach ($diagnostic in $diagnostics) {
            $findings.Add([pscustomobject][ordered]@{
                Severity     = $diagnostic.Severity.ToString()
                RuleName     = $diagnostic.RuleName
                Path         = $file.FullName
                RelativePath = Get-At0mFlowDisplayPath -FullName $file.FullName
                Line         = [int] $diagnostic.Line
                Column       = [int] $diagnostic.Column
                Message      = $diagnostic.Message
            })
        }
    }

    $orderedFindings = @(
        $findings |
            Sort-Object @{ Expression = {
                switch ($_.Severity) {
                    'Error' { 0 }
                    'Warning' { 1 }
                    default { 2 }
                }
            } }, RelativePath, Line, Column, RuleName
    )

    $report = [pscustomobject][ordered]@{
        ToolVersion      = '1.0.0'
        AnalyzerVersion  = $analyzerCommand.Module.Version.ToString()
        GeneratedAtUtc   = [DateTime]::UtcNow.ToString('o')
        FilesScanned     = $files.Count
        FindingCount     = $orderedFindings.Count
        Counts           = [pscustomobject][ordered]@{
            Error       = @($orderedFindings | Where-Object Severity -eq 'Error').Count
            Warning     = @($orderedFindings | Where-Object Severity -eq 'Warning').Count
            Information = @($orderedFindings | Where-Object Severity -eq 'Information').Count
        }
        Findings         = [object[]] $orderedFindings
    }

    return $report
}

function Write-At0mFlowPSAnalyzerReport {
    <#
    .SYNOPSIS
    Writes an At0mFlow PSAnalyzer report in a readable console format.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWriteHost',
        '',
        Justification = 'This function exists specifically to render coloured console output.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [psobject] $Report
    )

    process {
        $orbitLines = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Orbit.Console.txt'))
        $logoLines = @(
            '       #####> ########> ######> ###>   ###>#######>##>      ######> ##>    ##>'
            '      ##<--##>[--##<--]##<-####>####> ####|##<----]##|     ##<---##>##|    ##|'
            '      #######|   ##|   ##|##<##|##<####<##|#####>  ##|     ##|   ##|##| #> ##|'
            '      ##<--##|   ##|   ####<]##|##|[##<]##|##<--]  ##|     ##|   ##|##|###>##|'
            '      ##|  ##|   ##|   [######<]##| [-] ##|##|     #######>[######<][###<###<]'
            '      [-]  [-]   [-]    [-----] [-]     [-][-]     [------] [-----]  [--][--]'
        )
        $logoGlyphs = [ordered] @{
            '#' = [char] 0x2588
            '<' = [char] 0x2554
            '>' = [char] 0x2557
            '[' = [char] 0x255A
            ']' = [char] 0x255D
            '-' = [char] 0x2550
            '|' = [char] 0x2551
        }

        Write-Host ('=' * 98) -ForegroundColor DarkGray
        Write-Host ''
        foreach ($orbitLine in $orbitLines) {
            Write-Host $orbitLine -ForegroundColor Green
        }
        Write-Host ''
        foreach ($logoLine in $logoLines) {
            $renderedLogoLine = $logoLine
            foreach ($placeholder in $logoGlyphs.Keys) {
                $renderedLogoLine = $renderedLogoLine.Replace(
                    $placeholder,
                    [string] $logoGlyphs[$placeholder]
                )
            }
            Write-Host $renderedLogoLine -ForegroundColor Cyan
        }
        Write-Host ''
        Write-Host '                     PowerShell clarity.' -ForegroundColor White
        Write-Host '                      Orbit-level control.' -ForegroundColor White
        Write-Host ''
        Write-Host '                   ANALYSE | CLEAN | MIGRATE | MONITOR' -ForegroundColor Green
        Write-Host ''
        Write-Host '                         https://at0mflow.com' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host ('=' * 98) -ForegroundColor DarkGray
        Write-Host ''
        Write-Host 'At0mFlow PSAnalyzer' -ForegroundColor Cyan
        Write-Host ('Scanned {0} PowerShell file{1} with PSScriptAnalyzer {2}.' -f @(
            $Report.FilesScanned,
            $(if ($Report.FilesScanned -eq 1) { '' } else { 's' }),
            $Report.AnalyzerVersion
        ))
        Write-Host ('Findings: {0} error(s), {1} warning(s), {2} information.' -f @(
            $Report.Counts.Error,
            $Report.Counts.Warning,
            $Report.Counts.Information
        ))

        if ($Report.FindingCount -eq 0) {
            Write-Host ''
            Write-Host 'No findings for the selected severities.' -ForegroundColor Green
            return
        }

        foreach ($finding in $Report.Findings) {
            $colour = switch ($finding.Severity) {
                'Error' { 'Red' }
                'Warning' { 'Yellow' }
                default { 'DarkCyan' }
            }

            Write-Host ''
            Write-Host ('[{0}] {1}:{2}:{3}' -f @(
                $finding.Severity.ToUpperInvariant(),
                $finding.RelativePath,
                $finding.Line,
                $finding.Column
            )) -ForegroundColor $colour
            Write-Host ('  {0}' -f $finding.RuleName) -ForegroundColor DarkGray
            Write-Host ('  {0}' -f $finding.Message)
        }

        Write-Host ''
    }
}

Export-ModuleMember -Function @(
    'Invoke-At0mFlowPSAnalyzer'
    'Write-At0mFlowPSAnalyzerReport'
)
