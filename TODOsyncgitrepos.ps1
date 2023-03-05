$oldPath = $PWD
foreach($i in (Get-ChildItem -Path (Join-Path -Path $HOME -ChildPath "gits"))){
    Set-Location -Path $i.FullName
    git pull --all
}