<#
    .SYNOPSIS
        add-firewall
    
    .DESCRIPTION  
        Adds firewall rules for the executable.
    .NOTES
        Run like admin.
    .LINK
        https://github.com/adrianbiro/winbin
    
#>
#Requires -RunAsAdministrator

param (
    [string]$p1
)
if($p1){
    if (!(Test-Path -Path $p1 -PathType Leaf)){
        "$p1 does not exist."
        exit
    }
    $dname = "{0} {1}" -f $p1, (Get-Date -Format "dd/MM/yyyy")
    New-NetFirewallRule -DisplayName $dname -Direction Inbound -Program $p1 -Profile Domain, Private -Action Allow
} else {
    $sname = $MyInvocation.MyCommand.Name
    "Usage:`n`t$sname <prog.exe>"
}
