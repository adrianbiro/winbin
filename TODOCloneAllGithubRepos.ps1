param([string] $MYTOKEN)
$MYTOKEN = ""
$name = "adrianbiro"
$page = 1
while ($True) {

    (curl -s -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $MYTOKEN" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/users/$name/repos?per_page=100&page=$page" | ConvertFrom-Json
    ).ssh_url | ForEach-Object { 
        if (($_ | Measure-Object).Count -eq 0 ) { break } 
        #git@github.com:adrianbiro/zotero-deb.git
        $dirname = $_ -replace ".*\/", "" -replace "\.git", ""
        #$ git clone --mirror original-repo.git /path/cloned-directory/.git          # (1)
        #$ cd /path/cloned-directory
        #$ git config --bool core.bare false                                         # (2)
        #$ git checkout anybranch
    }#git clone $_}
    $page++
}
#https://archive.kernel.org/oldwiki/git.wiki.kernel.org/index.php/Git_FAQ.html#How_do_I_clone_a_repository_with_all_remotely_tracked_branches.3F
# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-the-authenticated-user
# https://docs.github.com/en/rest/gists/gists?apiVersion=2022-11-28
# https://stackoverflow.com/questions/12766174/how-to-execute-a-powershell-function-several-times-in-parallel#12768438