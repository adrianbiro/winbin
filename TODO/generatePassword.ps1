[CmdletBinding()]
param (
    [Parameter()]
    [Int]
    $Length = 16
)
Write-Verbose "Length: $Length"
-join (
    ((48..90) + (96..122)) * $Length `
    | Get-Random -Count $Length `
    | ForEach-Object { 
        [char]$_ 
    }
)