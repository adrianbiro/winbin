$timerseconds = 60 * 2 

$myshell = New-Object -com "Wscript.Shell"

while ([bool]$True) {
    $myshell.sendkeys("{SCROLLLOCK 2}")
    "Awake {0}" -f (Get-Date).ToString()
    Start-Sleep -Seconds $timerseconds
}