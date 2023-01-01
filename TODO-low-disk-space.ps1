
# Cleanup disk when utilization <15GB
if ( -not ((15 *1GB) -lt (Get-PSDrive | Where-Object {$_.name -eq "C"}).free)){exit 0}
else{exit 0}
"|TODO"
exit 0

$cleanupTypeSelection = 'Temporary Sync Files', 'Downloaded Program Files', 'Memory Dump Files', 'Recycle Bin'

foreach ($keyName in $cleanupTypeSelection) {
    $newItemParams = @{
        Path         = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$keyName"
        Name         = 'StateFlags0001'
        Value        = 1
        PropertyType = 'DWord'
        ErrorAction  = 'SilentlyContinue'
    }
    New-ItemProperty @newItemParams | Out-Null
}

Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -NoNewWindow -Wait