<#
    .SYNOPSIS
        Sync documents to google drive

    .LINK
        https://github.com/adrianbiro/winbin

#>


$HomeDocuments = Get-ChildItem -Path $ENV:HOMEPATH -Filter "Documents"
$HomeSrc = Get-ChildItem -Path $ENV:HOMEPATH -Filter "src"
$HomeBin = Get-ChildItem -Path $ENV:HOMEPATH -Filter "bin"

$GoogleDrive = (Get-PSDrive -PSProvider "FileSystem" | Where-Object { $_.Description -eq "Google Drive" }).Root
$MyDrive = Get-ChildItem -Path $GoogleDrive  -Filter "My Drive"
$BkpFolder = Join-Path -Path $MyDrive -ChildPath ("Documents from {0}" -f (hostname))

if (-not (Test-Path -Path $BkpFolder -PathType "Container")) {
    New-Item -ItemType Directory -Path $BkpFolder | ForEach-Object {
        "Creating Back-up Folder:`n`t{0}" -f $BkpFolder
    }
}
function Copy-Data {
    Param(
        $Src, $Dest, $Exclude 
    ) 
    Write-Information -MessageData ("Backing-up data from:`n`t{0}" -f $Src) -InformationAction Continue

    Copy-Item -Path $Src -Destination $Dest -Exclude $Exclude -Recurse -Force

    Write-Information -MessageData "Finished." -InformationAction Continue
}

Copy-Data -Src "$HomeDocuments\*" -Dest  $BkpFolder -Exclude "OneNote Notebooks", "PowerShell"
Copy-Data -Src $HomeSrc -Dest  $BkpFolder 
Copy-Data -Src $HomeBin -Dest  $BkpFolder 
