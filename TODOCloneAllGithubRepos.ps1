param([string] $MYTOKEN)
$MYTOKEN = ""
$name = "adrianbiro"  #orgname
$page = 1
$cntx = "users"  # orgs
(curl -H “Authorization: token $MYTOKEN” "https://api.github.com/$cntx/$name/repos?page=$page&per_page=100" | ConvertFrom-Json
).ssh_url | ForEach-Object {git clone $_}
# https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repositories-for-the-authenticated-user
# https://docs.github.com/en/rest/gists/gists?apiVersion=2022-11-28
# https://stackoverflow.com/questions/12766174/how-to-execute-a-powershell-function-several-times-in-parallel#12768438