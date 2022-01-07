function global:SetApplicationUri
{
    param (
        $appName,
        $token
    )
    $appName = "$appName"
    $token = "$token"
    $patchBody = ""
    
    try 
    {
        if(($AppReg = Get-AzureADMSApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
        {
            if($AppReg.count -eq 1 -and $AppReg.IdentifierUris.count -eq 0)
            {

                
                $url = "https://graph.microsoft.com/v1.0/applications/$($AppReg.Id)"
                $header = @{
                    Authorization = "Bearer $token"
                }

                $patchBody = @"
                {
                    "identifierUris" : [
                        "api://$($AppReg.AppId)"
                    ]
                }
"@
            
                $appRegistration = Invoke-RestMethod -Method 'PATCH' -Uri $url -Body $patchBody -ContentType 'application/json' -Headers $header
                Write-Host -f Green "##[section] Application URI for '$($appName)' created successfully"
                Write-Host ""
            }
            else 
            {
                if($AppReg.api.oauth2PermissionScopes.count -ge 1)
                {
                    Write-Host -f Yellow "##[warning] Application URI for '$($appName)' already exists"
                    Write-Host ""
                }
                else
                {
                    Write-Host -f Yellow "##[warning] There is than 1 Application with same display name"
                    Write-Host ""
                }
            }
        }
        else 
        {
            Write-Host -f Yellow "##[warning] Application with name '$($appName)' does not Exists"
            Write-Host ""
        }
    }
    catch
    {
        $message = $_.Exception.message
        Write-Host  "##vso[task.LogIssue type=error;] $message"
        exit 1      
    }
}
