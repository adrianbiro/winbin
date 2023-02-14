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

function seconds-to-timespan {
    param (
        [Parameter(Mandatory = $True)]
        [double] $Seconds
    )
    return ("{0:hh\:mm\:ss}" -f [timespan]::fromseconds($Seconds))
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

function last-week-firts-and-last-day {
    $days = @{ "Monday" = 0
        "Tuesday"       = 1
        "Wednesday"     = 2 
        "Thursday"      = 3
        "Friday"        = 4
        "Saturday"      = 5 
        "Sunday"        = 6
    }
    $DaysFromMonday = $days["$((get-date).DayOfWeek)"]
    $MondayLastWeek = (get-date).AddDays( - (7 + $DaysFromMonday)) 
    $SundayLastWeek = $MondayLastWeek.AddDays(6) #-Format 'YYYY-mm-DD'
    $Start = get-date -Date ($MondayLastWeek) -Format 'yyyy-MM-dd'
    $End = get-date -Date ($SundayLastWeek) -Format 'yyyy-MM-dd'
    return $Start, $End
}

function round_sigfigs {
    <#Round to specified number of sigfigs#>
    Param(
        [double] $num,
        [int] $sig_figs
    )
    if ($num -eq 0 ) {
        <#Can`t take the log of 0#>
        return 0
    }
    return [math]::Round($num, - [int]([math]::Floor([math]::Log10([Math]::Abs($num))) - ($sig_figs - 1 )))
}

<#function test-round_sigfigs {
    $results = [array]@()
    $results += [PSCustomObject]@{num = [double] 3.1415; sig = [int] 2; res = [double]3.1 }
    $results += [PSCustomObject]@{num = [double] -3.1415; sig = [int] 2; res = [double]-3.1 }
    $results += [PSCustomObject]@{num = [double] 0; sig = [int] 5; res = [double]0 }
    $results += [PSCustomObject]@{num = [double] 12345; sig = [int] 2; res = [double]12000 }
    $results += [PSCustomObject]@{num = [double] -12345; sig = [int] 2; res = [double]-12000 }
    $results += [PSCustomObject]@{num = [double] 1; sig = [int] 2; res = 1 }
    $results += [PSCustomObject]@{num = [double] 0.00098765; sig = [int] 2; res = [double]0.00099 }
    $results | ForEach-Object {
        (round_sigfigs -num $_.num -sig_figs $_sig) #-eq $_.res
    }   
}#>
