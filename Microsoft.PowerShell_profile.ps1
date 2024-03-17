# "C:\Users\biroa\src\winbin\lib\docker-functions.ps1"
#using module "C:\Users\biroa\src\winbin\lib\git-functions.ps1"
#using module "C:\Users\biroa\src\winbin\lib\math-functions.ps1"
#using module "C:\Users\biroa\src\winbin\lib\ssh-functions.ps1"
#using module "C:\Users\biroa\src\winbin\lib\unixlike-functions.ps1"
#using module "C:\Users\biroa\src\winbin\lib\web-functions.ps1"
<#
  .SYNOPSIS
    The lines above are auto-generated use, ".\settings\fix-pwsh-profile.ps1" to bootstrap $PROFILE
  .DESCRIPTION
    add line below to $profile to source this file
    using module "C:\Users\biroa\src\winbin\Microsoft.PowerShell_profile.ps1"
  .EXAMPLE
    .\settings\fix-pwsh-profile.ps1
#>
#Requires -Version 7.0
# ForEach-Object -InputObject @(
# "lib\git-functions.ps1",
# "lib\math-functions.ps1",
# "lib\ssh-functions.ps1",
# "lib\unixlike-functions.ps1",
# "lib\web-functions.ps1"
# ) {
# . (Resolve-Path -Path (Join-Path -Path $script:MyInvocation.MyCommand.Path -ChildPath [str]$_)).Path
# }
# PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle Visual
#Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadLineKeyHandler -Key 'Alt+(' `
  -BriefDescription ParenthesizeSelection `
  -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
  -ScriptBlock {
  param($key, $arg)

  $selectionStart = $null
  $selectionLength = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  if ($selectionStart -ne -1) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
  }
  else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
  }
}
# This key handler shows the entire or filtered history using Out-GridView. The
# typed text is used as the substring pattern for filtering. A selected command
# is inserted to the command line without invoking. Multiple command selection
# is supported, e.g. selected by Ctrl + Click.
Set-PSReadLineKeyHandler -Key F7 `
  -BriefDescription History `
  -LongDescription 'Show command history' `
  -ScriptBlock {
  $pattern = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
  if ($pattern) {
    $pattern = [regex]::Escape($pattern)
  }

  $history = [System.Collections.ArrayList]@(
    $last = ''
    $lines = ''
    foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath)) {
      if ($line.EndsWith('`')) {
        $line = $line.Substring(0, $line.Length - 1)
        $lines = if ($lines) {
          "$lines`n$line"
        }
        else {
          $line
        }
        continue
      }

      if ($lines) {
        $line = "$lines`n$line"
        $lines = ''
      }

      if (($line -cne $last) -and (!$pattern -or ($line -match $pattern))) {
        $last = $line
        $line
      }
    }
  )
  $history.Reverse()

  $command = $history | Out-GridView -Title History -PassThru
  if ($command) {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
  }
}

## Colors

$ISETheme = @{
  Command                = $PSStyle.Foreground.FromRGB(0x0000FF)
  Comment                = $PSStyle.Foreground.FromRGB(0x006400)
  ContinuationPrompt     = $PSStyle.Foreground.FromRGB(0x0000FF)
  Default                = $PSStyle.Foreground.FromRGB(0x0000FF)
  Emphasis               = $PSStyle.Foreground.FromRGB(0x287BF0)
  Error                  = $PSStyle.Foreground.FromRGB(0xE50000)
  InlinePrediction       = $PSStyle.Foreground.FromRGB(0x93A1A1)
  Keyword                = $PSStyle.Foreground.FromRGB(0x00008b)
  ListPrediction         = $PSStyle.Foreground.FromRGB(0x06DE00)
  Member                 = $PSStyle.Foreground.FromRGB(0x000000)
  Number                 = $PSStyle.Foreground.FromRGB(0x800080)
  Operator               = $PSStyle.Foreground.FromRGB(0x757575)
  Parameter              = $PSStyle.Foreground.FromRGB(0x000080)
  String                 = $PSStyle.Foreground.FromRGB(0x8b0000)
  Type                   = $PSStyle.Foreground.FromRGB(0x008080)
  Variable               = $PSStyle.Foreground.FromRGB(0xff4500)
  ListPredictionSelected = $PSStyle.Background.FromRGB(0x93A1A1)
  Selection              = $PSStyle.Background.FromRGB(0x00BFFF)
}

Set-PSReadLineOption -Colors $ISETheme


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
foreach ($i in @(
    “$HOME\src\winbin”, “$HOME\src\binexe”, “$HOME\bin", "$HOME\bin\sqlplus", 
    "$HOME\bin\oraclesqltools", "$ENV:ProgramFiles\Python3109", "$ENV:ProgramFiles\nodejs",
    (Get-ChildItem  "$ENV:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.*\LocalCache\local-packages\Python311\Scripts" -ErrorAction SilentlyContinue).FullName
  )) {  
  if (Test-Path -Path $i -PathType "Container" -ErrorAction SilentlyContinue) {
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

