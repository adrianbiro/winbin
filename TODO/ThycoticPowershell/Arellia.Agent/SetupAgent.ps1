## Version: 1.0.7
## Changed: Friday, May 18, 2018 3:39:48 PM -06:00

Param(
	[Switch] $NoWait,
	[Switch] $Wait,
	[Switch] $NonInteractive
)

## Script setup
$FirewallRuleName = 'Arellia Agent (SSTP-In)'
$ArelliaClientPort = 5593
$AgentCertLocation = 'PMAgent'
   
#----------------------------------------------------------------------------------------------------
function Main
#----------------------------------------------------------------------------------------------------
{
	Setup-Environment

	$existingCertificate = [Arellia.Agent.Management.CoreManagementAgent]::GetCertificate()

	if($existingCertificate -eq $null) {
		# generate a new cert and add it to the agent cert store
		Write-Host 'There is no agent certificate, generating new self-signed certificate.'  
		$cert = New-MachineCertificate

		# get the new cert
		$existingCertificate = [Arellia.Agent.Management.CoreManagementAgent]::GetCertificate()
	}

	if($existingCertificate -ne $null) {
		$thumbprint = $existingCertificate.Thumbprint
		Write-Host "Using agent certificate with thumbprint $thumbprint."

        # Ensure HTTP SSL config
        [Arellia.Agent.Management.CoreManagementAgent]::EnsureSslConfig($thumbprint, $ArelliaClientPort)

		# add firewall rule
		Add-FirewallRule $FirewallRuleName 'System' $ArelliaClientPort
	}
	else {
		Write-Warning 'Unable to determine client certificate. Agent will not be able to communicate with server.'
	}
}

#----------------------------------------------------------------------------------------------------
function Setup-Environment
#----------------------------------------------------------------------------------------------------
{
	$ArgList = '-NoLogo', '-File', "`"$($script:MyInvocation.MyCommand.Path)`""   

	if ($PSVersionTable.CLRVersion.Major -eq 4) {
		if (-not $(Check-IsAdmin)) {
			Write-Host -ForegroundColor Yellow "Relaunching script as Administrator"
		 
			if ($NonInteractive) {
				$ArgList += '-NonInteractive'
			} 
			else {
				$ArgList += '-Wait'
			}
		 
			try {
				Start-Process "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $ArgList
				$NoWait = $true
			} 
			catch [Exception] {
				Write-Host -ForegroundColor Red 'There was a problem attempting to elevate this script using UAC. Please relaunch the script using an elevated PowerShell window.'
			}

			Exit-Script
		}
	} 
	else {
		$EnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'
		$EnvVarOld = [Environment]::GetEnvironmentVariable($EnvVarName)

		Write-Host "CLR Version: $($PSVersionTable.CLRVersion)"
		if ($EnvVarOld) {
			Write-Host "$($EnvVarName): $([Environment]::GetEnvironmentVariable($EnvVarName))"
		}

		try {
			if (Check-IsAdmin) {
				$configPath = [IO.Path]::Combine($(Split-Path $script:MyInvocation.MyCommand.Path), 'powershell.exe.activation_config')
			
				if (-not (Test-Path $configPath)) {
					do {
						$newFolder = [IO.Path]::Combine([IO.Path]::GetTempPath(), [IO.Path]::GetRandomFileName())
					} while (Test-Path $newFolder)

					$configPath = [IO.Path]::Combine($((New-Item -Type Directory $newFolder).FullName), 'powershell.exe.activation_config')
					$createdActivationConfig = $true
					'<?xml version="1.0" encoding="utf-8" ?><configuration><startup useLegacyV2RuntimeActivationPolicy="true"><supportedRuntime version="v4.0"/></startup></configuration>' | Set-Content -Path $configPath -Encoding UTF8
				}

				[Environment]::SetEnvironmentVariable($EnvVarName, $(Split-Path $configPath))
				Write-Host "Starting new PowerShell session running under .NET 4.0 Runtime"

				if ($NonInteractive) {
					$ArgList += '-NonInteractive'
				} 
				else {
					$ArgList += '-Wait'
				}

				Start-Process "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -Wait -NoNewWindow -ArgumentList $ArgList
			
				if ($createdActivationConfig) {
					Write-Verbose "Removing $configPath"
					Remove-Item $configPath -ErrorAction SilentlyContinue
					Remove-Item $(Split-Path $configPath) -ErrorAction SilentlyContinue
				}
			} 
			else {
				Write-Host -ForegroundColor Yellow 'Relaunching script as Administrator'
				$ArgList += '-NoWait'

				Start-Process "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $ArgList
				$NoWait = $true
			}
		} 
		finally {
			[Environment]::SetEnvironmentVariable($EnvVarName, $EnvVarOld)
		}

		Exit
	}
   
	Import-ArelliaModule
}

#----------------------------------------------------------------------------------------------------
function Import-ArelliaModule
#----------------------------------------------------------------------------------------------------
{
	if (-not (Get-Module 'Arellia.Agent')) {
		if (-not (Get-Module -ListAvailable Arellia.Agent)) {
			Write-Error 'Unable to find Arellia.Agent PowerShell module'
			Exit
		}
	  
		Import-Module Arellia.Agent
	}
}

#----------------------------------------------------------------------------------------------------
function Add-FirewallRule
#----------------------------------------------------------------------------------------------------
# This function will:
# OS < 6.0 - It will call netsh to create a TCP:443 rule 
# OS >= 6.0 - It will enable the SSTP-In rule if it exists, otherwise create one that allows TCP:443
#----------------------------------------------------------------------------------------------------
{
	Param (
		[string] $name,	
		[string] $applicationName = $null,
		[int]    $port
	)

	$versionText = $(Get-WmiObject Win32_OperatingSystem).Version
	$version = New-Object -TypeName 'System.Version' -ArgumentList $versionText
    $version6 = New-Object -TypeName 'System.Version' -ArgumentList '6.0.0'
	if ($version -lt $version6) {
		netsh firewall add portopening TCP $port "$name" | out-null
		Write-Host "Firewall rule '$name' has been added using netsh"
	}
	else {
		$fw = New-Object -ComObject hnetcfg.fwpolicy2 
		$rules = $fw.rules

		$sstpRule = $rules | ?{ $_.name -eq $name } | Select-Object -first 1

		if ($sstpRule) {
			$sstpRuleName = ($sstpRule).name
			
			if ($sstpRule.Enabled) {
				Write-Host "Firewall rule '$sstpRuleName' already exists"
			}
			else {
				Write-Host "Firewall rule '$sstpRuleName' exists but is disabled, enabling"
				$sstpRule.Enabled = $true
			}
		} 
		else 
		{
			$rule = New-Object -ComObject HNetCfg.FWRule
			$rule.Name = $name

			if ($applicationName) { 
				$rule.ApplicationName = $applicationName
			}

			try {
				$rule.Protocol = 6  # NET_FW_IP_PROTOCOL_TCP
				$rule.LocalPorts = $port
				$rule.Enabled = $true
				$rule.Grouping = '@sstpsvc.dll,-35001'
				$rule.Profiles = 7  # All
				$rule.Action = 1  # NET_FW_ACTION_ALLOW
				$rule.EdgeTraversal = $false

				$fw.Rules.Add($rule)
		 
				Write-Host "Firewall rule '$name' has been added"
			}
			catch [System.Reflection.TargetInvocationException] {
				if ($_.Exception.InnerException -is [System.Runtime.InteropServices.COMException] -and
					$_.Exception.InnerException.ErrorCode -eq -2147023143) {
					Write-Warning "Firewall service is not running, firewall rule cannot be added"
				} 
				else {
					Write-Error $_
				}
			}
			catch {
				Write-Error $_
			}
		}
	}
}

#----------------------------------------------------------------------------------------------------
function Check-IsAdmin
#----------------------------------------------------------------------------------------------------
{
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
	$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

#----------------------------------------------------------------------------------------------------
function Exit-Script
#----------------------------------------------------------------------------------------------------
{  
	if ($NoWait -or $Host.Name -ne 'ConsoleHost' -or $NonInteractive) {
		Exit
	}

	#If script was started by double clicking on script pause for a key press
	$commandLine = Get-WmiObject -Class Win32_Process -Filter "ProcessID=$PID" | Select -Expand CommandLine
	$parentPID = (Get-WmiObject -Class Win32_Process -Filter "ProcessID=$PID").ParentProcessId
	$parentProcessName = Get-WmiObject -Class Win32_Process -Filter "ProcessID=$parentPID" | Select -Expand ProcessName

	if ($Wait -or ($commandLine.Contains($script:MyInvocation.MyCommand.Name) -and (-not $parentProcessName -or $parentProcessName -eq 'explorer.exe'))) {
		Write-Host -ForegroundColor White "`r`nDone!`r`n"
		Write-Host -NoNewLine Press any key to exit..
		$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
	}

	Exit
}

#----------------------------------------------------------------------------------------------------
# Call Main Function
#----------------------------------------------------------------------------------------------------

Main
Exit-Script

# SIG # Begin signature block
# MIIdrQYJKoZIhvcNAQcCoIIdnjCCHZoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUu9EDrhJqKvpJ2xZI9KwAVElN
# IhigghigMIIEKjCCAxKgAwIBAgIQYAGXt0an6rS0mtZLL/eQ+zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUT1hUR7KsF5gfYKhh/bSoU5obOD8wDQYJKoZIhvcNAQEBBQAEggEA
# ZBGvBVrh4lJIIXOYII6DVRnCzfUt8Xd8nV32CCV3c+uiWjS90hg6vTERxTmXjSkg
# o/RId+9cUmKAu2W10GZX/oEd3Ld7dFCmGKtUr+tekVM/AMuyMGg0e5erAnlOnPmX
# x5NTAmMO8vzZQJhPNGUr+th/DLlTXAPDxGnN+smpZ8LDYRAWzE/hwwSsFj8nm4Ge
# rNyUAbBatkWIEiMf0mBmDV5+lPgVgsGDLn2mW8bKfTg8rJs+lGKIJahH0JEIKV5X
# 03nN72Scj7eR+ChSsvLiixHE5Qhknni8cwPIFg+Wzc8eOamxXr8zejj2xauaMQhS
# sDhbKKV0/5p35cGdxkBuEaGCAm0wggJpBgkqhkiG9w0BCQYxggJaMIICVgIBATCB
# 0zCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNj
# b3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4x
# MzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFyZmllbGR0ZWNoLmNvbS9yZXBvc2l0
# b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgLSBHMgIIH9xY6WYITA4wCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE5MDMxNTAxMDUxNVowIwYJKoZI
# hvcNAQkEMRYEFNROdv+H94XBTPL36FUANhZmuhzPMA0GCSqGSIb3DQEBAQUABIIB
# AEooKQIKFNBfUZ17EVe+syfWzJ7pq9CbyDHU/VOa1zs8/2m/YH4Ar89zeJTUeCox
# ASGTbQKyV6oBMHjqsh0CCx/Yl/pZ55HA9VNdWoG0p91ls9RrGRI782nmp+hZ0DYP
# XGB7bZRM8d8wqxuP+k7aXVXpGTcYS1t0bdwk5yt2DG2lsV5xnri08lYyi0DH0gg7
# 0qMaNy5o7diIkeCcDlV2K3C7c/9rE1d+PIru2yujn+yqCYVb8IeWEgeMhMWgz1Pq
# xZI6wjj9cJh6qtWZygIifYp5z4oQ3uGe1j9/jk8VIk/v+BZVjP/PIE5uCnmoF0vN
# iBM3S0VnFVYZSUWgKx6glvs=
# SIG # End signature block
