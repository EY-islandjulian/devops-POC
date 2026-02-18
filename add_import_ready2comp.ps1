param(
   [string]$Username,
   [string]$Password,
   [string]$MigrationApi,   # e.g. https://<host>/migration
   [string]$CmaFile,               # CMA filename already stored in OSS
   # OPTIONAL – only passed for CCSDEV
   [string]$ShouldAutoApply,
   [string]$DefaultStatusForAdd,
   [string]$DefaultStatusForChange
)
try {
   Write-Host "Starting CMA migration..."
   Write-Host "Username: $Username"
   Write-Host "API Base URL: $MigrationApi"
   Write-Host "CMA file: $CmaFile"
   # Build Basic Auth header
   $pair = "$Username`:$Password"
   $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
   $encodedCreds = [Convert]::ToBase64String($bytes)
   $authHeader = "Basic $encodedCreds"
   # Headers
   $headers = @{
       accept        = 'application/json'
       Authorization = $authHeader
       'Content-Type' = 'application/json'
   }
   # Build POST /addImport body
   $importPayload = @{
       fileName = $CmaFile
   }
   if ($ShouldAutoApply) {
       $importPayload.shouldAutoApply = $ShouldAutoApply
   }
   if ($DefaultStatusForAdd) {
       $importPayload.defaultStatusForAdd = $DefaultStatusForAdd
   }
   if ($DefaultStatusForChange) {
       $importPayload.defaultStatusForChange = $DefaultStatusForChange
   }
   $body = @($importPayload) | ConvertTo-Json
   # DEBUG: Show exactly what we’re sending
   Write-Host "POST BODY:" $body
   $importUri = "$($MigrationApi.TrimEnd('/'))/addImport"
   $response = Invoke-RestMethod `
       -Uri $importUri `
       -Method Post `
       -Headers $headers `
       -Body $body `
       -SkipCertificateCheck
   Write-Host "Import submitted successfully."
   Write-Host "Response:" ($response | ConvertTo-Json -Depth 5)
   $migrationDataSetId = $response.migrationDataSetId
   if (-not $migrationDataSetId) {
       throw "migrationDataSetId not found in response."
   }
   $statusUri = "$($MigrationApi.TrimEnd('/'))/$migrationDataSetId/import"
   $pollIntervalSeconds = 15
   $timeoutMinutes = 30
   $elapsed = 0
   Write-Host "Polling migration status..."
   while ($elapsed -lt ($timeoutMinutes * 60)) {
       $statusResponse = Invoke-RestMethod `
           -Uri $statusUri `
           -Method Get `
           -Headers $headers `
           -SkipCertificateCheck
       $status = $statusResponse.statusDescription
       Write-Host "Current status: $status (elapsed: $elapsed seconds)"
       if ($status -eq "Ready to Compare") {
           Write-Host "Migration finished with status: $status"
           exit 0
       }
       elseif ($status -eq "Error") {
           Write-Error "❌ Migration finished with status: Error"
           Write-Error ($statusResponse | ConvertTo-Json -Depth 10)
           exit 1
       }
       Start-Sleep -Seconds $pollIntervalSeconds
       $elapsed += $pollIntervalSeconds
   }
   throw "Migration did not complete within $timeoutMinutes minutes."
}
catch {
   Write-Error "Migration API call failed!"
   Write-Error $_.Exception.Message
   # PRIMARY: Most REST API 400/500 errors appear here
   if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
       Write-Error "Response body (ErrorDetails):"
       Write-Error $_.ErrorDetails.Message
   }
   # SECONDARY: fallback for HttpResponseMessage
   elseif ($_.Exception.Response -is [System.Net.Http.HttpResponseMessage]) {
       try {
           $responseBody = $_.Exception.Response.Content.ReadAsStringAsync().Result
           Write-Error "Response body (HttpResponseMessage):"
           Write-Error $responseBody
       } catch {
           Write-Error "Unable to read response body."
       }
   }
   exit 1

}
