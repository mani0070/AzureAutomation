<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script sets up the basic framework for azure virtual machine provision.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : VMProvisionActions.ps1
        Created By : Manimaran Chandrasekaran
        Date Coded : 11/23/2014 07:51:20
     .LINK
        https://azureautomation.wordpress.com/
#>


Function CheckVMStatus
 {
    <#
        .SYNOPSIS  
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : CheckVMStatus
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 07:46:28
        .LINK
            https://azureautomation.wordpress.com/
    #>
 [CmdletBinding()]
 Param
     (
    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
	[string]$vmname,
	[parameter(Mandatory=$true,ValueFromPipeline=$true)]
	[string]$vmservice
     )
 Begin
 {
     }
 Process
 {
 $CheckVMStatus = $true
	$VMStatus = Get-AzureVM	
	if ($VMStatus.InstanceName -eq $vmname)
	{
		write-Host "VM Check passed and Virtual Machine is available "
		Write-Host $VMStatus.Status 
		if ($VMStatus.Status -eq "ReadyRole")
		{
			$CheckVMStatus = $false
		}
		elseif ($VMStatus.OperationStatus -eq "StoppedDeallocated")
		{
			$CheckVMStatus = $true
		}
	}
	else
	{
	Write-host $VMStatus.OperationStatus
	}
	return $CheckVMStatus
     }
 End
 {
     }
 }


Function ProvisionVM

 {
    <#
        .SYNOPSIS
        .DESCRIPTION :  Function used to provision the first VM in the Microsft Azure Cloud 
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : ProvisionVM
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 07:48:32
        .LINK
            https://azureautomation.wordpress.com/
    #>
 [CmdletBinding()]
 Param
     (
     		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$vmname,
			[parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$vmservice ,
			[parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$subnetname,
			[parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$vNetName	,
			[parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$un,
			[parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$pwd,
            [parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$vmlocation,
            [parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$vmSize
     )
 Begin
 {
     }
 Process
 {
 	write-host $vmname  "," $vmservice  "," $subnetname ","  $vNetName
	
	Write-Host "Get the Windows Azure Image with Latest Build"
	$Image = Get-AzureVMImage | Select Imagename , label | Where-Object {$_.Label -like 'Windows Server 2012 R2 Datacenter*'} `
	| select -first 1
	$iname = $Image.Imagename
	Write-Host "This is the Windows Image we will be using to provision the VM" + $iname
	
	Write-Host "Check if the Azure Cloud service exists"
	$srvstatus = Get-AzureService -ServiceName $vmservice
	if ($srvstatus)
		{
			Write-Host $vmservice  "   Azure Cloud Service already exists"
		}
		else
		{
			New-AzureService -ServiceName $vmservice -Location $vmlocation
		}
	$vmexists = CheckVMStatus $vmname.ToString()	$vmservice.ToString()
	if ($vmexists)
	{ 
	#Check if VM already exists
	$vm = New-AzureVMConfig -Name $vmname -InstanceSize $vmSize -Image $Image.ImageName
	$vm | Add-AzureProvisioningConfig -Windows -AdminUserName $un -Password $pwd
	$vm | Add-AzureEndpoint -Name "http" -Protocol tcp -LocalPort 80 -PublicPort 80 
	$vm | Set-AzureSubnet -SubnetNames $subnetName
	$vm | New-AzureVM -ServiceName $vmservice	-VnetName $vNetName -WaitForBoot 
	Write-Host $vm
	}
	else
	{
		write-Host "VM Exists, Cannot be recreated with same name, Please change the parameters"
	}
		
     }
 End
 {
     }
 }

Function  CleanUp
 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : CleanUp
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 07:50:08
        .LINK
            https://azureautomation.wordpress.com/
    #>
 [CmdletBinding()]
 Param
     (
     $vmname, 
     $vmservice
     )
 Begin
 {
     }
 Process
 {
 Write-Host  $vmname  "------"  $vmservice
	$result = CheckVMStatus $vmname $vmservice
	write-Host $result
	if ($result)
	{	
		write-Host "VM Deallocated"
		$removestatus = Remove-AzureVM -ServiceName $vmservice -Name $vmname -DeleteVHD 
		Write-Host $removestatus.OperationStatus
															  

	}
	else
	{
		$Status = Stop-AzureVM -ServiceName $vmservice -Name $vmname
			If ($Status.OperationStatus -eq "Succeeded")
			{
				Write-host "Shutdown Completed successfully"
				$removestatus = Remove-AzureVM -ServiceName $vmservice -Name $vmname -DeleteVHD 
				
			}
			elseIf ($Status.OperationStatus -eq "StoppedDeallocated")
			{
				Write-Host "VM Already stopped and deallocated"
			}
			else
			{
				Write-Host $Status.OperationStatus
			}	
	}
     }
 End
 {
     }
 }


Function NewVMsInDomain
 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : NewVMsInDomain
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 10:26:16
        .LINK
            https://code.google.com/p/mod-posh/wiki/VMProvisionActions#
    #>
 [CmdletBinding()]
 Param
    (
     	[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$vmname,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$vmservice ,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$subnetname,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$vNetName	,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[Int] $noOfVms,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$un,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$pwd,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$vmlocation,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$azureDomain,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$fullDomainName,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$ipaddressDns,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$vmSize

     )
 Begin
 {
     }
 Process
 {
  	$myDNS = New-AzureDNS -Name $azureDomain -IPAddress $ipaddressDns

	# OS Image to Use
	$Image = Get-AzureVMImage | Select Imagename , label |`
	Where-Object {$_.Label -like 'Windows Server 2012 R2 Datacenter*'}	| select -first 1
	$iname = $Image.Imagename
	Write-Host $iname
	$srvstatus = Get-AzureService -ServiceName $vmservice
	if ($srvstatus)
	{
		Write-Host $vmservice "Service already exists"
	}
	else
	{
		New-AzureService -ServiceName $vmservice -Location $vmlocation
	}
	for ($i=1 ; $i -le $noOfVms; $i++)
	{
		#VM Name Formation
		$vName = $vmname + '0' + $i
		$vmexists = CheckVMStatus $vName.ToString()	$vmservice.ToString()
		if ($vmexists)
		{ 
			# VM Creation  and adding it do the domain
			Write-Host $vName  "started provision"
			$VMC = New-AzureVMConfig -name $vName -InstanceSize $vmSize -ImageName $Image.Imagename 
			$VMC | Add-AzureProvisioningConfig -AdminUserName $un -WindowsDomain -Password $pwd -Domain $azureDomain `
			-DomainPassword $pwd -DomainUserName $un -JoinDomain $fullDomainName 
			$VMC | Set-AzureSubnet -SubnetNames $subnetname 
			New-AzureVM -ServiceName $vmservice -VMs $VMC -DnsSettings $myDNS -VNetName $vNetName -WaitForBoot  
			Write-Host $vName  "Completed provision"  
		}
		
	}
     }
 End
 {
     }
 }


Function EnableADRoles
 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : EnableADRoles
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 10:34:22
        .LINK
            https://code.google.com/p/mod-posh/wiki/VMProvisionActions#
    #>
 [CmdletBinding()]
 Param
     (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$vmname,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$vmservice,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$un,
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$pwd,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$azureDomain,
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$fullDomainName

     )
 Begin
 {
     }
 Process
 {
  	$SecurePassword = $pwd | ConvertTo-SecureString -AsPlainText -Force
	$credential = new-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $un , $SecurePassword
 	
	# Get the RemotePS/WinRM Uri to connect to	 the virtual machines
	$uri = Get-AzureWinRMUri -ServiceName $vmservice -Name $VMName 
 	# Generate certs 
	InstallWindowsRemoteCertificate $VMName $vmservice 
    Write-Host $azureDomain "Before Invoke command" $fullDomainName
 	# Use native PowerShell Cmdlet to execute a script block on the remote virtual machines					  
	Invoke-Command -ConnectionUri $uri.ToString() -Credential $credential -ScriptBlock {
         param(
        $azureDomain,
        $fullDomainName
        )
		#Generate the log files for future reference
		Write-Host "Generate the log files for future reference"
		$logLabel = $((get-date).ToString("yyyyMMddHHmmss"))
		$logPath = "c:\webservervm_webserver_install_log_$logLabel.txt"
		
		#Enable required windows features
		Write-Host "Enable required windows features"
		Import-Module -Name ServerManager
		Install-WindowsFeature -Name AD-Domain-Services  -IncludeManagementTools -LogPath $logPath
		$SecurePas = $pwd | ConvertTo-SecureString -AsPlainText -Force

		#Install and Configure active directiory and DNS
		Write-Host $pwd  $azureDomain "Install and Configure active directiory and DNS" $fullDomainName
		
        Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath 'C:\Windows\NTDS' -DomainMode 'Win2012' `
		-DomainName $fullDomainName -DomainNetbiosName $azureDomain -ForestMode 'Win2012' -InstallDns:$true -LogPath 'C:\Windows\NTDS' `
		-NoRebootOnCompletion:$true -SysvolPath 'C:\Windows\SYSVOL' -Force:$true  -SafeModeAdministratorPassword $SecurePas
		
        #Reboot the server to finish the active directory installation and configuration
		Write-Host "Reboot the server to finish the active directory installation and configuration"
		shutdown /r		
	} -argumentlist $azureDomain,$fullDomainName
     }
 End
 {
     }
 }

Function InstallWindowsRemoteCertificate
 {
    <#
        .SYNOPSIS
        .DESCRIPTION
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : InstallWindowsRemoteCertificate
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 11/23/2014 10:38:11
        .LINK
            https://code.google.com/p/mod-posh/wiki/VMProvisionActions#
    #>
 [CmdletBinding()]
 Param
     (
    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
	[string]$vmname,
	[parameter(Mandatory=$true,ValueFromPipeline=$true)]
	[string]$vmservice 
     )
 Begin
 {
     }
 Process
 {
   $winRMCert = (Get-AzureVM -ServiceName $vmservice -Name $vmname | select -ExpandProperty vm).DefaultWinRMCertificateThumbprint
 	$AzureX509cert = Get-AzureCertificate -ServiceName $vmservice -Thumbprint $winRMCert -ThumbprintAlgorithm sha1
 
    $certTempFile = [IO.Path]::GetTempFileName()
    $AzureX509cert.Data | Out-File $certTempFile
 
    # Target The Cert That Needs To Be Imported
    $CertToImport = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certTempFile
 
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", "LocalMachine"
    $store.Certificates.Count
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $store.Add($CertToImport)
    $store.Close()
 
    Remove-Item $certTempFile
     }
 End
 {
     }
 }