param(
    [string]$Username,
    [string]$Password,
    [string]$MigrationApi,
    [string]$CmaFile
)

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

# API URI
$uri = "$MigrationApi/"

# Invoke API
$response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -SkipCertificateCheck

Write-Output "MDS ID: $($response.mdsId)"
