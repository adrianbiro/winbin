<#
    .SYNOPSIS
        Tail.
    
    .DESCRIPTION  
        
    .NOTES
        Show last 10 lines.  
    .LINK
        https://github.com/adrianbiro/winbin
    
#>

param([string]$p1)
$selectLines = 10  #TODO -n <num>
if($p1) {
    if (!(Test-Path -Path $p1 -PathType Leaf)){
        "$p1 does not exist."
        exit
    }
    Get-Content $p1 -Last $selectLines 
} else {
    $Input | Select-Object -Last $selectLines
}