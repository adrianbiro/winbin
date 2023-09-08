$location = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Edge\User Data\Profile 1"

Get-ChildItem $location -Recurse |`
    Where-Object { $_.Name -match "cooki" } |`
    ForEach-Object  { $_.FullName }