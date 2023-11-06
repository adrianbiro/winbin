## Version: 1.0.2
## Changed: Friday, 12 December 2014 2:32:59 PM +11:00


Param( 
   [Parameter(Mandatory=$True,Position=1)]
   [Guid]   $ItemId,
   
   [Switch] $LaunchDebugger
)

$psVersion = $PSVersionTable.CLRVersion
Write-Verbose "Detected CLRVersion $psVersion"

if ($psVersion.Major -eq 2) {
   $RunActivationConfigPath = Split-Path $script:MyInvocation.MyCommand.Path
   $EnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'
   $EnvVarOld = [Environment]::GetEnvironmentVariable($EnvVarName)

   if ($EnvVarOld) {
      $message = "Was expecting .NET 4.0 but running under $psVersion"
      Write-Warning $message
      Write-EventLog -LogName 'Arellia' -Source 'Arellia Agent' -EntryType Error -Category 0 -EventId 0 -Message "TaskSchedulerInvoke.ps1 - $message`nCheck that .NET Framework 4.0 or greater is installed" 
      Exit
   }

   [Environment]::SetEnvironmentVariable($EnvVarName, $RunActivationConfigPath)
 
   try {
      if ($LaunchDebugger) {
         Write-Verbose "Launching powershell.exe -inputformat text -file $($script:MyInvocation.MyCommand.Path) -ItemId $($ItemId.ToString()) -LaunchDebugger"
         & "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -inputformat text -file $script:MyInvocation.MyCommand.Path -ItemId $ItemId.ToString() -LaunchDebugger
      } else {
         Write-Verbose "Launching powershell.exe -inputformat text -file $($script:MyInvocation.MyCommand.Path) -ItemId $($ItemId.ToString())"
         & "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -inputformat text -file $script:MyInvocation.MyCommand.Path -ItemId $ItemId.ToString()
      }
   } finally {
      Write-Verbose "Setting Environment Variable $EnvVarName to '$EnvVarOld'"
      [Environment]::SetEnvironmentVariable($EnvVarName, $EnvVarOld)
   }
} else {
   try {
      $script:agentDirectory = Resolve-Path $([IO.Path]::Combine((Get-ItemProperty HKLM:\Software\Arellia\Agent).MsiInstallPath, '..\..\PowerShell')) -ErrorAction Stop
   } catch [Management.Automation.ItemNotFoundException] {
      # Cannot determine Agent PowerShell directory, use default location if it exists
      Write-Warning $_.Exception.Message
      if (Test-Path 'C:\Program Files\Arellia\PowerShell') {
         $script:agentDirectory = 'C:\Program Files\Arellia\PowerShell'
         Write-Verbose "Using default Agent PowerShell directory `'$agentDirectory`'"
      }
   }

   if ($agentDirectory -and ($env:PSModulePath.Split(';') -notcontains $agentDirectory)) {
      Write-Verbose "Adding $agentDirectory to PSModulePath variable"
      $env:PSModulePath = "$($($env:PSModulePath).TrimEnd(';'));$agentDirectory"
   }
   
   if (-not (Get-Module Arellia.Agent)) {
      if (-not (Get-Module -ListAvailable Arellia.Agent)) {
         $error = 'Unable to find Arellia.Agent PowerShell module'
         Write-Verbose $error
         Throw $error
      }
      Write-Verbose "Running Import-Module Arellia.Agent"
      Import-Module Arellia.Agent
   }

   if ($LaunchDebugger) {
      Write-Verbose "Running Invoke-ScheduledCommand -LaunchDebugger $ItemId"
      Invoke-ScheduledCommand -LaunchDebugger $ItemId
   } else {
      Write-Verbose "Running Invoke-ScheduledCommand $ItemId"
      Invoke-ScheduledCommand $ItemId
   }
}

# SIG # Begin signature block
# MIIdrQYJKoZIhvcNAQcCoIIdnjCCHZoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUljftUHtA/ghPsSqlv0zIWb/Z
# y+KgghigMIIEKjCCAxKgAwIBAgIQYAGXt0an6rS0mtZLL/eQ+zANBgkqhkiG9w0B
# AQsFADCBrjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5jLjEoMCYG
# A1UECxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjE4MDYGA1UECxMv
# KGMpIDIwMDggdGhhd3RlLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkx
# JDAiBgNVBAMTG3RoYXd0ZSBQcmltYXJ5IFJvb3QgQ0EgLSBHMzAeFw0wODA0MDIw
# MDAwMDBaFw0zNzEyMDEyMzU5NTlaMIGuMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# dGhhd3RlLCBJbmMuMSgwJgYDVQQLEx9DZXJ0aWZpY2F0aW9uIFNlcnZpY2VzIERp
# dmlzaW9uMTgwNgYDVQQLEy8oYykgMjAwOCB0aGF3dGUsIEluYy4gLSBGb3IgYXV0
# aG9yaXplZCB1c2Ugb25seTEkMCIGA1UEAxMbdGhhd3RlIFByaW1hcnkgUm9vdCBD
# QSAtIEczMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsr8nLPvb2Fvd
# eHsbnndmgcs+vHyu86YnmjSjaDFxODNi5PNxZnmxqWWjpYvVj2AtP0LMqmsywCPL
# LEHd5N/8YZzic7IilRFDGF/Eth9XbAoFWCLINkw6fKXRz4aviKdEAhN0cXMKQlkC
# +BsUa0Lfb1+6a4KinVvnSr0eAXLbS3ToO39/fR8EtCab4LRarEc9VbjXsCZSKAEx
# QGbY2SS99irY7CFJXJv2eul/VTV+lmuNk5Mny5K76qxAwJ/C+IDPXfRa3M50hqY+
# bAtTyr2SzhkGcuYMXDhpxwTWvGzOW/b3aJzcJRVIiKHpqfiYnODz1TEoYRFsZ5aN
# OZnLwkUkOQIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIB
# BjAdBgNVHQ4EFgQUrWyqlGCc7eT/+j4KdCtjA/e2Wb8wDQYJKoZIhvcNAQELBQAD
# ggEBABpA2JVlrAmSicY59BDlqQ5mU1143vokkbvnRFHfxhY0Cu9qRFHqKweKA3rD
# 6z8KLFIWoCtDuSWQP3CpMyVtRRooOyfPqsMpQhvfO0zAMzRbQYi/aytlryjvsvXD
# qmbOe1but8jLZ8HJnBoYuMTDSQPxYA5QzUbF83d597YV4Djbxy8ooAw/dyZ02SUS
# 2jHaGh7cKUGRIjxpp7sC8rZcJwOJ9Abqm+RyguOhCcHpABnTPtRwa7pxpqpYrvS7
# 6Wy274fMm7v/OeZWYdMKp8RcTGB7BXcmer/YB1IsYvdwY9k5vG8cwnncdimvzsUs
# ZAReiDZuMdRAGmI0Nj81Aa6sY6AwggTXMIIDv6ADAgECAhA0A792GeXS5/JXkUNo
# fmyuMA0GCSqGSIb3DQEBCwUAMFExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwx0aGF3
# dGUsIEluYy4xKzApBgNVBAMTInRoYXd0ZSBTSEEyNTYgQ29kZSBTaWduaW5nIENB
# IC0gRzIwHhcNMTcxMjA3MDAwMDAwWhcNMjAxMjA2MjM1OTU5WjCBjzELMAkGA1UE
# BhMCVVMxHTAbBgNVBAgMFERpc3RyaWN0IG9mIENvbHVtYmlhMRMwEQYDVQQHDApX
# YXNoaW5ndG9uMRowGAYDVQQKDBFUaHljb3RpYyBTb2Z0d2FyZTEUMBIGA1UECwwL
# RGV2ZWxvcG1lbnQxGjAYBgNVBAMMEVRoeWNvdGljIFNvZnR3YXJlMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyr+8EZjvSBqhWsI1dAOXUvjyYHQE2gou
# H9OwTXwSIskUiKeBvDrd641ue1ATW4QnKhYHo2enTe8CG8q6d9WfjYnlSwIzuKsA
# f3pTIDURy7ePW5d8UjITWugBdT1KsuF/WoZ357wIh0yZN2Pv+pbxi2IuDrdBZHg6
# +n9rRGJsSMhiZ+n8jUDTlgbwj8KjF6lT61Mcpu0FMUmnARkzVS9CWEazEN0wYqlt
# Qa2jmGD5Za0EhuGa5G7rP1yVqbwDTHk1HEhWIaZ6jzfSwCsfCvBWNFDxktNhm2eL
# ryczmVtuFt0Dvj7wO9UlW+1M2DaAEA5ltvNmBdz7VIJ5SsomDeFC9QIDAQABo4IB
# ajCCAWYwCQYDVR0TBAIwADAfBgNVHSMEGDAWgBRw9qhzOlDyWwpwzRHBaAp28D2l
# VjAdBgNVHQ4EFgQU+aHLoPGThmDJQTwp4jBB+YUxLsEwKwYDVR0fBCQwIjAgoB6g
# HIYaaHR0cDovL3RvLnN5bWNiLmNvbS90by5jcmwwDgYDVR0PAQH/BAQDAgeAMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMG4GA1UdIARnMGUwYwYGZ4EMAQQBMFkwJgYIKwYB
# BQUHAgEWGmh0dHBzOi8vd3d3LnRoYXd0ZS5jb20vY3BzMC8GCCsGAQUFBwICMCMM
# IWh0dHBzOi8vd3d3LnRoYXd0ZS5jb20vcmVwb3NpdG9yeTBXBggrBgEFBQcBAQRL
# MEkwHwYIKwYBBQUHMAGGE2h0dHA6Ly90by5zeW1jZC5jb20wJgYIKwYBBQUHMAKG
# Gmh0dHA6Ly90by5zeW1jYi5jb20vdG8uY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQAp
# c7qvacIWcYE4B3iLU8i1jzn97eyZiNiVAVxQ+vAwHDdoZdS4VEdd4dcNdWj65qyH
# 6IjrVImJWD3SDLNUgGUfXhJlcYu7eV5Ojgdj51GidfqngIUQXUeEx0GbD+s+VPSP
# lcGxt3diqCeYUB1VpTlPREOOnuR6UYS6Yf7RTT7DjGEZgbJpfy3mnSUP3P0KQVEF
# e7f2ortYUhnVsozKcuvs2swfopTXTim2x8Q46s34cf8HMl1b7T7tr7QoCsvsi0q/
# ZVWuP8uzCnpBIBI/HMOxoBY2LuEv4QtOLUsDVPp/FZ1jv2I+TssiDziZtI9eYC72
# rS8lifQQzAWEjFf8NGJVMIIFADCCA+igAwIBAgIBBzANBgkqhkiG9w0BAQsFADCB
# jzELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0
# c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xMjAw
# BgNVBAMTKVN0YXJmaWVsZCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcy
# MB4XDTExMDUwMzA3MDAwMFoXDTMxMDUwMzA3MDAwMFowgcYxCzAJBgNVBAYTAlVT
# MRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMSUwIwYDVQQK
# ExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTMwMQYDVQQLEypodHRwOi8v
# Y2VydHMuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8xNDAyBgNVBAMTK1N0
# YXJmaWVsZCBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDlkGZL7PlGcakgg77pbL9KyUhpgXVO
# bST2yxcT+LBxWYR6ayuFpDS1FuXLzOlBcCykLtb6Mn3hqN6UEKwxwcDYav9ZJ6t2
# 1vwLdGu4p64/xFT0tDFE3ZNWjKRMXpuJyySDm+JXfbfYEh/JhW300YDxUJuHrtQL
# EAX7J7oobRfpDtZNuTlVBv8KJAV+L8YdcmzUiymMV33a2etmGtNPp99/UsQwxaXJ
# DgLFU793OGgGJMNmyDd+MB5FcSM1/5DYKp2N57CSTTx/KgqT3M0WRmX3YISLdkuR
# J3MUkuDq7o8W6o0OPnYXv32JgIBEQ+ct4EMJddo26K3biTr1XRKOIwSDAgMBAAGj
# ggEsMIIBKDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4E
# FgQUJUWBaFAmOD07LSy+zWrZtj2zZmMwHwYDVR0jBBgwFoAUfAwyH6fZMH/EfWij
# YqihzqsHWycwOgYIKwYBBQUHAQEELjAsMCoGCCsGAQUFBzABhh5odHRwOi8vb2Nz
# cC5zdGFyZmllbGR0ZWNoLmNvbS8wOwYDVR0fBDQwMjAwoC6gLIYqaHR0cDovL2Ny
# bC5zdGFyZmllbGR0ZWNoLmNvbS9zZnJvb3QtZzIuY3JsMEwGA1UdIARFMEMwQQYE
# VR0gADA5MDcGCCsGAQUFBwIBFitodHRwczovL2NlcnRzLnN0YXJmaWVsZHRlY2gu
# Y29tL3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEBCwUAA4IBAQBWZcr+8z8KqJOLGMfe
# Q2kTNCC+Tl94qGuc22pNQdvBE+zcMQAiXvcAngzgNGU0+bE6TkjIEoGIXFs+CFN6
# 9xpk37hQYcxTUUApS8L0rjpf5MqtJsxOYUPl/VemN3DOQyuwlMOS6eFfqhBJt2nk
# 4NAfZKQrzR9voPiEJBjOeT2pkb9UGBOJmVQRDVXFJgt5T1ocbvlj2xSApAer+rKl
# uYjdkf5lO6Sjeb6JTeHQsPTIFwwKlhR8Cbds4cLYVdQYoKpBaXAko7nv6VrcPuuU
# SvC33l8Odvr7+2kDRUBQ7nIMpBKGgc0T0U7EPMpODdIm8QC3tKai4W56gf0wrHof
# x1l7MIIFDzCCA/egAwIBAgIQC/PMY88EME1Hw7WHBJ+oBzANBgkqhkiG9w0BAQsF
# ADCBrjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5jLjEoMCYGA1UE
# CxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjE4MDYGA1UECxMvKGMp
# IDIwMDggdGhhd3RlLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxJDAi
# BgNVBAMTG3RoYXd0ZSBQcmltYXJ5IFJvb3QgQ0EgLSBHMzAeFw0xNDA3MjIwMDAw
# MDBaFw0yNDA3MjEyMzU5NTlaMFExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwx0aGF3
# dGUsIEluYy4xKzApBgNVBAMTInRoYXd0ZSBTSEEyNTYgQ29kZSBTaWduaW5nIENB
# IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDZVq/KrWk13jsG
# VgF1NZfSU3xJtv4MGPC2PENvchucSDTwrMmy2Zd9DBO5zoUMLrn2lsxJ5iOgJ1gy
# GEFZbYe+gjVkhuixOuSPdOTONpKuvLV2Jer5JGazeO6DoaP+0QNVVRCuIeixlZQC
# tSzZxfQIIwD+CY0rFwgpjAsWDlga2Qw65N6ZbSL/vRuUKjTLGXqmL+Mr0OZ5mErY
# 60uYZLu34RDGU9mrhHVjDGm38MkbpfdVkSFiWmeBPw95FlfQ7e9sGjVbbUFubZg6
# /UyZQ83qsSlpmTUG52z2BlTjVnnS9WrLyWZK7mu/X6fpj/v37nLb1vsh9S1j4Og7
# jUcXEdhVAgMBAAGjggGDMIIBfzAuBggrBgEFBQcBAQQiMCAwHgYIKwYBBQUHMAGG
# Emh0dHA6Ly90LnN5bWNkLmNvbTASBgNVHRMBAf8ECDAGAQH/AgEAMHMGA1UdIARs
# MGowaAYLYIZIAYb4RQEHMAIwWTAmBggrBgEFBQcCARYaaHR0cHM6Ly93d3cudGhh
# d3RlLmNvbS9jcHMwLwYIKwYBBQUHAgIwIxohaHR0cHM6Ly93d3cudGhhd3RlLmNv
# bS9yZXBvc2l0b3J5MDQGA1UdHwQtMCswKaAnoCWGI2h0dHA6Ly90LnN5bWNiLmNv
# bS9UaGF3dGVQQ0EtRzMuY3JsMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB
# /wQEAwIBBjApBgNVHREEIjAgpB4wHDEaMBgGA1UEAxMRU3ltYW50ZWNQS0ktMS03
# MjUwHQYDVR0OBBYEFHD2qHM6UPJbCnDNEcFoCnbwPaVWMB8GA1UdIwQYMBaAFK1s
# qpRgnO3k//o+CnQrYwP3tlm/MA0GCSqGSIb3DQEBCwUAA4IBAQBiWGZdNi/sf/XH
# qwg1gwoTVLtwi+F6KIBW26wgwSobcBB2/QhfCaWLpmAf9OrtETan1aDhVdIVJ3nR
# ug5pbIfF5wlaCIa/zGsciixXblLN0ZhScyj1NeMlwKtrXCg1uXVDDFWN3kfLX5Q9
# GXFXMzTdc8VY0uuuzOXC+pCZ/QPxizF7UIHjK3doAXsnec8FMiGthEDy9RkDxgQK
# rlHVyDUiOcInfMGKVUsGIc9gYSooyPaC7E7HAbyq3gsSxq4684JGJ7MYtumdnk1K
# AnerKZZ3FOXYwh7mS2DYuLKDJMBXc1sSydLAVicLk3FT6I5VUjexx1orTa1oVAqO
# zqxRMxyMMIIFfDCCBGSgAwIBAgIIH9xY6WYITA4wDQYJKoZIhvcNAQELBQAwgcYx
# CzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNk
# YWxlMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTMwMQYD
# VQQLEypodHRwOi8vY2VydHMuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8x
# NDAyBgNVBAMTK1N0YXJmaWVsZCBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IC0gRzIwHhcNMTgxMDE2MDcwMDAwWhcNMjMxMDE2MDcwMDAwWjCBhzELMAkGA1UE
# BhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJDAi
# BgNVBAoTG1N0YXJmaWVsZCBUZWNobm9sb2dpZXMsIExMQzErMCkGA1UEAxMiU3Rh
# cmZpZWxkIFRpbWVzdGFtcCBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAM6vIONtCudqEs8F/KvxFebFWIXYSc63OfxUG4kDq2sd
# D2WDKASnpyVqPbEUJMKpK8aEy86M8z6lPyxth+ZJ5MOtuXEjBwe+BRh7Tx4xI7uL
# X50BQyPlz80Rob0jzK8z74OcxhlU/xZLuc/gI1OizzzRVker8VbM9WatMunEiy9I
# iaIz9NUkelbXzacwzAru6fDrabbR/xhv6IY9wzLq79DQq3q86I85lhK+aBvJ9qrV
# QIdhfypm8zZkNsBzcxlRRpvWAdYlXRvTPle8wLNx2G50iShYvpNeFBYBGGolZ4cU
# QkvikRMvJxD2helCCNehcZt4CYSYTrt89uWD5JO+D2ECAwEAAaOCAakwggGlMAwG
# A1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgbAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMB0GA1UdDgQWBBR6q6kuLchs4yV49kbWxZsIun8q7zAfBgNVHSMEGDAWgBQl
# RYFoUCY4PTstLL7Natm2PbNmYzCBhAYIKwYBBQUHAQEEeDB2MCoGCCsGAQUFBzAB
# hh5odHRwOi8vb2NzcC5zdGFyZmllbGR0ZWNoLmNvbS8wSAYIKwYBBQUHMAKGPGh0
# dHA6Ly9jcmwuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS9zZl9pc3N1aW5n
# X2NhLWcyLmNydDBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vY3JsLnN0YXJmaWVs
# ZHRlY2guY29tL3JlcG9zaXRvcnkvbWFzdGVyc3RhcmZpZWxkMmlzc3VpbmcuY3Js
# MFAGA1UdIARJMEcwRQYLYIZIAYb9bgEHFwIwNjA0BggrBgEFBQcCARYoaHR0cDov
# L2NybC5zdGFyZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsF
# AAOCAQEAuBRGj0w7m/m/zG7HsLuyiJcTYdfeaFF8qZ48ImAIV/0y87l9pNjjIIy1
# e+NRFD7vlySpKM/iqFFdpZELuYUFf3QAPcathvKXc5ThpwPozV4ZnWdVDeifiUlv
# nFTK9bLnvLqy/spOCjGIQGSLBLDmtJTCOy4c9Olg0xmGI8gQ26xwHtYZsFqEayJW
# 6VkhrDklJP8WNFRwrw1Y1rybg8X69BgmjA8DlfJkOFnQ4JY4LA5IlhIbSrPTx1gQ
# Eom8+HFhDCu2+6GKbm734gD3zvfCIXzLKHq7T/WqhDfJ/bhhA3aj5popw6z8nrbM
# VzalXosnnBMuP2vF33RJCKTtWGvM6jGCBHcwggRzAgEBMGUwUTELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5jLjErMCkGA1UEAxMidGhhd3RlIFNIQTI1
# NiBDb2RlIFNpZ25pbmcgQ0EgLSBHMgIQNAO/dhnl0ufyV5FDaH5srjAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUMuAhHdRDXFjugfxTBHZSxzMBAiAwDQYJKoZIhvcNAQEBBQAEggEA
# ySNs0hewWQyjo2E4dH1bhUd42jOIIy+8FmRNEO48G82YNhHTQvCCkNeC5X5OHWTp
# sc8/ZoDBhcPsOkcbLk+5FSOeZKoxtXRlwjFpACplbV8T//dVUlHYb56IwpVDAPHg
# Hi8UH5M88FdJiI1Fh+sLG1qcOyJ2f8kaXzYTbHRcz94d4/t0zlbOS+cw8VgxPgf2
# Vjkti2GSr+7jxIIr5ns1xbqNjDdiNLIHO2AjzSoBoLiec4ZbZPDQ+pOjE7mfLV2t
# DjImXpZC6QnWkyqPwmA3tykEi4TgwOeVtjwVhP1SXuhgFuC0sOR9+28pod7QcRFc
# gMD4HweNzDjFPgq5oWt/JKGCAm0wggJpBgkqhkiG9w0BCQYxggJaMIICVgIBATCB
# 0zCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNj
# b3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4x
# MzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFyZmllbGR0ZWNoLmNvbS9yZXBvc2l0
# b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgLSBHMgIIH9xY6WYITA4wCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE5MDMxNDIyMTMzOVowIwYJKoZI
# hvcNAQkEMRYEFPwjFjx0vHV2E5Xw7yC+fq/c9x3RMA0GCSqGSIb3DQEBAQUABIIB
# AJSBjOdToBz6jOaFd/XuE3zMGhTCsK17/Z+qzlsdes5AL3yQr8tNRnwNrYIOU9yf
# qFn9UZA8gX3aHVlK+2lIp1iQ4P1fdkavhE9LGL0nCnlRseCuzRncDAmbkKqsY/kk
# GCjJf8RFmraJcq4FYJh5zE6KEidzoKBk//9aoPMFvUHmYxLtU37AOWtlLYhlZfLx
# Pw0TstlnakYUuaG8n6zXu9NzCjVc83aHE+s4W5GM8/0PMu5uQsBBbNXtjxeMaLlc
# pBvoY7Q7E3bTZbDxi0HqwCttjlFeVGZflzyQR+u8ZnIXWsz/T0JbCBfcnaDXYIxL
# aQ6Kpf6rm0RQwS2OL69Jo4s=
# SIG # End signature block
