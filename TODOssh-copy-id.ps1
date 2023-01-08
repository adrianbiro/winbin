function ssh-copy-id([string]$userAtMachine){   
    $publicKey = "$ENV:USERPROFILE" + "/.ssh/id_rsa.pub" #todo no hard code file and type
    if (!(Test-Path "$publicKey")){ #TODO leaf etc
        Write-Error "ERROR: failed to open ID file '$publicKey': No such file"            
    }
    else {
        & cat "$publicKey" | ssh $userAtMachine "umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys || exit 1"  #todo no umask but just chmod 600 
        # umask 077 will:  create directories with permission 700  create files with permission 600

    }
}
ssh-copy-id 
