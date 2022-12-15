param([string] $MYTOKEN)
$MYTOKEN = ""
$name = "adrianbiro"  #orgname
$page = 1
$cntx = "users"  # orgs
(curl -H “Authorization: token $MYTOKEN” "https://api.github.com/$cntx/$name/repos?page=$page&per_page=100" | ConvertFrom-Json
).ssh_url | ForEach-Object {git clone $_}