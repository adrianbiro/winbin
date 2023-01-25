Param([string] $EndpointAdress,
    [string] $userAtHost,  # name@ec2IP
    [string] $privateKye
)
ssh -i $privateKye $userAtHost -L 22:127.0.0.1:22 -v
