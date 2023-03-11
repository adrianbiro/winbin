# using namespace System.Management.Automation  # TODO
# function ssh-autocomplete {
#   ### ssh
#   #using namespace System.Management.Automation
#   Register-ArgumentCompleter -CommandName ssh, scp, sftp -Native -ScriptBlock {
#     param($wordToComplete, $commandAst, $cursorPosition)
#     $knownHosts = Get-Content ${Env:HOMEPATH}\.ssh\config `
#     | ForEach-Object { ([string]$_).Split(' ')[0] } `
#     | ForEach-Object { $_.Split(',') } `
#     | Sort-Object -Unique
#     # For now just assume it's a hostname.
#     $textToComplete = $wordToComplete
#     $generateCompletionText = {
#       param($x)
#       $x
#     }
#     if ($wordToComplete -match "^(?<user>[-\w/\\]+)@(?<host>[-.\w]+)$") {
#       $textToComplete = $Matches["host"]
#       $generateCompletionText = {
#         param($hostname)
#         $Matches["user"] + "@" + $hostname
#       }
#     }
#     $knownHosts `
#     | Where-Object { $_ -like "${textToComplete}*" } `
#     | ForEach-Object { [CompletionResult]::new((&$generateCompletionText($_)), $_, [CompletionResultType]::ParameterValue, $_) }
#   }
# }
function showSshHosts {
    Get-Content ${Env:HOMEPATH}\.ssh\config | 
    ForEach-Object { ([string]$_).Split(' ')[1] } | 
    ForEach-Object { $_.Split(',') } | 
    Sort-Object -Unique |
    Where-Object { $_ -ne "*" } |
    Format-Wide -Column 3
}

function sshTunel22 {
    Param([string] $EndpointAdress,
        [string] $userAtHost, # name@ec2IP
        [string] $privateKye
    )
    ssh -i $privateKye $userAtHost -L 22:127.0.0.1:22 -v
    #tunel mssql 
    #ssh user@urltoaws.com -L 0.0.0.0:1433:127.0.0.1:1433
}

function postgres-ssh-bastion {
    # ssh tunel
    # TODO test in Param description
    Param([string] $RdsDatabaseEndpoint,
        [string] $userAtBastionHost, # name@ec2IP
        [string] $privateKye
    )
    $conectionString = "5432:{0}:5432" -f $RdsDatabaseEndpoint
    ssh -i $privateKye -f -N -L $conectionString $userAtBastionHost -v
}

function ssh-copy-id {
    Param(
        #[Parameter(Mandatory = $True)]
        [string]$userAtMachine,
        [Parameter(Mandatory = $True)]
        [ValidateScript(
            { (Test-Path -Path $_ -PathType "Leaf") -and ($_ -match ".pub") },
            ErrorMessage = "Not a public key file." )]
        [System.IO.FileInfo] $publicKey
    )   
    & Get-Content $publicKey | ssh $userAtMachine "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys || exit 1"  
    # umask 077 will:  create directories with permission 700  create files with permission 600
}
