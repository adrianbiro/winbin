param([string]$p1)
if($p1) {
    $Obj = Get-History | Where-Object{$_.CommandLine -Match $p1} 
    $Obj | Select-Object Id, CommandLine
    "`n{0} total commands in history" -f $Obj.Count
} else {
    Write-Host "Usage:`n`t{0} <string-to-find>" -f $MyInvocation.MyCommand.Name 
    
}