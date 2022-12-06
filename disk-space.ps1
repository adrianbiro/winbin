<#
    .SYNOPSIS
        Check drive space
    
    .DESCRIPTION  
        
    .NOTES
        This PowerShell script check space on drive. 
        You need to specify drive letter as first argument,
        to change from default C.
    .LINK
        https://github.com/adrianbiro/winbin
#>
param([string]$p1)
if($p1) { $drive = $p1 } else { $drive = "C"}
$dobj = Get-PSDrive $drive
$free = ($dobj.Free / 1024 / 1024) / 1024
$used = ($dobj.Used / 1024 / 1024) / 1024
$total = $free + $used

"Disk space:`n`tFree: {0}GB Used: {1}GB Total: {2}GB" -f [math]::Round($free,2), [math]::Round($used,2), [math]::Round($total, 2) 