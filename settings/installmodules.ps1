$modules = @("PSReadLine") #, "PSFzf", "posh-git")

foreach ($mod in $modules)
{
    Install-Module -Name $mod -Repository PSGallery -Force
}

Update-Help -Verbose -Force -ErrorAction SilentlyContinue