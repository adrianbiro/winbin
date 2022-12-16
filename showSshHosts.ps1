Get-Content ${Env:HOMEPATH}\.ssh\config | 
    ForEach-Object { ([string]$_).Split(' ')[1] } | 
    ForEach-Object { $_.Split(',') } | 
    Sort-Object -Unique |
    Where-Object {$_ -ne "*"} |
    Format-Wide -Column 3
