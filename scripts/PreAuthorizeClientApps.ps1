[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    $webAppName,

    [Parameter(Mandatory=$true)]
    $clientAppName,

    [Parameter(Mandatory=$true)]
    $scope
)

function global:AuthorizeClientApplications
{
    param (
        $webAppName,
        $clientAppName,
        $scope
    )
    $webAppName = "$webAppName"
    $clientAppName = "$clientAppName"
    $scope = "$scope"
    # Authorize apps
    try 
    {
        if(($app = Get-AzureADMSApplication -Filter "DisplayName eq '$($webAppName)'"))
        {
            $clientApp = Get-AzureADMSApplication -Filter "DisplayName eq '$($clientAppName)'"    
            if (![string]::IsNullOrEmpty($clientApp))
            {
                $preAuthorizedApplications = New-Object 'System.Collections.Generic.List[Microsoft.Open.MSGraph.Model.PreAuthorizedApplication]'
                if($app.api.PreAuthorizedApplications.count -ge 0)
                {
                    $app.Api.PreAuthorizedApplications | foreach-object { $preAuthorizedApplications.Add($_) }
                }
                #Write-Host $app.Api.PreAuthorizedApplications
                $ifSameValueExist = $app.Api.PreAuthorizedApplications | Select-Object AppId | Where-Object {$_.AppId -eq "$($clientApp.AppId)"}            
                if([string]::IsNullOrEmpty($ifSameValueExist))
                {                
                    $scopedetails = $app.Api.Oauth2PermissionScopes | Select-Object Id,Value | Where-Object {$_.Value -match "$($scope)"}
                    if(![string]::IsNullOrEmpty($scopedetails))
                    {                                                
                        $ClienPreauthorization = CreatePreAuthorizedApplication `
                                -applicationIdToPreAuthorize $clientApp.AppId `
                                -scopeId $scopedetails.Id
                                
                        $preAuthorizedApplications.Add($ClienPreauthorization)                    
                        #Write-Host $preAuthorizedApplications
                        $app.Api.PreAuthorizedApplications = $preAuthorizedApplications
                        Set-AzureADMSApplication -ObjectId $app.Id -Api $app.Api
                        Write-Host "Applications pre-authorized."

                    }
                    else {
                        
                    }
                }
                else {
                    Write-Host -f Yellow "##[warning] Client App is already authorized for '$($scope)'"
                    return
                }
            }
            else {
                Write-Host -f Yellow "##[warning] Application with name '$($clientAppName)' does not Exists"
                Write-Host ""
                return
            }
        }
        else
        {
            Write-Host -f Yellow "##[warning] Application with name '$($webAppName)' does not Exists"
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

function global:CreatePreAuthorizedApplication
{
    param
    (
        [string] $applicationIdToPreAuthorize,
        [string] $scopeId
    )
    try 
    {       
        $preAuthorizedApplication = New-Object 'Microsoft.Open.MSGraph.Model.PreAuthorizedApplication'
        $preAuthorizedApplication.AppId = $applicationIdToPreAuthorize
        $preAuthorizedApplication.DelegatedPermissionIds = @($scopeId)
        return $preAuthorizedApplication
    }
    catch {
        $message = $_.Exception.message
        Write-Host  "##vso[task.LogIssue type=error;] $message"
        Write-Host ""
        exit 1
    }
}
& "$PSScriptRoot\ConnectToAzureAD.ps1"

function PreAuthorizeAppsProcess {
    $webAppName = "$webAppName"
    $clientAppName = "$clientAppName"
    $scope = "$scope"
    # Connect-AzureAD automatically
    ConnectToAzureAD     
    Write-Host "Authorizing client app..."
    Write-Host ""
    $scope = $scope.Trim()
    AuthorizeClientApplications -webAppName $webAppName -clientAppName $clientAppName -scope $scope   
    
}
PreAuthorizeAppsProcess