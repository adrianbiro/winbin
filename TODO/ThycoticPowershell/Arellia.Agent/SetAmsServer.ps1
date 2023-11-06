## Version: 1.0.8
## Changed: Monday, November 4, 2019 5:18:09 PM -07:00

Param(
   [string] $BaseURL,
   [string] $InstallCode
)

#==================================================================================================
function Main
#==================================================================================================
{
   if (-not (Check-IsAdmin)) {
      $argList = '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$($script:MyInvocation.MyCommand.Definition)`""
      if ($BaseURL) {
         $argList += '-BaseURL', $BaseURL, '-InstallCode', $InstallCode
      }
      Start-Process "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $argList
      Exit
   }
   
   Set-AmsServer
   Set-InstallCode
}

#----------------------------------------------------------------------------------------------------
function Restart-Agent
#----------------------------------------------------------------------------------------------------
{
    get-service Arellia* | where {$_.status -eq 'running'} | restart-service
	Write-Host "Restarted Agents"
}

#==================================================================================================
function Check-IsAdmin
#==================================================================================================
{
   $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()) 
   if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) { 
      Write-Host -ForegroundColor Yellow "This script needs to be run as Administrator"
      # If there is no UAC enabled then we are not a member of the administrators group
      if ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction SilentlyContinue).EnableLUA -ne 1) {
         Write-Host -ForegroundColor Red 'UAC is not enabled, unable to elevate script'
         Exit-Script
      }
      return $false
   }
   $true
}

#==========================================================================================================
function Prompt-AmsServer
#==========================================================================================================
{
   try {
      if ($BaseURL) {
         $AmsUri = [Uri] ''
         if (-not [Uri]::TryCreate($BaseURL, [UriKind]::Absolute, [ref] $AmsUri)) {
            # Relative Uri - assume only hostname provided
            $BaseURL = "https://$BaseURL/Tms/"
            if ([Uri]::TryCreate($BaseURL, [UriKind]::Absolute, [ref] $AmsUri)) {
               return $AmsUri
            } else {
               Write-Host -ForegroundColor Yellow "Invalid URL : $BaseURL`n"
               $script:BaseURL = $null
               return $false
            }
         } else {
            return [Uri] $BaseURL
         }
      }
      
      $message = "Enter Thycotic Management Server hostname"
      if ($CurrentBaseURL) {
         $message = $message + " (or press [ENTER] to leave unchanged)"
      }
      
      $script:BaseURL = Read-Host $message
      
      if ([string]::IsNullOrEmpty($BaseURL)) {
         Write-Host
		 Set-InstallCode
         Exit-Script
      }
      
      $AmsUri = [Uri] ''
      if (-not [Uri]::TryCreate($BaseURL, [UriKind]::Absolute, [ref] $AmsUri)) {
         # Relative Uri - assume only hostname provided
         $BaseURL = "https://$BaseURL/Tms/"
         if ([Uri]::TryCreate($BaseURL, [UriKind]::Absolute, [ref] $AmsUri)) {
            return $AmsUri
         } else {
            Write-Host -ForegroundColor Yellow "Invalid URL : $BaseURL`n"
            return $false
         }
      }  
      $AmsUri
   }
   catch {
      return $false
   }  
}

function Set-InstallCode
{
   if (-not $InstallCode)
   {
	   $InstallCode = Read-Host "Please enter the install code (typically in the format AAAA-BBBB-CCCC)"
   }

   if($InstallCode -ne $null -and $InstallCode.Length -gt 0)
   {
	   Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Arellia\AMS -Name InstallCode -Value $InstallCode
	   Write-Host "`nSet install code`n"
   }
   else
   {
	   Write-Host "`nInstall code not provided, skipping`n"
   }
   Restart-Agent
}

#==========================================================================================================
# Create BaseURL registry key if it does not exist
#==========================================================================================================
function Set-AmsServer
#==========================================================================================================
{
   if (-not (Test-Path "HKLM:\Software\Policies\Arellia")) {
      New-Item -Path HKLM:\SOFTWARE\Policies -Name Arellia | Out-Null
   }

   if (-not (Test-Path "HKLM:\Software\Policies\Arellia\AMS")) {
      New-Item -Path HKLM:\SOFTWARE\Policies\Arellia -Name AMS | Out-Null
   }

   if ([string]::IsNullOrEmpty($BaseURL)) {
      $script:CurrentBaseURL = (Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Arellia\AMS).BaseURL
      if ($CurrentBaseURL) {
         Write-Host "`nCurrent Thycotic Management Server instance :  $CurrentBaseURL`n"
      }
   }
   
   while (-not $AmsUri) {
      $AmsUri = Prompt-AmsServer
   }
   
   # User provided wrong scheme
   if ($AmsUri.Scheme -eq 'http') {
      Write-Warning "Thycotic Management Server hostname must use HTTPS scheme, changing"
      $AmsUri = [Uri] $AmsUri.AbsoluteUri.Replace('http:','https:')
   }
      
   $hostname = $AmsUri.DnsSafeHost

   for ($i=3;$i -gt 0;$i--) {
      if (Test-Connection -Quiet -Count 1 -ComputerName $hostname -ErrorAction SilentlyContinue) {
         $foundHost = $true
         break
      }
   }

   if (-not $foundHost) {
      Write-Warning "Unable to verify connectivity to $hostname"
      Write-Host
   }

   Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Arellia\AMS -Name BaseURL -Value $AmsUri.AbsoluteUri
   Write-Host "`nAMS URL set to : $($AmsUri.AbsoluteUri)`n"
}

#==========================================================================================================
function Exit-Script
#==========================================================================================================
{
   $commandLine = Get-WmiObject -Class Win32_Process -Filter "ProcessID=$PID" | Select -Expand CommandLine
   $parentPID = (Get-WmiObject -Class Win32_Process -Filter "ProcessID=$PID").ParentProcessId
   $parentProcessName = Get-WmiObject -Class Win32_Process -Filter "ProcessID=$parentPID" | Select -Expand ProcessName

   if ($commandLine.Contains($script:MyInvocation.MyCommand.Name) -and (-not $parentProcessName -or $parentProcessName -eq 'explorer.exe')) {
      Write-Host -ForegroundColor White "`nDone!`n"
      Write-Host -NoNewLine 'Press any key to exit..'
      $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
   }
   
   Exit
}

#==========================================================================================================
# Call Main function
#==========================================================================================================

Main

# SIG # Begin signature block
# MIIdrwYJKoZIhvcNAQcCoIIdoDCCHZwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaIAg7vEXovmutGjpxl+7+ikf
# k3OgghihMIIEKjCCAxKgAwIBAgIQYAGXt0an6rS0mtZLL/eQ+zANBgkqhkiG9w0B
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
# zqxRMxyMMIIFfTCCBGWgAwIBAgIJAIX7d7LhWRGXMA0GCSqGSIb3DQEBCwUAMIHG
# MQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRz
# ZGFsZTElMCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEzMDEG
# A1UECxMqaHR0cDovL2NlcnRzLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRvcnkv
# MTQwMgYDVQQDEytTdGFyZmllbGQgU2VjdXJlIENlcnRpZmljYXRlIEF1dGhvcml0
# eSAtIEcyMB4XDTE5MDkxNzA3MDAwMFoXDTI0MDkxNzA3MDAwMFowgYcxCzAJBgNV
# BAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMSQw
# IgYDVQQKExtTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBMTEMxKzApBgNVBAMTIlN0
# YXJmaWVsZCBUaW1lc3RhbXAgQXV0aG9yaXR5IC0gRzIwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCuMVEzuSlmretYrlkUguWWZmm50mSOlbbtD6bLXCI9
# vJ9Dlz3yu89Nr5l4BKk7iXTHCW9Wzc9dinlaMewgbaRaW2OCKLw+2sGO+xASW68E
# 4bc1pOhGCaOWdSFM0vcHtGXcF6R+WF5H8L+HjSoYKmwaYJ6rPL6unO2UzIgGPKIf
# hfMETwZ5296EHuj3q1z6VfPzIvf1ctXDNEQ85N52ZsmDE9EkfCniHDnuasWzkFAp
# ErFVXy64j7HkA8EoBU16kz1heAUOMd599iDuJHtHe8fzND4oEZ2ZxiDwzaRJ8Fwh
# FFcXAl8REGow5oU3Zme40zZHq6o4z+TN/6xPpYlGIE1VAgMBAAGjggGpMIIBpTAM
# BgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIGwDAWBgNVHSUBAf8EDDAKBggrBgEF
# BQcDCDAdBgNVHQ4EFgQUZ4R+lxl8Alwvlev4CZwzktIt2awwHwYDVR0jBBgwFoAU
# JUWBaFAmOD07LSy+zWrZtj2zZmMwgYQGCCsGAQUFBwEBBHgwdjAqBggrBgEFBQcw
# AYYeaHR0cDovL29jc3Auc3RhcmZpZWxkdGVjaC5jb20vMEgGCCsGAQUFBzAChjxo
# dHRwOi8vY3JsLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRvcnkvc2ZfaXNzdWlu
# Z19jYS1nMi5jcnQwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5zdGFyZmll
# bGR0ZWNoLmNvbS9yZXBvc2l0b3J5L21hc3RlcnN0YXJmaWVsZDJpc3N1aW5nLmNy
# bDBQBgNVHSAESTBHMEUGC2CGSAGG/W4BBxcCMDYwNAYIKwYBBQUHAgEWKGh0dHA6
# Ly9jcmwuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQEL
# BQADggEBAIGMQz16HKKUD8yZpwOh5Yt+PMIt8US9Gwx8cD3T3Wy4vwvTmalAYNiG
# xHUnPbWrXIYLY2BDXLdYBmzqXfEMzVq9UAVK65G39GW52W6oV4wE8g7PKmerQ8K3
# C2ZI/1iVdtRTtButZlp5px8KR6IYTZ6+wfIKU7QgvwMjvZgWAcfwCo7arNHk8OMV
# ZgtmeVzluVZ/n7R470YO0h/+lIm/zaLhZZJyK6WA320JmxB4yXBCYbJ/DEnXLdU8
# Bs7SYRbYQi8WAE/U+cXLHPPz1v6xLSYhTFYdridGJoOr8QNqzrLzWzFhTWuq53U5
# 4LQSDIkN6Cr7X+0A11RR35thSEwsljAxggR4MIIEdAIBATBlMFExCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwx0aGF3dGUsIEluYy4xKzApBgNVBAMTInRoYXd0ZSBTSEEy
# NTYgQ29kZSBTaWduaW5nIENBIC0gRzICEDQDv3YZ5dLn8leRQ2h+bK4wCQYFKw4D
# AhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZI
# hvcNAQkEMRYEFAnaB31lMHcdOgiID05PdNhgmXWMMA0GCSqGSIb3DQEBAQUABIIB
# AHfN7wW463s/xqRH81CZybToaczekps1hGFuzAodpfLHKLm6+DQJhKmVdovRcZ4o
# VC4FEmg8OI5EQb6DifdxjWY4YZBSOHo5jLnqFGE85M78C0jN/BlXdcuqaeY/U3Q2
# hRLh4grvw7dh8K4Vx4K7S4dV0rP8emMBymfPLKOgJMdmYZLtvJvXocDwDJKFcsfT
# MbYPDBEcoC1WDk0Vd4Dojh56Wb9rRgQu+/z2Le/SEQMa50df3Qgf0z1iBD7AQYuz
# vBkGsEpOj2ODV9611UiHJhPQNvySZoMn7f93uddd8lTwE6O64RGpvanhEJ75L/nM
# /w33mPvugvLKzCOnnc3WKYahggJuMIICagYJKoZIhvcNAQkGMYICWzCCAlcCAQEw
# gdQwgcYxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpT
# Y290dHNkYWxlMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMu
# MTMwMQYDVQQLEypodHRwOi8vY2VydHMuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3Np
# dG9yeS8xNDAyBgNVBAMTK1N0YXJmaWVsZCBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0
# aG9yaXR5IC0gRzICCQCF+3ey4VkRlzAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkxMTA1MDAxODEwWjAjBgkq
# hkiG9w0BCQQxFgQUbuC6agOoAyCm0+hyFd8S+4znsjEwDQYJKoZIhvcNAQEBBQAE
# ggEAPrfL8aXW5qNpHnHiHHEiOOiPbqwWwdYgxps+VDh9fHtD+hImSlI99wQeHvjQ
# bVUynSW4rxoCc9n3seYfwDp8nz6Y4K2J5fYlqEo8pbnHu2KUsblhO48hmOdcja4l
# YN7iNCmNKif17Rq87L/7rJ3oov4mx1V/Jw52nXj9F2Vc/Z6sft8SOWwz7PZVetDm
# MKiugUFRCFWcovV2E9lYgeD5c552We0iKQ1HvwmttIxhOojAyoVIzDqUQoeficUi
# uSRLvgMIwYhzNO0hLrI0R1wsAS++/2htt4XK83/aXggbK6/Zxb/XT2qQ2SznGD/I
# eKkZ/WzTxbBByxUiXprX94pAVw==
# SIG # End signature block
