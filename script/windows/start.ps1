. "$PSScriptRoot\common.ps1"

Write-Step "Starting Imairuka"
Ensure-Docker
Ensure-InstallEnv
Invoke-Compose up -d
Start-Process "http://localhost:3000"
Write-Host "Opened Imairuka: http://localhost:3000" -ForegroundColor Green
