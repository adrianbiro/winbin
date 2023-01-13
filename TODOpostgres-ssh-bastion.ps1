# ssh tunel
# TODO test in Param description
Param([string] $RdsDatabaseEndpoint,
    [string] $userAtBastionHost,  # name@ec2IP
    [string] $privateKye
)
$conectionString = "5432:{0}:5432" -f $RdsDatabaseEndpoint
ssh -i $privateKye -f -N -L $conectionString $userAtBastionHost -v