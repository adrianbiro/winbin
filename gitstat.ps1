#python3 $(Join-Path -Path $HOME -ChildPath "src\gitstat\gitstat.py")

$location = Join-Path -Path $HOME -ChildPath "src"  # TODO config 
#$owner = git config user.name | Out-String -NoNewline  #TODO  Adri├ín B├¡ro
$owner = $env:UserName
$oldPath = $PWD.Path

"{0}`nStatus overview of local git repositories from: {1}`nOwned by {2}.`n" -f 
    (Get-Date -Format "dd/MM/yyyy HH:mm:ss"), $location, $owner

Get-ChildItem -Directory -Recurse $location |
    % {
    if ((Get-ChildItem -Hidden $_.FullName).Name -contains ".git" ) {
        Set-Location $_.FullName
        if (git status -s) {
            git status -sb
            [bool] $todo = 1
        }
   }
}
if (-not $todo) {"There is nothing to do."}  
Set-Location $oldPath