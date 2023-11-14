<#
    .SYNOPSIS
        Show Selected Time Zones.
    .DESCRIPTION  
    .NOTES
        Show Available Time Zones
        Get-TimeZone -ListAvailable | select -Property ID,BaseUtcOffset
    .LINK
        https://github.com/adrianbiro/winbin
#>
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
        DateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($(Get-Date), $i)
        TimeZone = $i

    }
}
$Obj | Sort-Object -Property "DateTime" | Select-Object -Property "TimeZone", "DateTime"