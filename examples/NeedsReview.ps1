function Check-ServiceHealth {
    param(
        [string] $ComputerName = 'localhost'
    )

    Write-Host "Checking $ComputerName"
    Get-Service Spooler
}

Check-ServiceHealth 'server-01'
