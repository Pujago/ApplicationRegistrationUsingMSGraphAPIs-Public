

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    $appName
    
)
$appName = "$appName"


if (($appName -eq '')) 
{
    write-host "Application name cannot be empty"; 
    exit(1) 
}



& "$PSScriptRoot\GenerateToken.ps1"
& "$PSScriptRoot\WaitForActionToComplete.ps1"
& "$PSScriptRoot\ConnectToAzureAD.ps1"



function global:CreateAppRegistration {
    param (
        $DisplayName,
        $token
    )

    $DisplayName = "$DisplayName"
    $token = "$token"

    # Create App Registration
    Write-Host "Checking if Application '$($DisplayName)' exists ... "
    Write-Host ""
    try {
        
        if(!($AppReg = Get-AzureADMSApplication -Filter "DisplayName eq '$($DisplayName)'"  -ErrorAction SilentlyContinue))
        {
            Write-Host "Application '$($DisplayName)' does not exists, creating one ..."
            Write-Host ""
            
            $url = "https://graph.microsoft.com/v1.0/applications"
            $header = @{
                Authorization = "Bearer $token"
            }

            $postBody = @"
            {
                "displayName": "$DisplayName"
            }
"@

            try 
            {
                
                $appRegistration = Invoke-RestMethod -Method 'POST' -Uri $url -Body $postBody -ContentType 'application/json' -Headers $header
           
            }
            catch
            {
                $message = $_.Exception.message
                write-host -f Red $message
                Write-Host ""
                exit
                
            }

            Write-Host -f Green "##[section] Application '$($DisplayName)' created successfully"
            Write-Host ""
        
        }
        else
        {
            Write-Host -f Yellow "##[warning] Application with name '$($DisplayName)' already Exists"            
            Write-Host ""
        }
    }
    catch {
        $message = $_.Exception.message
        Write-host -f Red $message
        Write-host ""
        exit
    }
}


function global:UpdateAppRegistration {
    param (
        $DisplayName,
        $token
    )

    $DisplayName = "$DisplayName"
    $token = "$token"


    # Update App Registration
    try
    {

    
        if(($AppReg = Get-AzureADMSApplication -Filter "DisplayName eq '$($DisplayName)'"  -ErrorAction SilentlyContinue))
        {
            if($AppReg.count -eq 1)
            {                
                if(!($AppReg.SignInAudience -eq 'AzureADMyOrg'))
                {
                    $url = "https://graph.microsoft.com/v1.0/applications"
                    $header = @{
                        Authorization = "Bearer $token"
                    }

                    try 
                    {

                        # By default graph api creates AzureADandPersonalMicrosoftAccount as signin Audience, updating to AzureADMyOrg 
                        $patchBody = '{
                            "signInAudience" : "AzureADMyOrg"
                        }'

                        $url = "https://graph.microsoft.com/v1.0/applications/$($AppReg.Id)"
                        $appRegistration = Invoke-RestMethod -Method 'PATCH' -Uri $url -Body $patchBody -ContentType 'application/json' -Headers $header        
                        Write-Host -f Green "##[section]Application '$($DisplayName)' successfully updated"
                        Write-host ""
                    }
                    catch
                    {
                        $message = $_.Exception.message
                        Write-Host "Error while updating '$($DisplayName)' ..."
                        write-host $message
                        Write-Host ""
                        exit
                        
                    }
                }
                else 
                {
                    Write-Host -f Yellow "##[warning] Application '$($DisplayName)' is already updated with 'AzureAdMyorg'"
                    Write-host ""
                }
            }
            else {
                Write-Host -f Red "##[warning] There is more that one Application with same name '$($DisplayName)'. Will not update app registration..."
                Write-Host ""
            }
        }
        else
        {
            Write-Host -f Yellow "##[warning] Application with name '$($DisplayName)' does not Exists"
            Write-Host ""
        }
    }
    catch
    {
        $message = $_.Exception.message
        write-host $message
        exit
    }
}


function global:AppRegistrationProcess
{

    $appName = "$appName"    


     # Connect-AzureAD automatically
    ConnectToAzureAD

    # Generate JWT token
    $token = GenerateJWTToken -subscription $subscription
   
    CreateAppRegistration -DisplayName $appName -token $token

    Wait-Action -DisplayName $appName
    

    Write-Host "By default MS Graph API creates AzureADandPersonalMicrosoftAccount as signin Audience, updating to AzureADMyOrg.."
    Write-host ""
    # By default graph api creates AzureADandPersonalMicrosoftAccount as signin Audience, updating to AzureADMyOrg 

    UpdateAppRegistration -DisplayName $appName -token $token        

}

AppRegistrationProcess