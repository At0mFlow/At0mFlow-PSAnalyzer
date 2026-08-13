# Installation

## 1. Check PowerShell

Use Windows PowerShell 5.1 or PowerShell 7.4 or newer:

```powershell
$PSVersionTable.PSVersion
```

## 2. Install PSScriptAnalyzer

```powershell
Install-Module -Name PSScriptAnalyzer -MinimumVersion 1.24.0 -Scope CurrentUser
```

Confirm that PowerShell can find it:

```powershell
Get-Module -ListAvailable PSScriptAnalyzer
```

## 3. Get At0mFlow PSAnalyzer

```powershell
git clone https://github.com/At0mFlow/At0mFlow-PSAnalyzer.git
Set-Location ./At0mFlow-PSAnalyzer
```

Run the included example:

```powershell
./src/Invoke-At0mFlowPSAnalyzer.ps1 -Path ./examples/NeedsReview.ps1
```

## Optional module import

Import the module when you want a structured PowerShell object for further
processing:

```powershell
Import-Module ./src/At0mFlow.PSAnalyzer/At0mFlow.PSAnalyzer.psd1
$report = Invoke-At0mFlowPSAnalyzer -Path ./scripts
$report.Findings | Where-Object Severity -eq 'Error'
```

The repository does not install files into your PowerShell module path. Import
the checked-out module directly, or copy the `At0mFlow.PSAnalyzer` folder into a
module path if that suits your own environment.
