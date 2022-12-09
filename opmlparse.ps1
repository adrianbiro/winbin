<#
    .SYNOPSIS
        opmlparse
    
    .DESCRIPTION  
        Parse URLs from OPML file.
    .NOTES
        Just URLs (./opmlparse.ps1 ./podcasts_opml.xml).XmlUrl
    .LINK
        https://github.com/adrianbiro/winbin
#>
param([String]$p1)

if($p1) {
    if (Test-Path $p1 -PathType Leaf) {
        ([xml]$x = Get-Content $p1).opml.body.outline.outline 
            | Select-Object text, xmlUrl 
            #| ForEach-Object { "{0}`n`t{1}" -f $_.text, $_.xmlUrl }
    } else {
        Write-Warning -Message "$p1 does not exist."
    }
} else {
    "Usage:`n`t{0} <file_opml.xml>" -f $MyInvocation.MyCommand.Name
}
