<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script sets up the basic framework that I use for all my scripts.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : MapAzureFileShare.ps1
        Created By : Manimaran Chandrasekaran
        Date Coded : 11/23/2014 07:51:20

    .LINK
        https://azureautomation.wordpress.com/
#>
# Below simple lines of code is used to make the Azure file shares
cmdkey /add:azurenetworkfileshares.file.core.windows.net /user:azurenetworkfileshares /pass:GxAgGBZuxwRUp+JF6DR7QNO/YAoIrckSgLv0jxOiZpS85+wJDLtE8jY7TmEBQHcysXQwxir2++JX5gxsLpIFNw==

$key = "GxAgGBZuxwRUp+JF6DR7QNO/YAoIrckSgLv0jxOiZpS85"
$StorageAccName = "azurenetworkfileshares"
$AzureStorageShareName = "stagearea"
$cmdnetshare = "net use x: \\$StorageAccName.file.core.windows.net\$AzureStorageShareName /u:$StorageAccName $Key"
Invoke-Expression -Command $cmdnetshare

