<#
    .SYNOPSIS
        Enable Bitlocker.
    
    .DESCRIPTION  
        
    .NOTES
        Run like admin.
    .LINK
        https://github.com/adrianbiro/winbin
    
#>
#Requires -RunAsAdministrator

$BitLockerVolumeInfo = (Get-BitLockerVolume 
    | Where-Object -FilterScript { 
        $PSItem.VolumeType -eq 'OperatingSystem' })
$BootDrive = $BitLockerVolumeInfo.MountPoint

#Enable-BitLocker -MountPoint $BootDrive  # TODO