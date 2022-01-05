

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

function global:AppRegistrationProcess
{
    $appName = "$appName"    
     # Connect-AzureAD automatically
    ConnectToAzureAD
    # Generate JWT token
    $token = GenerateJWTToken -subscription $subscription
    # Create application registration
    CreateAppRegistration -DisplayName $appName -token $token
}

AppRegistrationProcess