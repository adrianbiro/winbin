$exclude = "*.md", "Microsoft.PowerShell_profile.ps1", $MyInvocation.MyCommand.Name, "dotnet-disable-tel.ps1"

Get-ChildItem (Join-Path -Path $HOME -ChildPath "src\winbin") -Exclude $exclude
    | Format-Wide -Column 3 -Property Name