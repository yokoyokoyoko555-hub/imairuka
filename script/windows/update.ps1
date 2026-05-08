. "$PSScriptRoot\common.ps1"

$root = Get-ImairukaRoot

Write-Step "Updating Imairuka"
Ensure-Docker

Push-Location $root
try {
  if (Test-Path ".git") {
    git pull
  }
} finally {
  Pop-Location
}

Invoke-Compose up -d --build
Write-Host "Update completed. Opening Imairuka." -ForegroundColor Green
Start-Process "http://localhost:3000"
