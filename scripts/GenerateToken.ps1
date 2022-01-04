function global:GenerateJWTToken {

        Write-Host "Creating jwt for Sandbox subscription ...."
        Write-Host ""
        $displayName = "<Your App Registration Name>"
        $clientAppRegistration = Get-AzureADMSApplication -Filter "DisplayName eq '$($displayName)'"
        $clientId = $clientAppRegistration.AppId           
        $url = "https://login.microsoftonline.com/<your tenant Id>/oauth2/token"
        $body = "grant_type=client_credentials&client_id=$clientId&client_secret=<your app registration secret>&resource=https://graph.microsoft.com"
        $header = @{
            "Content-Type" = 'application/x-www-form-urlencoded'
        }

        $request = Invoke-WebRequest -Method 'Post' -Uri $url -Body $body -Header $header
        $request = $request.Content | ConvertFrom-Json
        $token = $request.access_token
        return $token
    
    
}