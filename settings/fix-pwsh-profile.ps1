if(-not ((Split-Path $PWD -LeafBase) -eq "settings")) {
    "Run from '.\settings' directory."
    exit 1
}
[System.IO.FileInfo]$File = (Resolve-Path -Path "..\Microsoft.PowerShell_profile.ps1").Path
#get local pwsh libs 
[string[]]$Libs = @(Get-ChildItem -Path (Resolve-Path -Path "..\lib\").Path -Filter '*-functions.ps1' | ForEach-Object { 
        'using module "{0}"' -f $_.FullName 
    }
) 
#delte lines with old imports 
[string[]]$CleanProfile = @(Get-Content -Path $File | Select-String -Pattern '^using module .*-functions.ps1"' -NotMatch)
#update path for local imports 
Set-Content -Value ([array]$Libs + $cleanProfile) -Path $File
#source profile file
Set-Content -Value "using module `"$File`"" -Path $PROFILE
# Fix excecution warnings
Set-ExecutionPolicy -Scope "CurrentUser" -ExecutionPolicy "Unrestricted"
(Get-ChildItem -Path (Resolve-Path -Path "..\") -Recurse).FullName | ForEach-Object { Unblock-File -Path $_ }

