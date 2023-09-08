<#
    .SYNOPSIS
        Check changes in git repos recursively.
    
    .DESCRIPTION  
        
    .NOTES
        Recursively search for changes in git repos from the root directory.
        If there is no default location for the git repos, it will run the setup 
        and prompt the user to confirm the correct location. 
        python3 $(Join-Path -Path $HOME -ChildPath "src\gitstat\gitstat.py")

    .LINK
        https://github.com/adrianbiro/gitstat
        https://github.com/adrianbiro/winbin
#>
$oldPath = $PWD.Path
function SetUpLocation () {
    $configFile = Join-Path -Path $HOME -ChildPath ".gitstat.xml"
    if ( -not (Test-Path $configFile)) {
        $str = "{0}{1}{2}" -f
                "If this isn't the root level of your git repos run program again from that location:`n`t", 
                $oldPath, "`nTo continue write yes. " 
        $Islocation = Read-Host $str
        if ($Islocation -match "yes") {
            New-Item $configFile -ItemType File | % {Set-Content $_.FullName "<Location>$oldPath</Location>"}
        }
    }
    return ([xml]$XmlDocument = Get-Content -Path $configFile).Location
}

$location = SetUpLocation
$OutputEncoding = [Console]::OutputEncoding  # nejde more
$owner = git config user.name | Out-String -NoNewline  #TODO  Adri├ín B├¡ro 
#$owner = $env:UserName #TODO add to xml


"{0}`nStatus overview of local git repositories from: {1}`nOwned by {2}.`n" -f 
    (Get-Date -Format "dd/MM/yyyy HH:mm:ss"), $location, $owner

Get-ChildItem -Directory -Recurse $location |
    % {
    if ((Get-ChildItem -Hidden $_.FullName).Name -contains ".git" ) {
        Set-Location $_.FullName
        if (git status -s) {
            $PWD.Path
            git status -sb
            [bool] $todo = 1
        }
   }
}
if (-not $todo) {"There is nothing to do."}  
Set-Location $oldPath