<#
    .SYNOPSIS
        Rename OST file to fix sync.
    
    .DESCRIPTION  
        
    .NOTES
        C:\Users\<User_Name>\AppData\Local\Microsoft\Outlook\<username@example.com>.ost
        https://learn.microsoft.com/en-us/outlook/troubleshoot/synchronization/synchronization-issue-between-outlook-owa#how-to-rebuild-the-ost-file
    .LINK
        https://github.com/adrianbiro/winbin
    
#>

Get-Process -Name outlook -ErrorAction SilentlyContinue | Stop-Process -Force

Set-Location $HOME\AppData\Local\Microsoft\Outlook\
$OSTFILE = ls *.ost
$BAKFILE = $OSTFILE.name + ".bak"
Move-Item $OSTFILE.name $BAKFILE
Start-Process outlook