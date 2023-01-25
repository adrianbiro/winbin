#Requires -RunAsAdministrator
# netsh is depricated!!
netsh firewall set portopening protocol = TCP port = 1433 name = SQLPort mode = ENABLE scope = SUBNET profile = CURRENT
netsh firewall set portopening protocol = TCP port = 1434 name = SQLPortBrowser mode = ENABLE scope = SUBNET profile = CURRENT
#list
#netstat -abon
#Show-NetFirewallRule | where {$_.enabled -eq ‘true’ -AND $_.direction -eq ‘inbound’}