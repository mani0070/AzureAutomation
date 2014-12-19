<#
    .SYNOPSIS
        Template script
    .DESCRIPTION
        This script sets up the the Task scheduler for backup.
    .PARAMETER
    .EXAMPLE
    .NOTES
        ScriptName : CreateWindowsTaskScheduler.ps1
        Created By : Manimaran Chandrasekaran
        Date Coded : 12/19/2014 07:51:20

    .LINK
        https://www.devopspractice.com/
#>

#Define all the variables

$TName = "BackupDatabase"
$TDesc = "Run a Backup powershell script through a scheduled task"
$TCmd = "c:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
$TScript = "C:\Users\mani_000\Documents\AzureAutomation\azureinfrastructureascode\Schedulebackup.ps1"
$TArg = "-WindowStyle Hidden -NonInteractive -Executionpolicy unrestricted -file $TScript"
$TaskStartTime = [datetime]::Now.AddHours(1)

$svc = new-object -ComObject("Schedule.Service")
$svc.Connect()
$Folder = $svc.GetFolder("\")

$TaskDef = $svc.NewTask(0) 
$TaskDef.RegistrationInfo.Description = "$TDesc"
$TaskDef.Settings.Enabled = $true
$TaskDef.Settings.AllowDemandStart = $true
#Define triggers just one time in this case
$trgs = $TaskDef.Triggers
$trigger = $trgs.Create(1) 
$trigger.StartBoundary = $TaskStartTime.ToString("yyyy-MM-dd'T'HH:mm:ss")
$trigger.Enabled = $true

$Action = $TaskDef.Actions.Create(0)
$action.Path = "$TCmd"
$action.Arguments = "$TArg"

#Under the root folder reistration
$Folder.RegisterTaskDefinition("$TName",$TaskDef,6,"System",$null,5)