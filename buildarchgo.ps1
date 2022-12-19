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
    go build -ldflags "-s -w" -o $oname $pkgName  # "-H=windowsgui"
    Clear-Variable -Name "GOOS", "GOARCH"
    if($LASTEXITCODE -ne 0) {
        Write-Warning -Message "An build error has occurred!"
        Exit 1
    }
}
# go build flags test
# $fullexe = "path\to\full\go.exe"; (Get-ChildItem $fullexe).Length / 1MB
# 5.26123046875
# $fullexe = "path\with\flags\go.exe"; (Get-ChildItem $fullexe).Length / 1MB
# 3.65869140625
