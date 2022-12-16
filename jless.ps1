<#
    .SYNOPSIS
        jless is pager for json.
    .DESCRIPTION  
        Pager for json. Input can be from pipeline or as file.
        PS C:\> 1..500 | ConvertTo-Json | jless.ps1
    .NOTES
        Bash version:
            alias jless="jq '.' -C | less -R"
    .LINK
        https://github.com/adrianbiro/winbin
    
#>
param([string] $file)
if($file) {
    $jsonstring = Get-Content $file
} else {
    $jsonstring = $input
}
$jsonstring | jq '.' -C | C:\Program` Files\Git\usr\bin\less.exe -R #more  #jq is more versatile than pure pwsh  
#$jsonstring | ConvertTo-Json  | more  #out-host -paging 