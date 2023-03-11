<#
    .SYNOPSIS
        Check if checksum is valid
    
    .DESCRIPTION  
        
    .NOTES
        This PowerShell script compare sha256sum. 
        You need to specify file as first argument,
        and copy checksum for reference to clipboard.
    .LINK
        https://github.com/adambiro1/winbin
        https://github.com/adrianbiro/winbin
#>
param([string]$File)
if($File) {
    if (-not (Test-Path -Path $File -PathType Leaf)){
        "$File does not exist."
        exit
    }
    $checksum = Get-Clipboard
    $valid = foreach($i in [char]'A'..[char]'F' && 0..9) {$i}
    $ascii = foreach($i in 33..126) {"$([char]$i)"}
    foreach($i in $ascii) { 
        if($valid -contains $i) { continue }
        if($checksum.ToUpper().ToCharArray() -contains $i) {
            "Checksum in clipboard is not valid"   
            exit
        }
    }
    $isoHash = Get-FileHash $File -Algorithm sha256
    if ($isoHash.Hash -eq $checksum.ToUpper()) {
        "Checksum is valid."
    } else {
        "Checksum is not valid"
    }
} else {
    "Usage:`n`t{0} <file>" -f $MyInvocation.MyCommand.Name
}