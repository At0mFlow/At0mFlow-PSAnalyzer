<p align="center">
  <img src="assets/at0mflow-psanalyzer-banner.png" alt="At0mFlow PSAnalyzer, with the GitHub-themed Orbit mascot" width="100%">
</p>

<p align="center">
  <a href="https://github.com/At0mFlow/At0mFlow-PSAnalyzer/actions/workflows/test.yml"><img alt="Tests" src="https://github.com/At0mFlow/At0mFlow-PSAnalyzer/actions/workflows/test.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-2ea44f"></a>
  <a href="https://www.powershellgallery.com/packages/PSScriptAnalyzer"><img alt="PSScriptAnalyzer" src="https://img.shields.io/badge/PSScriptAnalyzer-1.24%2B-2671be"></a>
  <a href="https://at0mflow.com/"><img alt="Explore At0mFlow" src="https://img.shields.io/badge/explore-at0mflow.com-19a7ce"></a>
</p>

# At0mFlow PSAnalyzer

A small, readable wrapper around
[PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) for checking
one PowerShell file or a whole folder.

It gives you clear console results, stable PowerShell objects, JSON or CSV,
plus useful exit codes for CI. It runs locally and does not upload your scripts.

This is a standalone open-source utility. You do not need an At0mFlow account,
and the repository contains none of the private At0mFlow application code.

## Quick start

```powershell
git clone https://github.com/At0mFlow/At0mFlow-PSAnalyzer.git
Set-Location ./At0mFlow-PSAnalyzer

Install-Module -Name PSScriptAnalyzer -MinimumVersion 1.24.0 -Scope CurrentUser

./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./examples/NeedsReview.ps1
```

Scan a folder recursively:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./scripts
```

Use a CI-friendly failure threshold:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 `
    -Path ./scripts `
    -Severity Error, Warning `
    -FailOnSeverity Warning
```

## What the output looks like

```text
                           .-o-.
                             |
                      .------+------.
                 .---'               '---.
              .-'      .-----------.      '-.
       O=====/   .--. |   /\   /\   | .--.   \=====.
            /   / GH \|  /__\ /__\  |/    \   \     \
           |    \____/|             |\____/    |     |
           |          |    \___/    |          |     O
            \         '-------------'         /     /
             '._       .----___----.       _.'     /
                '-----'     | |     '-----'      .'
                         .--' '--.          _..-'
                        /  .---.  \    _..-'
                  O===='__/|||||\__'==='
                           |||||
                            |||
                             V
                            VVV
                             V
                           ORBIT

At0mFlow PSAnalyzer
Scanned 1 PowerShell file with PSScriptAnalyzer 1.25.0.
Findings: 0 error(s), 2 warning(s), 0 information.

[WARNING] examples/NeedsReview.ps1:1:10
  PSUseApprovedVerbs
  The cmdlet 'Check-ServiceHealth' uses an unapproved verb.
```

See the complete checked-in [example output](examples/example-output.txt).
PSScriptAnalyzer versions can change individual messages or findings.

## Useful commands

```powershell
# Return a structured object
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./src -Format Object

# Save the complete report as JSON
./src/Invoke-At0mFlowPSAnalyzer.ps1 `
    -Path ./src `
    -Format Json `
    -OutputPath ./analysis.json

# Save findings as CSV
./src/Invoke-At0mFlowPSAnalyzer.ps1 `
    -Path ./src `
    -Format Csv `
    -OutputPath ./findings.csv

# Use your existing PSScriptAnalyzer settings
./src/Invoke-At0mFlowPSAnalyzer.ps1 `
    -Path ./src `
    -Settings ./PSScriptAnalyzerSettings.psd1
```

Folders are recursive by default. Use `-NoRecurse` for the top level only.
`.git`, `node_modules` and `vendor` folders are excluded by default, and you can
set your own wildcard patterns with `-ExcludePath`.

For all parameters and examples, see the [usage guide](docs/usage.md). Setup and
version details are in [installation](docs/installation.md) and
[requirements](requirements.md).

## Use it as a module

```powershell
Import-Module ./src/At0mFlow.PSAnalyzer/At0mFlow.PSAnalyzer.psd1

$report = Invoke-At0mFlowPSAnalyzer -Path ./scripts
$report.Findings | Where-Object Severity -eq 'Error'
```

`Invoke-At0mFlowPSAnalyzer` returns a report with file and finding counts plus a
normalised findings array. `Write-At0mFlowPSAnalyzerReport` renders that report
for a person at the console.

## What this tool does, and what it does not

At0mFlow PSAnalyzer stays intentionally narrow:

- runs the standard rules from your installed PSScriptAnalyzer module;
- accepts files, folders, severity filters, exclusions and settings files;
- makes the results easier to read or pass into another tool;
- adds predictable exit codes for automation.

It does not score scripts, generate AI explanations, rewrite code, create SOPs,
perform migrations, track changes or send anything to an At0mFlow service.

## Want to go further than a one-off scan?

[At0mFlow](https://at0mflow.com/) is the full product for teams that need more
than lint findings. It adds PowerShell documentation and SOP generation,
cleanup suggestions, migration to Power Automate, change tracking and ownership
tracking.

This open tool is useful on its own. If the work grows from checking a script to
understanding, improving and managing automation over time, that is where
At0mFlow fits.

## Privacy and scope

Analysis happens on your machine through the PSScriptAnalyzer module you have
installed. This repository contains no telemetry, API client, AI prompt,
At0mFlow scoring logic, cleanup engine, migration logic, backend code or customer
data.

The repository includes an automated public-boundary check. It rejects common
product paths, private configuration formats, credential patterns, unexpected
source types and an incorrect Git remote before changes are pushed. See
[PUBLIC_BOUNDARY.md](PUBLIC_BOUNDARY.md) for the exact controls.

## Contributing

Issues and focused pull requests are welcome. Please read
[CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes and use only
synthetic scripts in examples or tests.

## Licence

MIT. See [LICENSE](LICENSE).

Built by [At0mFlow](https://at0mflow.com/) with a little help from Orbit.
