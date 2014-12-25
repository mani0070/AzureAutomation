# Generate the relative path, this makes it easy when you download
$vmProvisonScript =  $PSScriptRoot + "\azureinfrastructureascode\VMProvisionActions.ps1"
$StroageBlobActions =  $PSScriptRoot + "\azureinfrastructureascode\StroageAccountBlobActions.ps1"
$MapAzureFileShare =  $PSScriptRoot + "\azureinfrastructureascode\MapAzureFileShare.ps1"
$AzureVNetSetup =  $PSScriptRoot + "\azureinfrastructureascode\AzureVNetSetup.ps1"
$AzureFileservices =  $PSScriptRoot + "\azureinfrastructureascode\AzureFileservices.ps1"

# Load the scripts to access the functions
. $vmProvisonScript
. $StroageBlobActions
#. $MapAzureFileShare
. $AzureVNetSetup
. $AzureFileservices


# Time to started
$time = [Diagnostics.Stopwatch]::StartNew()
Write-Host "Time Started" (Get-Date).ToString()
#Check if the Azure Subscription and Storage account exists
$azuresub = Get-AzureSubscription | Select CurrentStorageAccountName , SubscriptionName  `
 | Where-Object {$_.SubscriptionName -like 'BizSpark'}
 
 Get-AzureStorageAccount | Select Location, StorageAccountName , Label | `
 Where-Object {$_.StorageAccountName -like $azuresub.CurrentStorageAccountName} 
Write-host $PSScriptRoot

#Setup the Network Configuration 
New-AzureVNetConfiguration 

write-host "Cloud Configuration and Provision Started @" [DateTime]::UtcNow
ProvisionVM	DiLabADVM DiLabVMSvc Subnet-1	DILabsVNET	DITestUser Test@didemo1 'West Europe' Small
write-host "AD Provision Completed @" (Get-Date).ToString()
Sleep 60

EnableADRoles DiLabADVM DiLabVMSvc DITestUser Test@didemo1 DiLabs DiLabs.edu
 write-host "AD Setup and Configuration Completed @" (Get-Date).ToString()

NewVMsInDomain	DiLabVMClient DiLabVMSvcClient Subnet-1 DILabsVNET 1  DITestUser Test@didemo1 'West Europe' DiLabs DiLabs.edu '172.16.0.4' 'Small'
 write-host "Client VMs Created @" (Get-Date).ToString()
 Sleep 60

write-host "Cloud Configuration and Provision completed @"  (Get-Date).ToString()
$time.Stop()
Write-Host "End to End completed in "  $time.Elapsed 

