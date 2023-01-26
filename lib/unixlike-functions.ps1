function zip { 
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { Test-Path -Path $_ -PathType "Any" },
            ErrorMessage = "Specify name of existiong file or directory."
        )]
        [string] $Path,
        [Parameter(Mandatory = $True)]
        [string] $DestinationPath #= $Path
    )
    Compress-Archive -Path $Path -DestinationPath $DestinationPath 
}

function unzip { 
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { (Test-Path -Path $_ -PathType "Any") -and ($_.EndsWith(".zip")) },
            ErrorMessage = "Specify name of existiong zip archive."
        )]
        [string] $Path,
        [Parameter(Mandatory = $True)]
        [string] $DestinationPath #= $Path
    )
    Expand-Archive -Path $Path -DestinationPath $DestinationPath 
}
