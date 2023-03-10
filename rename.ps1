Param(
    [Parameter(ValueFromPipeline=$true, Mandatory = $True)]
    $Files,
    [Parameter(Mandatory = $True)]
    [string] $Old,
    [Parameter(Mandatory = $True)]
    [string] $New

)
$Files | ForEach-Object { Move-Item $_.Name ($_.Name -replace $Old, $New ) }
