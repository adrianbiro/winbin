
<#
.SYNOPSIS
    Time stamp.
.DESCRIPTION
.NOTES
.LINK
    https://github.com/adrianbiro/winbin.
.EXAMPLE
    foreach($i in 1..5){"{0}: {1}" -f $i, $(ts); sleep 0.1}
#>


param(
    [Parameter(Mandatory = $false,
        HelpMessage = "Offset from UTC")] 
    [switch] $tz,
    [switch] $iso,
    [switch] $time,
    [switch] $date,
    [switch] $date_time,
    [switch] $delta_stdin      
)

function get-timestamp {
    $tform = if ($tz) { "yyyy-MM-dd HH:mm:ss.ffff K" }
    elseif ($iso) { "o" }
    elseif ($time) { "HH:mm:ss" }
    elseif ($date) { "yyyy-MM-dd" }
    elseif ($date_time) { "yyyy-MM-dd HH:mm:ss" }
    else { "yyyy-MM-dd HH:mm:ss.ffff" }

    return (get-date -Format $tform)
}
function get-delta-from-pipeline {
    [cmdletbinding()]
    param(
        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        $pipelineInput
    )
    
    Begin { }
    Process {}
    End {
        $StartTime = get-date
        ForEach ($i in $pipelineInput) {
            # FIXME
            "{0} {1}" -f $i, (NEW-TIMESPAN –Start $StartTime –End ($EndTime = Get-Date)).TotalSeconds
            $StartTime -lt $endtime
            $StartTime = $EndTime
        }
    }
    #End { }
}
if ($delta_stdin) { 
    get-delta-from-pipeline $input
}
else {
    get-timestamp
}
