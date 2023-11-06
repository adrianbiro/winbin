param([string]$BaseUrlValue)

$BaseUrlPath = "HKLM:\Software\Policies\Arellia\AMS"
$logPath = "C:\ProgramData\Arellia\cert-health.log"

function Write-Message
{
	param([string]$message, $append = $true)
	
	if(-not $append)
	{
		if(Test-Path $logPath)
		{
			$oldLog = "$logPath.old"
			if(Test-Path $oldLog)
			{
				Remove-Item $oldLog
			}
			Move-Item $logPath $oldLog
		}
	}
	
	if(-not (Test-Path $logPath))
	{
		New-Item $logPath | Out-Null
		$acl = Get-Acl $logPath
		$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users","FullControl","Allow")
		$acl.SetAccessRule($rule)
		Set-Acl $logPath $acl
	}
	
	Write-Output $message | Out-File $logPath -Append:$append
}

if ((get-item $logpath).lastwritetime.date -ne (get-date).date)
{
	Write-Message "$(get-date -format g) Script start" $false
}
else
{
	Write-Message "$(get-date -format g) Script start"
}

try
{
	$timeout = new-timespan -Minutes 30
	$sw = [diagnostics.stopwatch]::StartNew()
	while ($sw.elapsed -lt $timeout) {
  		if ((resolve-dnsname -name gp-internal-aware.pwcinternal.com).IPAddress -eq "10.34.255.250")
		{
			Write-Message "$(get-date -format g) Resolved gp-internal-aware.pwcinternal.com"
			break
		}
		else
		{
			Write-Message "$(get-date -format g) Unable to resolve gp-internal-aware.pwcinternal.com.  Retry in 2 minutes..."
		}
		Start-sleep -seconds 120
	}

	$psd1path = "C:\Program Files\Thycotic\Powershell\Arellia.Agent\Arellia.Agent.psd1"
	
	Write-Message "$(get-date -format g) Attempting to load $psd1path"
	write-host "running..."
	if (-not (Test-Path $psd1path))
	{
		throw "Unable to find '$psd1path'"
	}

	Import-Module $psd1path
	
	if(($BaseUrlValue -eq $null) -or ($BaseUrlValue.Length -eq 0))
	{
		throw "Invalid BaseURLValue '$BaseUrlValue'"
	}
	
	if(-not (Test-Path $BaseUrlPath))
	{
		New-Item $BaseUrlPath -Force | Out-Null
		Write-Message "$(get-date -format g) Created $BaseUrlPath"
	}
	
	$regkey = Get-Item $BaseUrlPath
	$currentBaseUrl = $regkey.GetValue("BaseUrl")
	if($currentBaseUrl -ne $BaseUrlValue)
	{
		Write-Message "$(get-date -format g) Changing BaseUrl from '$currentBaseUrl' to '$BaseUrlValue'. Agent service restart required."
		Set-ItemProperty -Path $BaseUrlPath -Name "BaseUrl" -Value $BaseUrlValue
		  
		Write-Message "$(get-date -format g) Attempting to restart ArelliaAgent Service"
		  
		Start-Sleep -Seconds 3
		Restart-Service ArelliaAgent
	}
	
	$certStore = "Cert:\LocalMachine\PMAgent"
	
	if(-not (Test-Path $certStore))
	{
		throw "Unable to find '$certStore'"
	}
	
	$certs = Get-ChildItem $certStore
	
	if($certs.Count -gt 1)
	{
		Write-Message "$(get-date -format g) More than 1 certificate was found, cleaning up"
		[Arellia.Diagnostics.Logger]::Error("More than 1 certificate was found, cleaning up")
		
		$sortedByCreation = $certs | Sort-Object { $_.NotBefore } 
		
		$sortedByCreation | Where-Object { $_.Thumbprint -ne $sortedByCreation[0].Thumbprint } | ForEach-Object {
			Remove-Item $_.PSPath
			Write-Message "$(get-date -format g) Remove $($_.PSPath)"
		}
		
		$existingHttpConfig = Get-HttpConfig | Where-Object { $_.AppId -eq [Arellia.Agent.Management.CoreManagementAgent]::ArelliaAgentHttpConfigAppId }
		
		if($existingHttpConfig -ne $null)
		{
			Remove-HttpConfig $existingHttpConfig
			Write-Message "$(get-date -format g) Removed existing http config for thumbprint $($existingHttpConfig.SslCertThumbprint)"
		}
		
		$ipEndpoint = New-Object System.Net.IPEndPoint(0, 5593)
		$newHttpConfig = New-Object Arellia.HttpConfig.SslEntry($ipEndpoint, $sortedByCreation[0].Thumbprint, "PMAgent", [Arellia.Agent.Management.CoreManagementAgent]::ArelliaAgentHttpConfigAppId)
		$newHttpConfig.DefaultCertCheckMode = "NoCheck"

		Set-HttpConfig $newHttpConfig
		
		Write-Message "$(get-date -format g) Set-HttpConfig, attempting to restart ArelliaAgent Service"
		
		Start-Sleep -Seconds 3
		Restart-Service ArelliaAgent
	}
	else
	{
		Write-Message "$(get-date -format g) Only one certificate found, nothing to fix."
	}
	
	$policyCount = 0
	$tries = 0
	
	while($policyCount -lt 2)
	{
		$policyCount = (Get-Item HKLM:\Software\Policies\Arellia\Ams\Policies\).Property.Count
		if($policyCount -lt 10)
		{
			Start-AmsRegistration
			Start-Sleep -Seconds 15
		}
		
		$tries = $tries + 1
		if($tries -gt 10)
		{
			break;
		}
	}
	
	Write-Message "$(get-date -format g) Policy count $policyCount after $tries tries"
}
catch
{
	[Arellia.Diagnostics.Logger]::Exception($_.Exception, "Critical Exception while ensuring Agent Health")
	Write-Message $_.Exception
}
