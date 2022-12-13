<#
    .SYNOPSIS
        Copy full path to the clipboard.
    
    .DESCRIPTION  
        
    .NOTES
        This PowerShell script will copy full path of the file to clipboard. 
        You can specify file as first argument, or it will copy current working directory. 
    .LINK
        https://github.com/adrianbiro/winbin
#>
param([string]$p1)
if($p1) {
    if (!(Test-Path -Path $p1 -PathType "Any")){
        "$p1 does not exist."
        exit
    }
    Set-Clipboard (Resolve-Path $p1).Path
} else {
    Set-Clipboard (Resolve-Path "." ).Path
}
Get-Clipboard
