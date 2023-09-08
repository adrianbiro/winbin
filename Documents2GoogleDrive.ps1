<#
    .SYNOPSIS
        Sync documents to google drive

    .LINK
        https://github.com/adrianbiro/winbin

#>


$HomeDocuments = Get-ChildItem -Path $ENV:HOMEPATH -Filter "Documents"
$GoogleDrive = (Get-PSDrive -PSProvider "FileSystem" | Where-Object { $_.Description -eq "Google Drive" }).Root
$MyDrive = Get-ChildItem -Path $GoogleDrive  -Filter "My Drive"
$BkpFolder = Join-Path -Path $MyDrive -ChildPath ("Documents from {0}" -f (hostname))

if (-not (Test-Path -Path $BkpFolder -PathType "Container")) {
    New-Item -ItemType Directory -Path $BkpFolder | ForEach-Object {
        "Creating Back-up Folder:`n`t{0}" -f $BkpFolder
    }
}
Write-Information -MessageData ("Backing-up data from:`n`t{0}" -f $HomeDocuments) -InformationAction Continue

Copy-Item -Path "$HomeDocuments\*" -Destination $BkpFolder -Exclude "OneNote Notebooks", "PowerShell" -Recurse

Write-Information -MessageData "Finished." -InformationAction Continue