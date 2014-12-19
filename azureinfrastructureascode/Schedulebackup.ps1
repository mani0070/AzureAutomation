<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script sets up the basic framework that I use for all my scripts.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : ScheduleBackup.ps1
        Created By : Manimaran Chandrasekaran
        Date Coded : 12/19/2014 07:51:20

    .LINK
        https://www.devopspractice.com/
#>

$key = "GxAgGBZuxwRUp+JF6DR7QNO/YAoIrckSgLv0jxOiZpS85"
$StorageAccName = "azurenetworkfileshares"

# Below simple lines of code is used to make the Azure file shares
cmdkey /add:$StorageAccName.file.core.windows.net /user:$StorageAccName /pass:$key
$AzureStorageShareName = "stagearea"

$cmdnetshare = "net use x: \\$StorageAccName.file.core.windows.net\$AzureStorageShareName"
#Invoke-Expression -Command $cmdnetshare
$from = "C:\DemoSource"
$to = "C:\backups\"
$objSvc = Get-CimInstance -ComputerName $server -Query "SELECT Name, StartName, Status, State FROM Win32_Service WHERE StartName <> 'LocalSystem'" | ? { $_.StartName -notlike 'NT AUTHORITY*' -and $_.StartName -notlike 'NT SERVICE*' } | Select *
    if ($objSvc.Name -eq 'EventStoreService')
    {
        Write-Host "Service is installed on the destination server"
                
    }
    else
    {
        Write-Host "Service is not installed on the destination server"
    }
$timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#Create the backup directory if does not exists
New-Item -ItemType Directory -Path $to\logs
#Backup to the azure file shares
Robocopy $from $to /MT:20 > $to\logs\$timestamp.log


