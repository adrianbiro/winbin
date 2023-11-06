<#
.SYNOPSIS
	This script contains the functions and logic to extract CPU temperature to a log file.
.DESCRIPTION
	Temperature variations above the threshold level can affect the computer performance. This script contains logic to record the cpu temperature to log file for splunk consumption.
    
.NOTES
	Author: Sreejith Kizhakkedathurajan & Kevin Olson
    Created: 2/21/2020
    Updated: 3/23/2020
    Version: 1.1

.LINK
	https://pwc.com
"#>


$Output = @{}

$TempArray = @()
$TempArray = Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation | Select-Object Name, Temperature
$TempOutput=$null

foreach ($item in $TempArray)
{
    $TempKelvin = $item.Temperature
    $TempCelsius = $TempKelvin - 273.15
    $TempFahrenheit = (9/5) * $TempCelsius + 32

    if(($item.name.Contains("TZ.THM0")) -or ($item.name.Contains("TZ.THM")) -or ($item.name.Contains("TZ.CPUZ")))
        {
        $TempOutput=[math]::Round($TempCelsius)
        }
}

$ComputerName = $env:COMPUTERNAME
$UserName =$env:USERNAME

if($TempOutput -eq $null)
{
    $TempOutput = "NULL"
}


 $Output = @{
    'DateTime' = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    'ComputerName' = $ComputerName
    'UserName' = $UserName
    'CpuTemp' = $TempOutput
    }
Write-Output $($Output.Keys.ForEach({"$_=$($Output.$_)"}) -join ',')
