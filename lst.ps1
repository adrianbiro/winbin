<#
    .SYNOPSIS
        ls -t
    .DESCRIPTION  
        Get the last modified item in the current directory.    
    .NOTES
    .LINK
        https://github.com/adrianbiro/winbin
#>
param([Int64] $num = 1)
(Get-ChildItem | Sort-Object -Property "LastWriteTime" -Descending | Select-Object -First $num).Name