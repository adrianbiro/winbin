using module "C:\Users\biroa\src\winbin\lib\docker-functions.ps1"
using module "C:\Users\biroa\src\winbin\lib\git-functions.ps1"
using module "C:\Users\biroa\src\winbin\lib\math-functions.ps1"
using module "C:\Users\biroa\src\winbin\lib\ssh-functions.ps1"
using module "C:\Users\biroa\src\winbin\lib\unixlike-functions.ps1"
using module "C:\Users\biroa\src\winbin\lib\web-functions.ps1"
<#
  .SYNOPSIS
    The lines above are auto-generated use, ".\settings\fix-pwsh-profile.ps1" to bootstrap $PROFILE
  .DESCRIPTION
    add line below to $profile to source this file
    using module "C:\Users\biroa\src\winbin\Microsoft.PowerShell_profile.ps1"
  .EXAMPLE
    .\settings\fix-pwsh-profile.ps1
#>
# PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle Visual
#Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
# PSFzf
# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# Fix encoding 
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding 
#$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UnicodeEncoding

function Add-Path {
  <#
    .SYNOPSIS
      Adds a Directory to the Current Path
    .DESCRIPTION
      Add a directory to the current path.  This is useful for 
      temporary changes to the path or, when run from your 
      profile, for adjusting the path within your powershell 
      prompt.
    .EXAMPLE
      Add-Path -Directory "C:\Program Files\Notepad++"
    .PARAMETER Directory
      The name of the directory to add to the current path.
  #>

  [CmdletBinding()]
  param (
    [Parameter(
      Mandatory = $True,
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $True,
      HelpMessage = 'What directory would you like to add?')]
    [Alias('dir')]
    [string[]]$Directory
  )

  PROCESS {
    $Path = $ENV:PATH.Split(';')

    foreach ($dir in $Directory) {
      if ($Path -contains $dir) {
        Write-Verbose "$dir is already present in PATH"
      }
      else {
        if (-not (Test-Path $dir)) {
          Write-Verbose "$dir does not exist in the filesystem"
        }
        else {
          $Path += $dir
        }
      }
    }

    $ENV:PATH = [String]::Join(';', $Path)
  }
}
foreach ($i in @(“$HOME\src\winbin”, “$HOME\src\binexe”, “$HOME\bin")) { 
  if (Test-Path -Path $i -PathType "Container") {
    Add-Path -Directory $i 
  }
}
foreach ($i in @(
    "$ENV:ProgramFiles\Git\usr\bin\less.exe", "$ENV:LOCALAPPDATA\Programs\Git\usr\bin\less.exe",
    "$ENV:ProgramFiles\Git\usr\bin\vim.exe", "$ENV:LOCALAPPDATA\Programs\Git\usr\bin\vim.exe"
    "$ENV:ProgramFiles\Git\usr\bin\perl.exe", "$ENV:LOCALAPPDATA\Git\usr\bin\perl.exe",
    "$ENV:ProgramFiles\Git\usr\bin\sed.exe", "$ENV:LOCALAPPDATA\Git\usr\bin\sed.exe"
  )) {
  if (Test-Path -Path $i -PathType "Leaf") {
    # Set-Alias less C:\Program Files\Git\usr\bin\less.exe
    Set-Alias (Split-Path $i -LeafBase) $i 
  }
}

##  (Get-Command Prompt).ScriptBlock
function prompt {
  # fix encoding error when it is set to unicode main -> 慭湩
  #$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding 
  "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))$(if (git status){$GB=git branch --show-current;"($GB)" }) ";
}
