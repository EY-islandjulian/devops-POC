param(
   [Parameter(Mandatory = $true)]
   [string]$ReleaseTag,
   [Parameter(Mandatory = $true)]
   [string]$TargetEnv,
   [Parameter(Mandatory = $true)]
   [string]$DeployStatus,
   [Parameter(Mandatory = $true)]
   [string]$Repo
)
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm")
$entry = "• $TargetEnv | $DeployStatus | $timestamp | by $env:GITHUB_ACTOR"
# Fetch existing release notes
$existingNotes = gh release view $ReleaseTag `
   --repo $Repo `
   --json body `
   -q .body 2>$null
if ([string]::IsNullOrWhiteSpace($existingNotes)) {
   $updatedNotes = $entry
}
else {
   # Append
   $updatedNotes = $existingNotes.TrimEnd() + "`r`n`r`n" + $entry
}
# test file
$tempFile = New-TemporaryFile
Set-Content -Path $tempFile -Value $updatedNotes -Encoding utf8
# Update release notes safely
gh release edit $ReleaseTag `
   --repo $Repo `
   --notes-file $tempFile
Remove-Item $tempFile -Force
Write-Host "Release notes appended successfully"