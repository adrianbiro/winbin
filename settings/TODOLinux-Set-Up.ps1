
New-Item -ItemType Directory -Path "$ENV:HOME/.config/powershell/" -ErrorAction SilentlyContinue | Out-Null

". {0}" -f (Resolve-Path ../Microsoft.PowerShell_profile.ps1).Path > "$ENV:HOME/.config/powershell/Microsoft.PowerShell_profile.ps1" #$PROFILE 