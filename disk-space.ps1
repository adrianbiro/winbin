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

"Disk space:`n`tFree: {0}GB Used: {1}GB Total: {2}GB" -f 
    [math]::Round($dobj.Free/1GB,2), 
    [math]::Round($dobj.Used/1GB,2), 
    [math]::Round(($dobj.Free + $dobj.Used)/1GB, 2) 