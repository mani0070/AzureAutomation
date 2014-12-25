configuration DIDemoWebsite 
{ 
    Import-DscResource -Module xWebAdministration 
    Import-DscResource -Module xPSDesiredStateConfiguration
    WindowsFeature IIS  
    {  
        Ensure          = "Present"  
        Name            = "Web-Server"  
    }  
    WindowsFeature AspNet45  
    {  
        Ensure          = "Present"  
        Name            = "Web-Asp-Net45"  
    }   
    xWebsite DefaultSite   
    {  
        Ensure          = "Present"  
        Name            = "Default Web Site"  
        State           = "Stopped"  
        PhysicalPath    = "C:\inetpub\wwwroot"  
        DependsOn       = "[WindowsFeature]IIS"  
    }  
    File WebContent  
    {  
        Ensure          = "Present"  
        SourcePath      = "Z:\DiDemoShare"
        DestinationPath = "C:\inetpub\DIDemoWebsite" 
        Recurse         = $true  
        Type            = "Directory"  
        DependsOn       = "[WindowsFeature]AspNet45"  
    }   
    xWebsite DiBlogDemo   
    {  
        Ensure          = "Present"  
        Name            = "DIDemoWebsite" 
        State           = "Started"  
        PhysicalPath    = "C:\inetpub\DIDemoWebsite"  
        DependsOn       = "[File]WebContent"  
    }  
}