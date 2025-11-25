param(
    [string]$Username,
    [string]$Password,
    [string]$MigrationApi,
    [string]$CmaFile
)

try {
    # Debug info
    Write-Host "Username: $Username"
    Write-Host "API URL: $MigrationApi"
    Write-Host "CMA file: $CmaFile"

    # Combine username and password for Basic Auth
    $pair = "$Username`:$Password"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $encodedCreds = [Convert]::ToBase64String($bytes)
    $authHeader = "Basic $encodedCreds"

    # Headers
    $headers = @{
        'accept' = 'application/json'
        'Authorization' = $authHeader
        'Content-Type' = 'application/json'
    }

    # Body
    $body = @{ fileName = $CmaFile } | ConvertTo-Json

    # API URI (ensure no double slash)
    $uri = "$($MigrationApi.TrimEnd('/'))/"

    Write-Host "Calling API at: $uri"

    # Invoke API
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -SkipCertificateCheck

    Write-Host "MDS ID: $($response.mdsId)"

} catch {
    Write-Error "Migration API call failed!"
    Write-Error $_.Exception.Message

    if ($_.Exception.Response -ne $null) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response body: $responseBody"
    }

    exit 1
}
