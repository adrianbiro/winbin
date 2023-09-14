Get-Process `
| Select-Object -Property Id, CPU, WS, Name, CommandLine `
| Sort-Object -Property CPU, WS -Descending -Top 30 `
| Format-Table -AutoSize
