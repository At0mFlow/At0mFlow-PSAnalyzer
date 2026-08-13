[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Name
)

Write-Output "Hello, $Name. Orbit has completed the check."
