<#
    .SYNOPSIS
        Show Selected Time Zones.
    .DESCRIPTION
        Show current time:
            .\Show-Selected-TimeZones.ps1 
        Show Custom time or date and time:
            .\Show-Selected-TimeZones.ps1 -Time '20:30:12'
            .\Show-Selected-TimeZones.ps1 -Time '12.05.2012 20:30:12'
    .NOTES
        Central Europe Standard Time is assumed to be default machine configuration.
        If no time but the date is specified, the default time will be 00:00:00.  
        Show all Available Time Zones:
            Get-TimeZone -ListAvailable | select -Property ID,BaseUtcOffset
    .LINK
        https://github.com/adrianbiro/winbin
#>
Param(
    [Parameter(Mandatory = $false)]
    [datetime]$Time = (Get-Date)
)
[string[]]$Zones = @(
    'Pacific Standard Time', 
    'Mountain Standard Time', 
    'Central Standard Time', 
    'Eastern Standard Time', 
    'Greenwich Standard Time', 
    'Central Europe Standard Time',
    'Israel Standard Time', 
    'Central Asia Standard Time', 
    'Singapore Standard Time', 
    'Tokyo Standard Time'
)


$Obj = @()

foreach ($i in $Zones) { 
    $Obj += New-Object psobject -Property @{ 
        DateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($Time, $i)
        TimeZone = $i

    }
}
$Obj | Sort-Object -Property "DateTime" | Select-Object -Property "TimeZone", "DateTime"