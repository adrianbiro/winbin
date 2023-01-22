function is-N-divisible-by-M {
    Param(
        [double] $N,
        [double] $M )
    #((6468 / 11) % 1) -eq 0
    if ($M -eq 0) { 
        return $true
    }
    return (($N / $M) % 1) -eq 0
}

function days-to-EOY {
    return [math]::Round((New-TimeSpan –Start $(get-date) –End $(Get-Date -Day 31 -Month 12)).TotalDays)
}

function seconds-to {
    param (
        [Parameter(Mandatory = $True)]
        [double] $Seconds,
        [switch] $Hours,
        [switch] $Days
    )
    if ($Hours) { 
        return $Seconds / 3600 
    }
    else { 
        return $Seconds / (3600 * 24) 
    }
}
function percent-up-timne {
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
        return ("{0:f6}% Uptime for {1} month" -f $PercentUp, $Month)
    }
    return $PercentUp 
}

function duration-in-hours-from-decimal {
    #Decimal hours = hours + minutes/60 + seconds/3600
    #https://calculatordaily.com/decimal-hours-to-hours-minutes-calculator
    param([double] $Decimal)
    [int] $hours = [math]::Floor($Decimal) 
    [int] $minutes = [math]::Floor(($Decimal * 60) % 60)
    [int] $seconds = [math]::Floor(($Decimal * 3600) % 60)
    return "{0}:{1}:{2}" -f $hours, $minutes, $seconds
  }