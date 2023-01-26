# using namespace System.Management.Automation  # TODO
# add line below to $profile to source this file
# using module "C:\Users\biroa\src\winbin\Microsoft.PowerShell_profile.ps1"
# import local functions
# TODO
#foreach($i in (Get-ChildItem -Filter '*-functions.ps1').FullName){ . $i }#| Import-Module}
using module "C:\Users\biroa\src\winbin\lib\math-functions.ps1"
using module "C:\Users\biroa\src\winbin\lib\docker-functions.ps1"
using module "C:\Users\biroa\src\winbin\lib\web-functions.ps1"
using module "C:\Users\biroa\src\winbin\lib\unixlike-functions.ps1"
# Posh
# Import-Module posh-git
# PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle Visual
#Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# PSFzf
# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
# Fix encoding 
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding


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
    $Path = $env:PATH.Split(';')

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

    $env:PATH = [String]::Join(';', $Path)
  }
}

Add-Path -Directory “$HOME\src\winbin”
Set-Alias less C:\Program` Files\Git\usr\bin\less.exe
Set-Alias vim  C:\Program` Files\Git\usr\bin\vim.exe
##  (Get-Command Prompt).ScriptBlock
function prompt {
  "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))$(if (git status){$GB=git branch --show-current;"($GB)" }) ";
}
function gita {
  git status -s;
  git add --all;
}
function gitap {
  Param([switch] $Amend)
  git status -s;
  if ($LASTEXITCODE -eq 0) {
    git add --all;
    if($Amend) {
      git commit --amend
    } else {
      git commit -m "small fixes";
    }
    $cb = git branch --show-current;
    git push origin $cb;
  } 
}

function type-sh-like{
  Param([string] $command)
  (Get-Command $command).ScriptBlock
}

function uname-a {
  Get-CimInstance Win32_OperatingSystem | Select-Object 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture' | Format-Table
}
# function ssh-autocomplete {
#   ### ssh
#   #using namespace System.Management.Automation
#   Register-ArgumentCompleter -CommandName ssh, scp, sftp -Native -ScriptBlock {
#     param($wordToComplete, $commandAst, $cursorPosition)
#     $knownHosts = Get-Content ${Env:HOMEPATH}\.ssh\config `
#     | ForEach-Object { ([string]$_).Split(' ')[0] } `
#     | ForEach-Object { $_.Split(',') } `
#     | Sort-Object -Unique
#     # For now just assume it's a hostname.
#     $textToComplete = $wordToComplete
#     $generateCompletionText = {
#       param($x)
#       $x
#     }
#     if ($wordToComplete -match "^(?<user>[-\w/\\]+)@(?<host>[-.\w]+)$") {
#       $textToComplete = $Matches["host"]
#       $generateCompletionText = {
#         param($hostname)
#         $Matches["user"] + "@" + $hostname
#       }
#     }
#     $knownHosts `
#     | Where-Object { $_ -like "${textToComplete}*" } `
#     | ForEach-Object { [CompletionResult]::new((&$generateCompletionText($_)), $_, [CompletionResultType]::ParameterValue, $_) }
#   }
# }