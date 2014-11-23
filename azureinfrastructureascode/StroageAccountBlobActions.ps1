<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script contains all the functions release to storage actions of blog in the storage account.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : StroageAccountBlobActions.ps1
        Created By : Manimaran Chandrasekaran
        Date Coded : 11/23/2014 07:51:20
    .LINK
        https://azureautomation.wordpress.com/
#> 
Function CreateStorageContainerinAzure
 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : CreateStorageContainerinAzure
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 07:58:48
        .LINK
            https://azureautomation.wordpress.com/
    #>
 [CmdletBinding()]
 Param
     (
     $CreateStorageContainer
     )
 Begin
 {
     }
 Process
 {
     if ($CreateStorageContainer)
    {
        $existingContainer = Get-AzureStorageContainer | 
            Where-Object { $_.Name -like $StorageContainer }

        if ($existingContainer)
        {
            $msg = "Azure Storage container '" + $StorageContainer + "' already exists."
        }
        else
        {
                $newContainer = New-AzureStorageContainer -Name $StorageContainer
                "Azure Storage container '" + $newContainer.Name + "' created."
        }
    }
     }
 End
 {
     }
 }

Function DownloadBlobStorage
 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : DownloadBlobStorage
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 07:59:12
        .LINK
            https://azureautomation.wordpress.com/
    #>
 [CmdletBinding()]
 Param
     (
    [string]$localContainerPath="C:\DemoSource\",
    [string]$SourceContainerName="stagearea41container"
     )
 Begin
 {
     }
 Process
{
# Following modifies the Write-Verbose behavior to turn the messages on globally for this session
$VerbosePreference = "Continue"

# Ensure the local path given exists. Create it if switch specified to do so.
if (-not (Test-Path $localContainerPath))
    {
     New-Item -Path $localContainerPath -ItemType Directory
    }

$localContainerPath = ""
if ($SourceContainerName -ne $null -and $SourceContainerName -ne "" )
{
    # Download blobs for the specified container.    
    $DestLocalPath = $localContainerPath + "\" + $SourceContainerName
    
    # Get a reference to the container.
    $container = Get-AzureStorageContainer -Name $SourceContainerName -ErrorAction SilentlyContinue
    if ($container -eq $null)
    {
        throw "Unable to Contact storage container '$SourceContainerName'."
    }

    # Copy blobs from storage container to local file path.
    $blobs = Get-AzureStorageBlob -Container $SourceContainerName
    foreach ($blob in $blobs)
    {
        $sourceBlob = $SourceContainerName + "\" + $blob.Name
        $destFilePath = $DestLocalPath + "\" + $blob.Name

        # Create a sub-directory using the container name.
        $destDirectory = [System.IO.Path]::GetDirectoryName($destFilePath)
        $destFilePath = $destDirectory + "\" + [System.IO.Path]::GetFileName($destFilePath)
        
        if (-not (Test-Path $destDirectory -PathType Container))
        {
            New-Item -Path $destDirectory -ItemType Directory -Force
        }
  
        # Copy blob from container to local path.
            Get-AzureStorageBlobContent `
                -Container $SourceContainerName -Blob $blob.Name -Destination $destFilePath -Force | `
                    Format-Table -Property Length,Name -AutoSize 
    }

}
else
{
    throw "Provide a valid storage container name using the 'SourceContainerName'"
}

 
     }
 End
 {
     }
 }

Function PushFilesToStorageContainer
 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : PushFilesToStorageContainer
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 08:57:06
        .LINK
            https://code.google.com/p/mod-posh/wiki/StroageAccountActions#
    #>
 [CmdletBinding()]
 Param
     (
    [string]$LocalPath = 'C:\customscripts',
    [string]$StorageContainer = "scripts"
     )
 Begin
 {
     }
 Process
 {
 
    $VerbosePreference = "Continue"

    # Ensure the local path given exists.
    if (-not (Test-Path $LocalPath -IsValid))
    {
    throw "Source path '$LocalPath' does not exist.  Specify an existing path."
    }

    $files = ls -Path $LocalPath -File -Recurse
    if ($files -ne $null -and $files.Count -gt 0)
    {
   
        $time = [DateTime]::UtcNow
        

    if ($Files.Count -gt 0)
    {
        foreach ($file in $Files) 
        {
            $blobFileName1 = Split-Path -Path $file.FullName -NoQualifier
            $blobFileName = $blobFileName1.Substring($blobFileName1.ToString().LastIndexOf("\")+1)
            try
            {
                Set-AzureStorageBlobContent -Container $StorageContainer `
                    -File $file.FullName -Blob $blobFileName `
                    -Force
            }
            catch
            {
                  Write-Error ("This is error message" + $_.Tostring())
                $warningMessage = "Unable to upload file " + $file.FullName
                Write-Warning -Message $warningMessage
              
            }
        }
    }
    else
    {
    Write-Warning ("No files to upload")
    }
    $duration = [DateTime]::UtcNow - $time
    "Uploaded " + $files.Count + " files to blob container '" + $StorageContainer + "'."
    "Total upload time: " + $duration.TotalMinutes + " minutes."
}

     }
 End
 {
     }
 }