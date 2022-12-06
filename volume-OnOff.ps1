<#
    .SYNOPSIS
        Turn volume On/off.
    
    .DESCRIPTION  
        
    .NOTES
        Immediately mutes/unmutes the audio output.  
    .LINK
        https://github.com/adrianbiro/winbin
    
#>
(new-object -com wscript.shell).SendKeys([char]173)