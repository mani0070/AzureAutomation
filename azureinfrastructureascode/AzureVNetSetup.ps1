<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script sets up the basic framework for all the virtual network configuration in azure cloud service.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : AzureVNetSetup.ps1
        Created By : Manimaran Chandrasekaran
        Date Coded : 11/23/2014 07:51:20

    .LINK
        https://azureautomation.wordpress.com/
#>
function New-AzureVNetConfiguration 

{
	[CmdletBinding()]
	param 
	(
	[string]$newDnsServerName = 'DiLabs.edu',
	[string]$newDnsServerIP = '172.16.0.4',
	[string]$newVNetName = 'DILabsVNET',
	[string]$newVNetLocation = 'West Europe',
	[string]$newVNetAddressRange = '172.16.0.0/12',
	[string]$newSubnetName = 'Subnet-1',
	[string]$newSubnetAddressRange = '172.16.0.0/15',
	[string]$configFile = "C:\AzureVNetConfig.XML"
	)

	begin
	{

    Write-Host "Deleting $configFile if it exists"
    Del $configFile -ErrorAction:SilentlyContinue
	 
	}

	process 
	{

	        Write-Host "Creating Empty template for Azure Virtual Network"
        $newVNetConfig = [xml] '
        <NetworkConfiguration xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration">
          <VirtualNetworkConfiguration>
            <Dns>
              <DnsServers>
                <DnsServer name="" IPAddress="" />
              </DnsServers>
            </Dns>
            <VirtualNetworkSites>
              <VirtualNetworkSite name="" Location="">
                <AddressSpace>
                  <AddressPrefix></AddressPrefix>
                </AddressSpace>
                <Subnets>
                  <Subnet name="">
                    <AddressPrefix></AddressPrefix>
                  </Subnet>
                </Subnets>
                <DnsServersRef>
                  <DnsServerRef name="" />
                </DnsServersRef>
              </VirtualNetworkSite>
            </VirtualNetworkSites>
          </VirtualNetworkConfiguration>
        </NetworkConfiguration>
        '

        Write-Host "Add VNet and DNS attribute values to XML template"
        $vmnetattrib = $newVNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite
        $vmnetattrib.SetAttribute('name', $newVNetName)
        $vmnetattrib.SetAttribute('Location', $newVNetLocation)
        $vmnetattrib.AddressSpace.AddressPrefix = $newVNetAddressRange
        $vmnetattrib.Subnets.Subnet.SetAttribute('name', $NewSubNetName)
        $vmnetattrib.Subnets.Subnet.AddressPrefix = $newSubnetAddressRange
        $vmnetattrib.DnsServersRef.DnsServerRef.SetAttribute('name', $newDnsServerName)
       
	    $Dnsattrib = $newVNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.Dns.DnsServers.DnsServer
        $Dnsattrib.SetAttribute('name', $newDnsServerName)
        $Dnsattrib.SetAttribute('IPAddress', $newDnsServerIP)



        Write-Host "Get Current Cloud Azure VNet configuration from Azure subscription"
        $CurrentCloudVNetConfig = [xml] (Get-AzureVnetConfig).XMLConfiguration

        Write-Host "Identify the Current DNS servers into new VNet XML configuration"
        $CurrentDnsServers = $CurrentCloudVNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.Dns.DnsServers
        if ($CurrentDnsServers.HasChildNodes) {
           ForEach ($CurrentDnsServer in $CurrentDnsServers.ChildNodes) { 
                if ($CurrentDnsServer.name -ne $newDnsServerName) {
                    $importedDnsServer = $newVNetConfig.ImportNode($CurrentDnsServer,$True)
                    $newVNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.Dns.DnsServers.AppendChild($importedDnsServer) | Out-Null
                }
            }
        }

        Write-Host "Merge existing VNets into new VNet XML configuration"
        $CurrentVNets = $CurrentCloudVNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites
        if ($CurrentVNets.HasChildNodes) {
            ForEach ($CurrentVNet in $CurrentVNets.ChildNodes) { 
                if ($CurrentVNet.name -ne $newVNetName) {
                    $importedVNet = $newVNetConfig.ImportNode($CurrentVNet,$True)
                    $newVNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.AppendChild($importedVNet) | Out-Null
                }
            }
        }

        Write-Host "Merge existing Local Networks into new VNet XML configuration"
        $CurrentLocalNets = $CurrentCloudVNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.LocalNetworkSites
        if ($CurrentLocalNets.HasChildNodes) {
            $dnsNode = $newVNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.Dns
            $importedLocalNets = $newVNetConfig.ImportNode($CurrentLocalNets,$True)
            $newVnetConfig.NetworkConfiguration.VirtualNetworkConfiguration.InsertAfter($importedLocalNets,$dnsNode) | Out-Null
        }

        Write-Host "Saving new VNet XML configuration to $configFile"
        $newVNetConfig.Save($configFile)

        Write-Host "Provisioning new VNet configuration from $configFile"
        Set-AzureVNetConfig -ConfigurationPath $configFile



	}


}
