<#
    .SYNOPSIS
        word2pdf
    
    .DESCRIPTION  
        Convert docx to pdf.    
    .NOTES
        If it freezes run:
        ps WINWORD | kill
    .LINK
        https://github.com/adrianbiro/winbin
#>
Param( 
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "File does not exist" 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The Path argument must be a file. Folder paths are not allowed."
        }
        return $true
    })]
    [string]$File
)
$File = Resolve-Path $File
$Doc = (New-Object -comobject Word.Application).Documents.Open($File) 
$Doc.saveas([ref] (($File).replace(“docx”,”pdf”)), [ref] 17)
$Doc.close()