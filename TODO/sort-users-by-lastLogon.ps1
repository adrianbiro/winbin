#get last logged user

#Get-ChildItem -Path "C:\Users"|Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime -First 1

Get-WmiObject -Class Win32_NetworkLoginProfile | Sort-Object -Property LastLogon -Descending
