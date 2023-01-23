<#
    .SYNOPSIS
        Tail.
    
    .DESCRIPTION  
        
    .NOTES
        Show last 10 lines.  
    .LINK
        https://github.com/adrianbiro/winbin
    
#>

param(
    [Alias("p")]
    [string]$path,
    [Alias("n")]
    [int] $number = 10
)
if ($path) {
    if (!(Test-Path -Path $path -PathType Leaf)) {
        "$path does not exist."
        exit
    }
    Get-Content $path -Head $number 
}
else {
    $Input | Select-Object -First $number
}