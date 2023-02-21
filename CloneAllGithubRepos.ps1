<#
    .SYNOPSIS
       Clone all user repos froom github
    
    .DESCRIPTION  
        
    .NOTES
        https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-the-authenticated-user
        https://archive.kernel.org/oldwiki/git.wiki.kernel.org/index.php/Git_FAQ.html#How_do_I_clone_a_repository_with_all_remotely_tracked_branches.3F
        https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
    .LINK
        https://github.com/adrianbiro/winbin
#>
param(
    [Parameter(Mandatory = $True)]
    [string] $MYTOKEN,
    [string ]$name = "adrianbiro",
    [string] $gitsdir = (Join-Path -Path $HOME -ChildPath "gits")
)
mkdir $gitsdir -ErrorAction "SilentlyContinue" | Out-Null
$oldpwd = $PWD
Set-Location -Path $gitsdir 

function gitstuff {
    Param([string] $gitrepo)
    Set-Location -Path $gitsdir
    $dirname = $gitrepo -replace ".*\/", "" -replace "\.git", ""
    git clone --mirror $gitrepo (Join-Path -Path $dirname -ChildPath ".git") && Set-Location -Path $dirname 
    git config --bool core.bare false && git checkout (git branch --show-current) | Out-Null 
}
$page = 1
while ($True) {
    $headers = @{"Accept"      = "application/vnd.github+json";
        "Authorization"        = "Bearer $MYTOKEN";
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    $uri = "https://api.github.com/users/$name/repos?per_page=100&page=$page"
    $obj = (Invoke-WebRequest -Headers $headers -Uri $uri).Content | ConvertFrom-Json
    $obj.ssh_url | ForEach-Object { 
        if (($_ | Measure-Object).Count -eq 0 ) { break } 
        gitstuff -gitrepo $_
    }
    $page++
}
Set-Location -Path $oldpwd | Out-Null

# https://docs.github.com/en/rest/gists/gists?apiVersion=2022-11-28
#TODO
# https://stackoverflow.com/questions/12766174/how-to-execute-a-powershell-function-several-times-in-parallel#12768438