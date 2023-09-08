#Requires -RunAsAdministrator
Param(
[Parameter(Mandatory = $True )]
[string] $restorePointName
)
[string] $RSPname = (Join-String -Separator ' ' -InputObject $restorePointName, (get-date -Format 'O'))

powershell.exe -ExecutionPolicy Bypass -NoExit -Command "Checkpoint-Computer -Description $RSPname -RestorePointType 'MODIFY_SETTINGS'"