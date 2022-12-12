param([string]$pkgName)
if(-not $pkgName) {
    Write-Host("Usage:`n`t{0} <package-name>" -f $MyInvocation.MyCommand.Name)
    exit 1  
}
$platforms = "windows/amd64", "linux/amd64"
New-Item -Path "." -Name "bin" -ItemType "directory" -ErrorAction SilentlyContinue | Out-Null
foreach($i in $platforms){
    Set-Variable -Name "GOOS" -Value $i.split("/")[0]
    Set-Variable -Name "GOARCH" -Value $i.split("/")[1]
    $oname = [io.path]::combine($PWD.Path, "bin", "$pkgname-$GOOS-$GOARCH")
    if($GOOS -eq "windows") {$oname += ".exe"}
    go build -o $oname $pkgName
    Clear-Variable -Name "GOOS", "GOARCH"
    if($LASTEXITCODE -ne 0) {
        Write-Warning -Message "An build error has occurred!"
        Exit 1
    }
}
