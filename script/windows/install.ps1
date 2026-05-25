. "$PSScriptRoot\common.ps1"

$root = Get-ImairukaRoot

Write-Step "Starting Imairuka install"
Ensure-Docker

Write-Step "Preparing install.env"
Ensure-InstallEnv

Write-Step "Building and starting containers"
Invoke-Compose up --detach --build

Write-Step "Loading sample data"
Invoke-Compose exec -T web ./bin/rails db:seed

Write-Step "Creating desktop shortcuts"
New-ImairukaShortcut -Name "Imairuka Start" -Target (Join-Path $root "start_imairuka.bat")
New-ImairukaShortcut -Name "Imairuka Stop" -Target (Join-Path $root "stop_imairuka.bat")
New-ImairukaShortcut -Name "Imairuka Backup" -Target (Join-Path $root "backup_imairuka.bat")

Write-Step "Opening Imairuka"
Start-Process "http://localhost:3000"

Write-Host ""
Write-Host "Install completed" -ForegroundColor Green
Write-Host "URL: http://localhost:3000"
Write-Host "Login: admin@example.com / Password1!"
