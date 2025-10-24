curl -L -o C:\Windows\Panther\unattend.xml https://raw.githubusercontent.com/adrianbiro/winbin/refs/heads/main/install/vm-unattend.xml
C:\Windows\System32\Sysprep\Sysprep.exe /oobe /unattend:C:\Windows\Panther\unattend.xml /reboot
