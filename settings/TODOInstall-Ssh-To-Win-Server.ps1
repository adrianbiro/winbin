#https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration
#Requires -RunAsAdministrator
$name = (Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*').Name
Add-WindowsCapability -Online -Name $name
#Remove-WindowsCapability -Online -Name $name
# Start the sshd service
Start-Service sshd
# OPTIONAL but recommended:
Set-Service -Name sshd -StartupType 'Automatic'
# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}
# set default shell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

#TODO keys
#https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
