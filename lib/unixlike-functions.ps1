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

function jless {
    <#
    .SYNOPSIS
        jless is pager for json.
    .DESCRIPTION  
        Pager for json. Input can be from pipeline or as file.
        PS C:\> 1..500 | ConvertTo-Json | jless.ps1
    .NOTES
        Bash version:
            alias jless="jq '.' -C | less -R"
#>
    param([string] $file)
    if ($file) {
        $jsonstring = Get-Content $file
    }
    else {
        $jsonstring = $input
    }
    $jsonstring | jq '.' -C | less -R #more  #jq is more versatile than pure pwsh out-host -paging 
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
    Param([System.IO.FileInfo] $Path)
    return [System.IO.File]::ReadAllText((Get-ChildItem -Path $Path).FullName)
}

function gomih {
    go mod init ((Get-Location).Path -replace ".*\\", "")
}

function type-sh-like {
    Param([string] $command)
    (Get-Command $command).ScriptBlock
}
  
function uname-a {
    Get-CimInstance Win32_OperatingSystem | Select-Object 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture' | Format-Table
}

function python3-utf8 { 
    Param(
        [string]$Script,
        [switch]$c
    )
    if ($c) {
        # python3-utf8 -c 'print(42)'
        python3 -X utf8 -c $Script 
    }
    else {
        # python3-utf8 foo.py
        python3 -X utf8 $Script 
    }
}

function lst {
    <#
    .SYNOPSIS
        ls -t
    .DESCRIPTION  
        Get the last modified item in the current directory.    
#>
    param([Int64] $num = 1)
(Get-ChildItem | Sort-Object -Property "LastWriteTime" -Descending | Select-Object -First $num).Name
    
}

function lslwcl {
    # like ins shell 
    # $ ls -l | wc -l
    #(ls | Measure-Object -Line).Lines
    (Get-ChildItem).Count
}

function head {
    <#
    .SYNOPSIS
        Head.
    .NOTES
        Show last 10 lines.  
#>
    param(
        [Alias("p")]
        [string]$path,
        [Alias("n")]
        [int] $number = 10
    )
    if ($path) {
        if (!(Test-Path -Path $path -PathType Leaf)) {
            return "$path does not exist."
        }
        Get-Content $path -Head $number 
    }
    else {
        $Input | Select-Object -First $number
    }
}

function tail {
    <#
    .SYNOPSIS
        Tail.
    .NOTES
        Show last 10 lines.  
#>

    param(
        [Alias("p")]
        [string]$path,
        [Alias("n")]
        [int] $number = 10
    )
    if ($path) {
        if (!(Test-Path -Path $path -PathType Leaf)) {
            "$path does not exist."
            exit
        }
        Get-Content $path -Tail $number 
    }
    else {
        $Input | Select-Object -Last $number
    }
}
function rmf {
    param([string] $path)
    Remove-Item -Recurse -Force -Path $path
}

function wc {
    $Input | Measure-Object -Line -Word -Character
}

function cdf {
    Set-Location -Path (Join-Path -Path $HOME -ChildPath "src/winbin")
}

    
function o {
    bat --pager less 
}
    
