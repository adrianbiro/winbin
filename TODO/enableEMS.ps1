#Enable Emergency Management Services (EMS) to allow for serial console connection

bcdedit /ems '{current}' on
bcdedit /emssettings EMSPORT:1 EMSBAUDRATE:115200