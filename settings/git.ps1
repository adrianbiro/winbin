#Requires -RunAsAdministrator
Param( 
    [Parameter(Mandatory = $true)]
    [string] $pathToKey
)
Get-Service ssh-agent | Set-Service -StartupType Automatic -PassThru | Start-Service
start-ssh-agent.cmd
start-ssh-agent.cmd # intentional duplication
ssh-add $pathToKey
git config --global core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe