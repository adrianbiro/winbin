param([string]$p1)
if($p1) {
    Get-History | Where-Object{$_.CommandLine -Match $p1} |
        Tee-Object -Variable Obj | 
        Select-Object Id, CommandLine
    "`n{0} total commands in history" -f $Obj.Count
} else {
    Write-Host "Usage:`n`t{0} <string-to-find>" -f $MyInvocation.MyCommand.Name   
}
