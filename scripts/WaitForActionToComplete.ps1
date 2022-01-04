function global:Wait-Action {
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]$Timeout = 120,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]$RetryInterval = 3
    )
    try {
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and (!(($AppReg = Get-AzureADMSApplication -Filter "DisplayName eq '$($DisplayName)'").Count -eq 1)))
        {
            Start-Sleep -Seconds $RetryInterval
            $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds, 0)
            Write-Verbose -Message "Still waiting for action to complete after [$totalSecs] seconds..."
        }
        $timer.Stop()
        if ($timer.Elapsed.TotalSeconds -gt $Timeout) {
            throw 'Action did not complete before timeout period.'
        } else {
            Write-Verbose -Message 'Action completed before timeout period.'
        }
    } catch {
        Write-Error -Message $_.Exception.Message
    }
}


