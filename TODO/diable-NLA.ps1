<#
Disables Network Level Authentication (NLA). You must restart the VM after the script completes for the change to take effect. 
The script itself does not restart the VM. You can use this script to disable NLA if RDP connections are failing with error 
'The remote computer that you are trying to connect to requires Network Level Authentication (NLA), 
but your Windows domain controller cannot be contacted to perform NLA.' or error 'An authentication error has occurred. 
The Local Security Authority cannot be contacted.' NLA is a security feature that should only be disabled temporarily to allow RDP 
connections to succeed until the domain controller connectivity issue has been resolved.
#>
Write-Output 'Configuring registry to disable Network Level Authentication (NLA).'
$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
Set-ItemProperty -Path $path -Name UserAuthentication -Type DWord -Value 0
Write-Output 'Restart the VM for the change to take effect.'