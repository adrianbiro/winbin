param([string] $file)
if($file) {
    $jsonstring = Get-Content $file
} else {
    $jsonstring = $input
}
# todo error user end
$jsonstring | jq -C '.' | out-host -paging