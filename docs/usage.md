# Usage

The command accepts a `.ps1`, `.psm1` or `.psd1` file, a folder, or several
paths. Folder scans are recursive unless `-NoRecurse` is supplied.

## Console report

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./scripts
```

Scan several paths:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./build.ps1, ./src, ./tools
```

Only show errors and warnings:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./src -Severity Error, Warning
```

## Exclusions

The wrapper skips `.git`, `node_modules` and `vendor` folders by default. Add or
replace wildcard patterns with `-ExcludePath`:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 `
    -Path . `
    -ExcludePath '*/.git/*', '*/node_modules/*', '*/vendor/*', '*/generated/*'
```

Patterns are matched against full paths normalised with `/`, and against file
names. Use `-ExcludePath '*.Tests.ps1'` to skip matching file names.

## JSON and CSV

Write a JSON report with the scan summary and all findings:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 `
    -Path ./src `
    -Format Json `
    -OutputPath ./analysis.json
```

Write findings as CSV:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 `
    -Path ./src `
    -Format Csv `
    -OutputPath ./analysis.csv
```

Omit `-OutputPath` to send JSON or CSV to the success stream.

## CI exit codes

By default, findings do not make the command fail. Set a threshold when a CI
job should stop:

```powershell
# Fail for errors only
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./src -FailOnSeverity Error

# Fail for errors or warnings
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./src -FailOnSeverity Warning

# Fail for any returned finding
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./src -FailOnFindings
```

Exit codes are:

- `0`: scan completed and the selected failure threshold was not met.
- `1`: findings met the selected failure threshold.
- `2`: the scan could not run, such as a missing dependency or invalid path.

## PSScriptAnalyzer settings

Pass any standard PSScriptAnalyzer settings file through to the underlying
analyser:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 `
    -Path ./src `
    -Settings ./PSScriptAnalyzerSettings.psd1
```

At0mFlow PSAnalyzer does not add proprietary rules, scoring or remediation. The
finding rule names, severities and messages come from your installed
PSScriptAnalyzer version and settings.
