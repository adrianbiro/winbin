
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
    [switch] $tz,
    [switch] $iso,
    [switch] $time,
    [switch] $date,
    [switch] $date_time
)
$tform = if($tz){ "yyyy-MM-dd HH:mm:ss.ffff K" }
elseif ($iso) { "o" }
elseif ($time) {"HH:mm:ss"}
elseif ($date) {"yyyy-MM-dd"}
elseif ($date_time) {"yyyy-MM-dd HH:mm:ss"}
else { "yyyy-MM-dd HH:mm:ss.ffff" }

get-date -Format $tform
