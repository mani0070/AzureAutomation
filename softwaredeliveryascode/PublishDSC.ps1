# Below Script is mainly used for publishing the DSC configuration and applying them in Azure VM

Publish-AzureVMDscConfiguration `
    C:\Users\mani_000\OneDrive\AzureBootstrap\AzureScripts\BootStrapAzure\BootStrapAzure\DIDemoWebsite.ps1 `
    -ConfigurationArchivePath C:\DemoSource\DIDemoWebsite.ps1.zip -Verbose -Force

Publish-AzureVMDscConfiguration C:\DemoSource\DIDemoWebsite.ps1.zip -Force -Verbose

$vm = Get-AzureVM -Name "DiLabVMClient01" -ServiceName "DiLabVMSvcClient" -Verbose

Set-AzureVMCustomScriptExtension -ContainerName scripts -StorageAccountName `
    azurenetworkfileshares -FileName MapAzureFileShare.ps1 -Run MapAzureFileShare.ps1 -VM $vm | Update-AzureVM -Verbose

#Set-AzureVMCustomScriptExtension -FileUri `
    #https://azurenetworkfileshares.blob.core.windows.net/scripts/MapAzureFileShare.ps1 `
    #-Run MapAzureFileShare.ps1  -VM $vm | Update-AzureVM -Verbose

$vm = Set-AzureVMDSCExtension -VM $vm -ConfigurationArchive "DIDemoWebsite.ps1.zip" -ConfigurationName "DIDemoWebsite"  

$vm | Update-AzureVM -Verbose
