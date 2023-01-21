Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, 
    HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, 
    HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* 
        | select-object DisplayName,DisplayVersion,InstallDate 
        | Out-GridView


