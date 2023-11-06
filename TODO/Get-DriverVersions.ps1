$Output = @{}
$DriverPackages = $null

$DriverPackages = Get-WmiObject Win32_PnPSignedDriver | select FriendlyName,  Description, DeviceID, DriverVersion, HardWareID, DeviceName, DriverProviderName, Status, DriverDate | where-object {$PSItem.DriverProviderName -notlike "" -and $PSItem.DriverProviderName -notlike "*Microsoft*"}

Foreach ($DriverPackage in $DriverPackages)
{
    # Do some formatting for Intel drivers as the vendor name is not consistent
    If ($DriverPackage.driverprovidername -like "*Intel*")
    {
        $DriverPackage.driverprovidername = "Intel"
    }
    $Output = @{
       'DeviceName' = "`"$($DriverPackage.DeviceName)`""
       'DriverVersion' = $DriverPackage.DriverVersion
       'FriendlyName' ="`"$($DriverPackage.FriendlyName)`""
       'Description' = "`"$($DriverPackage.Description)`""
       'DeviceID' = "`"$($DriverPackage.DeviceID)`""
       'HardWareID' = "`"$($DriverPackage.HardWareID)`""
       'Status' = "`"$($DriverPackage.Status)`""
       'DriverVendor' = "`"$($DriverPackage.DriverProviderName)`""
       'DriverDate' = "`"$($DriverPackage.DriverDate.substring(0, 8))`""
    }
    Write-Output $($Output.Keys.ForEach({"$_=$($Output.$_)"}) -join ' ')
}