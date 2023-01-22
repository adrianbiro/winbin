Param(
    [int] $Month = (get-date -Format 'MM'), # default is current month
    [double] $DownTimeSec,
    [switch] $Verbose
)
$firstDay = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -Month $Month
$lastDay = ($firstDay).AddMonths(1).AddSeconds(-1)
$SecondsInMonth = (3600 * 24) * $lastDay.Day 
$PercentUp = (($SecondsInMonth - $DownTimeSec) / $SecondsInMonth) * 100
if ($Verbose) {
    Write-Host ("{0:f6}% Uptime for {1} month" -f $PercentUp, $Month)
}
else { $PercentUp }