[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    $appName,

    [Parameter(Mandatory=$true)]
    $appRolesList
)

function global:CreateAudienceAppRoles
{
    param (
        $appName,
        $appRole        
    )
    $appName = "$appName"
    $appRole = "$appRole"  
    try 
    {
        if(($AppReg = Get-AzureADMSApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
        {
            $approles = $AppReg.AppRoles            
            foreach ($role in $appRoles.Value) {               
                if($role -eq $appRole)
                {
                    Write-Host -f Yellow "##[warning] '$($appRole)' already exists"
                    Write-Host ""
                    return
                } 
            }
            Write-Host "Creating app role '$($appRole)'..."
            Write-Host ""
            $description = "Giving permission to the app as '$($appRole)'"
            $newRole = CreateAppRolePS -Name $appRole -Description $description
            $appRoles.Add($newRole)

            Set-AzureADMSApplication -ObjectId $AppReg.Id -AppRoles $appRoles
            Write-Host -f Green "##[section] App role '$($appRole)' added successfully"
            Write-Host ""
        }
        else
        {
            Write-Host -f Yellow "##[warning] Application with name '$($DisplayName)' does not Exists"
            Write-Host ""
            return
        }
    }
    catch
    {
        $message = $_.Exception.message
        Write-Host  "##vso[task.LogIssue type=error;] $message"
        exit 1        
    }
}

function global:CreateAppRolePS
{
    param
    (
        $Name, 
        $Description
    )
    try 
    {       
        $Name = "$Name"
        $Description = "$Description"
        $appRole = New-Object Microsoft.Open.MSGraph.Model.AppRole
        $appRole.AllowedMemberTypes = New-Object System.Collections.Generic.List[string]        
        #$appRole.AllowedMemberTypes.Add("User")
        $appRole.AllowedMemberTypes.Add("Application")
        $appRole.DisplayName = $Name
        $appRole.Id = New-Guid
        $appRole.IsEnabled = $true
        $appRole.Description = $Description
        $appRole.Value = $Name;
        return $appRole
    }
    catch {
        $message = $_.Exception.message
        Write-Host  "##vso[task.LogIssue type=error;] $message"
        Write-Host ""
        exit 1
    }
}

& "$PSScriptRoot\ConnectToAzureAD.ps1"

function AppRolesProcess {
    $appName = "$appName"
    $appRolesList = "$appRolesList"
    $approles = $appRolesList.Split(",")

    # Connect-AzureAD automatically
    ConnectToAzureAD
          
    Write-Host "Creating app roles '$($approlesList)' for '$($appName)'..."
    Write-Host ""
    foreach ($item in $approles) {
        $item = $item.Trim()
            CreateAudienceAppRoles -appName $appName -appRole $item 
    }
}

AppRolesProcess