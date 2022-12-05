<#
    .SYNOPSIS
        Get Recovery Key For Bitlocker Volume.
    
    .DESCRIPTION  
        
    .NOTES
        Run like admin.
    .LINK
        https://github.com/adrianbiro/winbin
    
#>
(Get-BitLockerVolume 
    | Where-Object{$_.VolumeStatus -eq 'FullyEncrypted' -and $_.VolumeType -eq 'OperatingSystem'}
    ).KeyProtector.RecoveryPassword