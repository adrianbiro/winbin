# $PROFILE.CurrentUserCurrentHost
# if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force}
# Posh
# Import-Module posh-git

# PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle Visual

# PSFzf
#Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

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
      Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      HelpMessage='What directory would you like to add?')]
    [Alias('dir')]
    [string[]]$Directory
  )

  PROCESS {
    $Path = $env:PATH.Split(';')

    foreach ($dir in $Directory) {
      if ($Path -contains $dir) {
        Write-Verbose "$dir is already present in PATH"
      } else {
        if (-not (Test-Path $dir)) {
          Write-Verbose "$dir does not exist in the filesystem"
        } else {
          $Path += $dir
        }
      }
    }

    $env:PATH = [String]::Join(';', $Path)
  }
}

Add-Path -Directory “C:\Users\AdriánBíro\src\winbin”
Set-Alias lslwcl lslwcl.ps1
##  (Get-Command Prompt).ScriptBlock
function prompt {"PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1))$(if (git status){$GB=git branch --show-current;"($GB)" }) ";
}
function gita {
  git status -s;
  git add --all;
}
function gitap {
  git status -s;
  if ($LASTEXITCODE -eq 0) {
    git add --all;
    git commit -m "small fixes";
    $cb = git branch --show-current;
    git push origin $cb;
  } 
}
