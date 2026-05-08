. "$PSScriptRoot\common.ps1"

Write-Step "Stopping Imairuka"
Ensure-Docker
Invoke-Compose down
Write-Host "Stopped." -ForegroundColor Green
