# PowerShell script to disable Windows power management on all currently connected serial ports, including USB adapters
# In simpler terms, it prevents Windows from turning off connected serial devices to save power.
# Equivalent to right-clicking on a serial port device in Device Manager > Properties > "Power Management" Tab > Unchecking "Allow the computer to turn off this device to save power."


$hubs = Get-WmiObject Win32_Serialport | Select-Object Name, DeviceID, Description
$powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi
foreach ($p in $powerMgmt) {
    $IN = $p.InstanceName.ToUpper()
    foreach ($h in $hubs) {
        $PNPDI = $h.PNPDeviceID
        if ($IN -like "*$PNPDI*") {
            $p.enable = $False
            $p.psbase.put()
        }
    }
}