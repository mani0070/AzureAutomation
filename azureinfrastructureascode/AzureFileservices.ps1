<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script sets up the basic framework for all the Azure file and network share services.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : AzureFileservices.ps1
        Created By : Manimaran Chandrasekaran
        Date Coded : 11/23/2014 07:51:20
    .LINK
        https://azureautomation.wordpress.com/
#>
# create a context for account and key


Function  Uploadfiles
 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : Uploadfiles
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 07:55:12
        .LINK
            https://azureautomation.wordpress.com/
    #>
 [CmdletBinding()]
 Param
     (
       [string]$rootfolder = "C:\",
       [string]$basefolder = "publishsite",
       [String]$NWSharefolder = "DiDemoShare",
       [string]$azureStorageaccount = "azurenetworkfileshares",
       [string]$storageAccountKey = "GxAgGBZuxwRUp+JF6DR7QNO/YAoIrckSgLv0jxOi",
       [string]$azurenetworkshare = "stagearea"
     )
 Begin
  {
    $Storagectx=New-AzureStorageContext $azureStorageaccount $storageAccountKey

    $fileShareCtx = Get-AzureStorageShare -Name $azurenetworkshare -Context $Storagectx 

    if (!$fileShareCtx)
    {
    # create a new share if does not exists
    $fileShareCtx = New-AzureStorageShare $azurenetworkshare -Context $Storagectx

    }

     }
 Process
 {

    $Currentfolder = $rootfolder + $basefolder
    If ((Test-Path $Currentfolder))
    {
    # Get all the files including subdirectories
    $files = ls -Path $Currentfolder -File -Recurse
    # Get all the folders/subdfolders 
    $allsubdir = ls -Path $Currentfolder -Directory -Recurse


    # upload a local files/folders to the directory just created in azure file share
    if ($allsubdir.Count -gt 0)
        {
            if (!(Get-AzureStorageFile -Share $fileShareCtx -Path DiDemoShare -Verbose | `
                where {$_.Name -eq $basefolder}))
            {
            New-AzureStorageDirectory -Share $fileShareCtx -Path  DiDemoShare/$basefolder
            }
            Write-Host $allsubdir

                foreach($subdir in $allsubdir)
                {
                    try
                    {
                    $tmpsubdir = '/' + $subdir
                    $tempsubstr1 = Split-Path -Path $subdir.FullName.ToString().`
                        Substring($Currentfolder.Length) -NoQualifier

                    $tempsubstr = $NWSharefolder + $tempsubstr1.Replace("\","/")
                    $rootdirpath = $tempsubstr.Substring(0,$tempsubstr.ToString().LastIndexOf("/"))
                    Write-Host $tempsubstr $rootdirpath
                    if (!(Get-AzureStorageFile -Share $fileShareCtx -Path $rootdirpath -Verbose `
                         | where {$_.Name -eq $subdir}))
                    {
                        New-AzureStorageDirectory -Share $fileShareCtx -Path  $tempsubstr
                    }
                    }
                catch 
                {
                    Write-Error ("This is error message" + $_.Tostring())
                    $warningMessage = "Unable to create directory " + $file.FullName
                    Write-Warning -Message $warningMessage
                 }
             }
          
            
            foreach ($file in $Files) 
            
                {
                try
                {
                $tempstr = Split-Path -Path $file.FullName.ToString().Substring($Currentfolder.Length) -NoQualifier
                $Sharepath = $NWSharefolder + $tempstr.Replace("\","/")
                Set-AzureStorageFileContent -Share $fileShareCtx -Source $file.FullName `
                    -Path $Sharepath -Force -Verbose 
                }

                catch 
                {
                    Write-Error ("This is error message" + $_.Tostring())
                    $warningMessage = "Unable to upload file " + $file.FullName
                    Write-Warning -Message $warningMessage
                }
        
        }
    }
    }
    else
    {
    Write-Warning ("No Local folder exists")
    }
     }
 End
 {
     }
 }
