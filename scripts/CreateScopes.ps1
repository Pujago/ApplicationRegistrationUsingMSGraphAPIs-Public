[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    $appName,

    [Parameter(Mandatory=$true)]
    $scopesList
)

function global:CreateScopes
{

    param (
        $appName,
        $scope
    )
    $appName = "$appName"
    $scope = "$scope"
    try 
    {
        if(($app = Get-AzureADMSApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
        {
            $scopes = New-Object System.Collections.Generic.List[Microsoft.Open.MsGraph.Model.PermissionScope]
            if($app.api.Oauth2PermissionScopes.count -ge 0)
            {
                $app.Api.Oauth2PermissionScopes | foreach-object { $scopes.Add($_) }
            }

            $ifScopeWithSameValueExist = $app.Api.Oauth2PermissionScopes | Select-Object Value | Where-Object {$_.Value -eq "$($scope)"}
            
            if ([string]::IsNullOrEmpty($ifScopeWithSameValueExist))
            {
                $scope = CreateScope -value "$($scope)"  `
                    -userConsentDisplayName ""  `
                    -userConsentDescription ""  `
                    -adminConsentDisplayName "$($scope)"  `
                    -adminConsentDescription "Role use to secure the api for T01"
                $scopes.Add($scope)
                $app.Api.Oauth2PermissionScopes = $scopes
                Set-AzureADMSApplication -ObjectId $app.Id -Api $app.Api
                Write-Host "scope '$($scope)' added"
            }
            else {
                Write-Host -f Yellow "##[warning] Scope with the value '$($scope)' already exists"
                return
            }                                   

        }
        else
        {
            Write-Host -f Yellow "##[warning] Application with name '$($audienceAppName)' does not Exists"
            Write-Host ""
            return
        }
    }
    catch
    {
        $message = $_.Exception.message
        Write-Host  "##vso[task.LogIssue type=error;] $message"
        Write-Host ""
        exit 1
        
    }
}

function global:CreateScope
{
    param
    (
        [string] $value,
        [string] $userConsentDisplayName,
        [string] $userConsentDescription,
        [string] $adminConsentDisplayName,
        [string] $adminConsentDescription
    )

    try 
    {
       
        $scope = New-Object Microsoft.Open.MsGraph.Model.PermissionScope
        $scope.Id = New-Guid
        $scope.Value = $value
        $scope.UserConsentDisplayName = $userConsentDisplayName
        $scope.UserConsentDescription = $userConsentDescription
        $scope.AdminConsentDisplayName = $adminConsentDisplayName
        $scope.AdminConsentDescription = $adminConsentDescription
        $scope.IsEnabled = $true
        $scope.Type = "User"
        return $scope
    }
    catch {
        $message = $_.Exception.message
        Write-Host  "##vso[task.LogIssue type=error;] $message"
        Write-Host ""
        exit 1
    }
}


& "$PSScriptRoot\GenerateToken.ps1"
& "$PSScriptRoot\ConnectToAzureAD.ps1"
& "$PSScriptRoot\SetApplicationUri.ps1"

function CreateScopesProcess {
    $appName = "$appName"
    $scopesList = "$scopesList"
    $scopes = $scopesList.Split(",")

    # Connect-AzureAD automatically
    ConnectToAzureAD

    # Generate JWT token
    $token = GenerateJWTToken

    # Set Application URI
    Write-Host "Setting Application ID URI for '$($appName)'..."
    SetApplicationUri -appName $appName -token $token
      
    Write-Host "Creating scopes '$($scopesList)' for '$($appName)'..."
    Write-Host ""
    foreach ($item in $scopes) {
        $item = $item.Trim()
        CreateScopes -appName $appName -scope $item   
    }
}
CreateScopesProcess

