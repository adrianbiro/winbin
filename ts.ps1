
<#
.SYNOPSIS
    Time stamp with optional UTC time zone offset.
.DESCRIPTION
    -tz flag for UTC time zone offset.
.NOTES
.LINK
    https://github.com/adrianbiro/winbin.
.EXAMPLE
    foreach($i in 1..5){"{0}: {1}" -f $i, $(ts); sleep 0.1}
#>


param([switch] $tz)
if($tz){$tzform = " K"}
get-date -Format "yyyy/MM/dd HH:mm:ss.ffff$tzform"
