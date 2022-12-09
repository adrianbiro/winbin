Get-ChildItem *.py -Recurse 
    | ForEach-Object {
        $content = Get-Content -Path $_
        Set-Content 
            -Path $_.Fullname 
            -Value $content 
            -Encoding UTF8 
            -PassThru 
            -Force
}