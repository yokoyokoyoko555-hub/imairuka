. "$PSScriptRoot\common.ps1"

Write-Step "Imairuka を起動しています"
Ensure-Docker
Ensure-InstallEnv
Invoke-Compose up -d
Start-Process "http://localhost:3000"
Write-Host "Imairuka を開きました: http://localhost:3000" -ForegroundColor Green
