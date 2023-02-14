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

function getjsonschema {
    Param([Parameter(Mandatory = $True)]
        [ValidateScript(
            { Test-Path -Path $_ -PathType "Leaf" },
            ErrorMessage = "Not a json file." )]
        [string] $Path)
    jq -r 'path(..) | map(tostring) | join("/")' $Path
}

function mergejson {
    # merge 
    # echo '{"A": {"a": 1}}' '{"A": {"b": 2}}' '{"B": 3}' '{"B": 4}' --> {"A":{"a":1,"b":2},"B":4}
    $Input | jq --slurp 'reduce .[] as $item ({}; . * $item)'
}
function mergejsonduplicatekeys {
    # echo '{"A": {"a": 1}}' '{"A": {"b": 2}}' '{"B": 3}' '{"B": 4}' --> {"A":[{"a":1},{"b":2}],"B":[3,4]}
    $Input | jq -s 'map(to_entries) | flatten | group_by(.key) | map({(.[0].key):map(.value)}) | add'
}

function cat-fast {
    #for big files
    Param([string] $Path)
    return [System.IO.File]::ReadAllText((Get-ChildItem -Path $Path).FullName)
}