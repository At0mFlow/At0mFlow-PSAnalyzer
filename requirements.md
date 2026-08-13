# Requirements

At0mFlow PSAnalyzer deliberately has one runtime dependency: Microsoft's
[PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) module.

## Supported environments

- Windows PowerShell 5.1 on Windows, or PowerShell 7.4 or newer on Windows,
  macOS or Linux.
- PSScriptAnalyzer 1.24.0 or newer. The current tested version is 1.25.0.
- Git is optional and only needed to clone the repository.

Install the dependency from the PowerShell Gallery:

```powershell
Install-Module -Name PSScriptAnalyzer -MinimumVersion 1.24.0 -Scope CurrentUser
```

If `Install-Module` asks whether to trust PSGallery, review the prompt and choose
the option appropriate for your environment.

No At0mFlow account, API key, network service or paid dependency is required.
The wrapper analyses files on the machine where it runs.
