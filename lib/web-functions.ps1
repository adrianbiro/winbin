function my-public-ip { 
    Param([string]$IP = "json")
    Invoke-RestMethod -uri ('http://ipinfo.io/{0}' -f $IP) 
}
function ipfromec2url {
    Param(
        [Parameter(Mandatory = $True)]
        [string] $url
    )
    #ec2-3-73-150-210.eu-central-1.compute.amazonaws.com
    return ((($url -split '\.')[0] -replace "ec2-", "") -replace "-", ".")
}