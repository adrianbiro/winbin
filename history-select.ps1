param([string]$String)
if($String) {
    Get-History | Where-Object{$_.CommandLine -Match $String} |
        Tee-Object -Variable Obj | 
        Select-Object Id, CommandLine
    "`n{0} total commands in history" -f $Obj.Count
} else {
    Write-Host "Usage:`n`t{0} <string-to-find>" -f $MyInvocation.MyCommand.Name   
}
