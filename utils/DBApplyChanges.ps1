# Author Manimaran Chandrasekaran Version 1.0
# Configure the SQL server database based on the input parameters

#Below are the default values for setting up the SQL server 
#NOTE: Going forward these parameters will be generalized and function based approach.

# format of the script should be 001_dbname_Createdb.sql - for creating database 
# format of the scripts 002_dbname_description.sql

$sqlserverinstance = "localhost" # specify instance name if required
$CleanRebuilddb = 1
$Module ="Ver1.0"
$dbname = "diautomationdb"


Function IsDBExists
 {
    <#
        .SYNOPSIS
        .DESCRIPTION     : Check if the database exists on the specified sql server
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : 
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 01/26/2015 10:33:58
        .LINK
            https://github.com/mani0070    #>
 [CmdletBinding()]
 Param
     (
     [string]$sqlServer,
     [string]$DBName
     )
 Begin
 {
  $exists = $FALSE
     }
 Process
 {

	 try 
	 {

	  # we set this to null so that nothing is displayed
	  $null = [reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
	   
	  # Get reference to database instance
	  $server = new-object ("Microsoft.SqlServer.Management.Smo.Server") $sqlServer
	   
	  foreach($db in $server.databases)
	  {  
	   if ($db.name -eq $DBName) 
	   {
	    $exists = $TRUE
	   }
	  }
 	}
	 catch 
	 {
	  	Write-Error "Failed to connect to $sqlServer"
	 }
	 # Return
	 Write-Output $exists
     }
 End
 {
     }
 }

 Function UpdateChangeLog
 {
    <#
        .SYNOPSIS
        .DESCRIPTION     : Updated the log table on the specified database
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : 
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 01/26/2015 10:36:23
        .LINK
            https://github.com/mani0070    #>
 [CmdletBinding()]
 Param
     ($scriptnumber,
     [String]$currentusername,
     [String]$Module,
     [String]$file,
     [String]$dbname
     )
 Begin
 {
     }
 Process
 {
 Invoke-Sqlcmd –ServerInstance $sqlserverinstance –Database $dbname -Query "INSERT INTO [dbo].[dbchangelog]
           (change_set
           ,executedby
           ,Executetype
           ,description)
     		VALUES
           ($scriptnumber, '$currentusername','$Module' ,'$file' )"
     }
 End
 {
     }
 }

Function ApplyDBScripts
 {
    <#
        .SYNOPSIS
        .DESCRIPTION     : Check and apply the all the db changes or just apply the delta changes based on the parameters.
        .PARAMETER
        .EXAMPLE
        .NOTES
            FunctionName : 
            Created by   : Manimaran Chandrasekaran
            Date Coded   : 01/26/2015 10:38:18
        .LINK
            https://github.com/mani0070    #>
 [CmdletBinding()]
 Param
     ([String]$sqlserverinstance,
     [String] $Module,
     [String] $CleanRebuilddb
     )
 Begin
 {
     }
 Process
 {
 
 	try
	{

		$dbscriptloc = Split-Path -Path $PSScriptRoot -Parent 
		Get-ChildItem "$dbscriptloc\db"  –Recurse –File -Filter *.sql | `
		Foreach-Object{
		    $filename = Get-Item $_.FullName
			$file = $_
			Write-Host $filename 
			[Security.Principal.WindowsIdentity]::GetCurrent().Name | %{$data = $_.split("\"); $currentusername = $($data[1])}
			Write-Host "Current username script is running under :: $currentusername"
			
			$pos=$file.ToString().IndexOf("_")
			[int] $scriptnumber = $file.ToString().Substring(0, $pos)
			Write-Host "Scripts available in the $scriptnumber"
			if (($filename.ToString().Contains($dbname)) -and (($filename.ToString().Contains("createdb")))){
		    	$dbexists = IsDBExists  $sqlserverinstance $dbname
				if (!$dbexists)
				{
					Invoke-Sqlcmd –ServerInstance $sqlserverinstance -inputfile $filename
					Invoke-Sqlcmd –ServerInstance $sqlserverinstance –Database $dbname  –Query "CREATE TABLE dbchangelog 
					(
		            change_set INTEGER PRIMARY KEY,
		            start_dt      DateTime DEFAULT (GetDate()) NOT NULL,
		            complete_dt   DateTime DEFAULT (GetDate()) NOT NULL,
		            executedby    VARCHAR(100) DEFAULT (USER) NOT NULL,
		            Executetype     VARCHAR(100) DEFAULT (USER) NOT NULL,
		            description   VARCHAR(500) NOT NULL
					)"
				   UpdateChangeLog $scriptnumber $currentusername $Module $file $dbname
				   $tblscript = Invoke-Sqlcmd –ServerInstance $sqlserverinstance –Database $dbname -Query "SELECT MAX(change_set) FROM dbchangelog where Executetype = 'Main'"
					$scriptavailable = $tblscript[0]
					Write-Host "Scripts already applied in database :" $scriptavailable
				}
				else
				{
					$tblscript = Invoke-Sqlcmd –ServerInstance $sqlserverinstance –Database $dbname -Query "SELECT MAX(change_set) FROM dbchangelog where Executetype = 'Main'"
					$scriptavailable = $tblscript[0]
					Write-Host "Scripts already applied in database :" $scriptavailable
				}
			}
			
			elseif(($filename.ToString().Contains($dbname)) -and ($scriptnumber -gt 1)-and ($scriptnumber -gt $scriptavailable )){
		    	Invoke-Sqlcmd –ServerInstance $sqlserverinstance -inputfile $filename -Database $dbname
				UpdateChangeLog $scriptnumber $currentusername $Module $file $dbname
			}

			Write-Host Script execution compelted $filename
		}
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Host "Setting up SQL Server Script failed because of the error message :: $ErrorMessage"
	}
     }
 End
 {
     }
 }

 
 ApplyDBScripts $sqlserverinstance $Module $CleanRebuilddb