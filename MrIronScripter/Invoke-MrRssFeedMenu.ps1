#Requires -Version 3.0
function Invoke-MrRssFeedMenu {

<#
.SYNOPSIS
    Retrieves information from the specified RSS feed and displays it in a selectable menu.
 
.DESCRIPTION
    Invoke-MrRssFeedMenu is an advanced function that retrieves information from the specified RSS feed, displays it in
    a selectable menu and then prompts the user to return the information about the selected item in a browser or as text.
 
.PARAMETER Uri
    Specifies the Uniform Resource Identifier (URI) of the RSS feed to which the web request is sent. This parameter supports 
    HTTP, HTTPS, FTP, and FILE values. The default is the PowerShell.org RSS feed.
 
.EXAMPLE
     Invoke-MrRssFeedMenu

.EXAMPLE
     Invoke-MrRssFeedMenu -Uri http://mikefrobbins.com/feed/
 
.INPUTS
    None
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Uri = 'https://powershell.org/feed/'
    )

    $Results = Invoke-RestMethod -Uri $Uri 

    $MenuItems = for ($i = 1; $i -le $Results.Count; $i++) {
        [pscustomobject]@{
            Number = $i
            Title = $Results[$i-1].title
            PublicationDate = ([datetime]$Results[$i-1].pubDate).ToShortDateString()
            Author = $Results[$i-1].creator.InnerText
        }
    }

$PostMenu = @"
    $($MenuItems | Out-String)
    Enter the number of the article to view
"@

    do {
        Clear-Host
        [int]$Post = Read-Host -Prompt $PostMenu   
    }
    while (
        $Post -notin 1..$Results.Count
    )

    Clear-Host

$OutputMenu = @"
Number DisplayOption
------ ----------------
     1 Default Browser
     2 Text
     3 Quit

Enter the number to display the article in the desired option
"@

    Clear-Host

    do {
        [int]$OutputType = Read-Host -Prompt $OutputMenu
    }
    while (
        $OutputType -notin 1..3
    )

    switch ($OutputType) {
        1 {
            Start-Process -FilePath ($Results[$Post-1]).link
            Clear-Host
            break
          }
        2 {
            Clear-Host
            ($Results[$Post-1]).InnerText.ToString() -replace '\t.*|\n|<[^>]*>|/\s\s+/g|^\s+|\s+$'
            break
          }
        3 {
            break
          }
    }

}