## Version: 1.0.10
## Changed: Thursday, 1 October 2015 11:15:42 PM +10:00

Param(
   [Switch] $StartedByShortcut = $false
)

#==========================================================================================================
function Main
#==========================================================================================================
{
   if ($PSVersionTable.CLRVersion.Major -eq 2) {
      $EnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'
      $EnvVarOld = [Environment]::GetEnvironmentVariable($EnvVarName)
      $RunActivationConfigPath = Split-Path $script:MyInvocation.MyCommand.Path

      if ($EnvVarOld) {
         Write-Host -ForegroundColor Red "Was expecting .NET 4.0 but running under $psVersion"
         Exit-Script
      }

      [Environment]::SetEnvironmentVariable($EnvVarName, $RunActivationConfigPath)
    
      try {
         $cmdArgs = '-NoExit', '-NoLogo', '-File', "`"$($script:MyInvocation.MyCommand.Path)`""
         $script:PSBoundParameters.Keys | % { 
            $cmdArgs += "-$_"
            $cmdArgs += [string] $script:PSBoundParameters[$_]
         }
         Write-Host "Starting new PowerShell console using .NET 4.0 Runtime`n"
         if ($StartedByShortcut) {
            Start-Process "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -NoNewWindow -ArgumentList $cmdArgs
         } else {
            Start-Process "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $cmdArgs
         }
      }
      finally {
         [Environment]::SetEnvironmentVariable($EnvVarName, $EnvVarOld)
      }

      if ($StartedByShortcut) {
         $Host.SetShouldExit(0)
      }
   } else {
      Setup-Imports
      Setup-Icon
      Resize-Window

      # Do not use system proxy settings
      [Net.WebRequest]::DefaultWebProxy = $null

      if (Check-IsAdmin) {
         $Host.UI.RawUI.WindowTitle = 'Administrator: Thycotic Agent PowerShell Session'
      } else {
         $Host.UI.RawUI.WindowTitle = 'Thycotic Agent PowerShell Session'
      }

      $version = (Get-Item "$((Get-Module Arellia.Agent).ModuleBase)\..\..\Agents\Agent\Arellia.Agent.dll").VersionInfo.FileVersion
      if (-not $version) {
         $version = (Get-Module 'Arellia.Agent').Version
      }
      Write-Host -ForegroundColor Yellow "PowerShell console using Arellia.Agent $version and .NET $($PSVersionTable.CLRVersion)`r`n"
      if ($StartedByShortcut) {
         if ((Get-Location).Path -ne (Get-Module Arellia.Agent).ModuleBase) {
            Set-Location (Get-Module Arellia.Agent).ModuleBase
         }
      }
   } 
}

#==========================================================================================================
function Setup-Imports
#==========================================================================================================
{
   if (-not (Get-Module 'Arellia.Agent')) {
      if (-not (Get-Module -ListAvailable Arellia.Agent)) {
         Throw "Unable to import Arellia.Agent module"
      }
      Import-Module Arellia.Agent
   }

   $agentDirectory = (Get-ItemProperty 'HKLM:\SOFTWARE\Arellia\Agent').MsiInstallPath
   $SQLiteLibrary = [IO.Path]::Combine($agentDirectory, 'System.Data.SQLite.dll')

   if ([IntPtr]::Size -eq 4) {
      $InteropDirectory = [IO.Path]::Combine($agentDirectory, 'x86')
   } else {
      $InteropDirectory = [IO.Path]::Combine($agentDirectory, 'x64')
   }

   $SQLiteInteropLib = [IO.Path]::Combine($InteropDirectory, 'SQLite.Interop.dll')

   if ($env:PATH.Split(';') -notcontains $InteropDirectory) {
      $env:PATH = "$($env:PATH);$InteropDirectory"
   }
   
   [Reflection.Assembly]::LoadFrom($SQLiteLibrary) | Out-Null
   
   Add-Type @'
   using System;
   using System.Runtime.InteropServices;

   public class Win32Utils
   {
      public struct RECT
      {
         public int Left;
         public int Top;
         public int Right;
         public int Bottom;
      }

      [DllImport("user32.dll")]
      [return: MarshalAs(UnmanagedType.Bool)]
      public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

      [DllImport("user32.dll")]
      [return: MarshalAs(UnmanagedType.Bool)]
      public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

      [DllImport("kernel32.dll")] 
      public static extern IntPtr GetConsoleWindow();

      [DllImport("user32.dll")]
      public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
   }
'@

   [Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
}

#==========================================================================================================
function Setup-Icon
#==========================================================================================================
{
   try {
      # Use Thycotic icon for powershell window
      $base64IconString = "AAABAAIAEBAAAAAAIABoBAAAJgAAACAgAAAAACAAqBAAAI4EAAAoAAAAEAAAACAAAAABACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALuB/wC7gf8Au4H/ALuB/wC7gf8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAu4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wAAAAAAAAAAAAAAAAAAAAAAu4GuAAAAAAAAAAAAu4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/AAAAAAAAAAAAu4G7ALuB/wAAAAAAAAAAAAAAAAC7gfoAu4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4HGALuB/wC7gf8AAAAAAAAAAAAAAAAAAAAAALuB6wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/AAAAAAAAAAAAAAAAAAAAAAAAAAAAu4HNALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC7gagAu4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALuBgQC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAu4HxALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAu4H2ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAu4H6ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf/AAAD/wAAAf8AAAD/AAAAfwAAADMAAMATAADAAwAA4AMAAPgDAAD4AwAA/AMAAPwDAAD4AwAA//8AAP//AAAoAAAAIAAAAEAAAAABACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wDAhP8AyYv/ALuBxwC/fyQAAAAAAAAAAAD//wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAu4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/AL6D/wDFiP8Au4HXALuBYQC6fxoAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8AvIL/AL6D/wC7gfoAu4HlALuBmgC4ehkAAAAAAAAAAAD//wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H+AMGF/wDRkP8Au4HnALuBZQC/gBgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAu4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8Au4H/ALuB/wC7gf8AvYL/AMGF/wC7gf8Au4HnALuBmgC/gBgAAAAAAAAAAAD//wEAAAAAAAAAAAAA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"
      $iconBytes = [Convert]::FromBase64String($base64IconString)
      $ims = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
      [Win32Utils]::SendMessage([Win32Utils]::GetConsoleWindow(), 0x80, 0, (New-Object System.Drawing.Bitmap $ims).GetHIcon()) | Out-Null
   } catch {
      # silently ignore
   }
}

#======================================================================================================================
function Resize-Window([int] $width  = 125, [int] $height = 30)
#======================================================================================================================
{
   if ($width -gt ($Host.UI.RawUI.MaxPhysicalWindowSize.Width - 10)) {
      $width = ($Host.UI.RawUI.MaxPhysicalWindowSize.Width - 10)
   }

   if ($height -gt ($Host.UI.RawUI.MaxPhysicalWindowSize.Height - 5)) {
      $height = ($Host.UI.RawUI.MaxPhysicalWindowSize.Height - 5)
   }

   $currentSize = $Host.UI.RawUI.BufferSize
   if ($Host.UI.RawUI.BufferSize.Width -lt $width) {
      $currentSize.Width = $width
   }
   if ($Host.UI.RawUI.BufferSize.Height -lt ($height * 10)) {
      $currentSize.Height = ($height * 10)
   }
   $Host.UI.RawUI.BufferSize = $currentSize

   $currentSize = $Host.UI.RawUI.WindowSize

   if ($Host.UI.RawUI.WindowSize.Width -lt $width) {
      $currentSize.Width = $width
      $resized = $true
   }
   if ($Host.UI.RawUI.WindowSize.Height -lt $height) {
      $currentSize.Height = $height
      $resized = $true
   }

   if (-not $resized) {
       return
   }

   $Host.UI.RawUI.WindowSize = $currentSize

   # Ensure window is not resized off screen
   $rect = New-Object Win32Utils+RECT
   $handle = (Get-Process -Id $PID).MainWindowHandle

   [Win32Utils]::GetWindowRect($handle, [ref] $rect) | Out-Null

   [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
   $workingArea = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea

   if ($rect.Right -gt $workingArea.Width) {
      $windowWidth = ($rect.Right - $rect.Left)
      $rect.Left = ($workingArea.Width - $windowWidth) / 2
      $rect.Right = $rect.Left + $windowWidth 
      $moved = $true
   }

   if ($rect.Bottom -gt $workingArea.Height) {
      $windowHeight = ($rect.Bottom - $rect.Top)
      $rect.Top = ($workingArea.Height - $windowHeight) / 2
      $rect.Bottom = $rect.Top + $windowHeight
      $moved = $true
   }

   if ($moved) {
      [Win32Utils]::MoveWindow($handle, $rect.Left, $rect.Top, ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top), $true) | Out-Null
   }
}

#==========================================================================================================
function Check-IsAdmin
#==========================================================================================================
{
   $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
   $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

#==========================================================================================================

Main

# SIG # Begin signature block
# MIIdrQYJKoZIhvcNAQcCoIIdnjCCHZoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU556UecSwXOsMVMr5wJxzBb0+
# wx2gghigMIIEKjCCAxKgAwIBAgIQYAGXt0an6rS0mtZLL/eQ+zANBgkqhkiG9w0B
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
# 9w0BCQQxFgQUFcc2viRDYZ564kg72E4ajEJmaVcwDQYJKoZIhvcNAQEBBQAEggEA
# suVZkxZeL8FYwHcFW2VsG1LKynGe2P0zMN+IsSZ4C/CU7Vsw+VdOh51fYyQgNFof
# Ew4rF6f1XyqR3rZ5dGFEEbe1BDKLIuhuy4wMqMOAWtDAfHHviTAg3WUt4RUtkEVj
# OjgCOIxi5ik20quh8S1OrXfuthzj1cTHHz76pllACqkmY7c7u65ruQKJa84KybEn
# mIygQ3rGEol+hJFQB4UiFuUUvWYsl5VJQgCoVBU0LteHeefs2ZGi0QOIAqQ5H+6T
# 005eQ83Py8jrpo/xhxOSaaQQzxUpPoFFVStb6hkr4eORXsUrgI9yXYMrtN96TV9o
# sRbO5LNrvuRLSkDmPwzU6qGCAm0wggJpBgkqhkiG9w0BCQYxggJaMIICVgIBATCB
# 0zCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNj
# b3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4x
# MzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFyZmllbGR0ZWNoLmNvbS9yZXBvc2l0
# b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgLSBHMgIIH9xY6WYITA4wCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE5MDMxNDIyMTM0MFowIwYJKoZI
# hvcNAQkEMRYEFPHNggXSu1jN2TPsrg549LAcp8fpMA0GCSqGSIb3DQEBAQUABIIB
# AMJQeOdRIrIq36Q/rUCPtc2aO9dbkdh3ofeZ+ER2tFXq2/5KtQPH6MUQXYMCQHLb
# ms61ZAcXsWVtsYiK1cTCkbrysP1SGWSRJTahbifufzFeeTOU8/DnT3NZDMEsB3vx
# M0Gq8VyugZhxDjHQwLqwNBqigifXWWUmsAi8CG4kilck0ww3oLQ5Vy4m7SLOZMFD
# Wi+8qVGJzeN/3N3Sr7AWohIeEk5HiGN6Zj6bF33TKhyL/c/js//Vwo+XnXwchJJO
# bKwUDsgfvVlCDvWhV58J6Ykzk53pM8StYqqG8Yyzz+TJdsR69O7PHk7tvMKRj7Db
# RJc3XSuBNvWyshYL4X3igOY=
# SIG # End signature block
