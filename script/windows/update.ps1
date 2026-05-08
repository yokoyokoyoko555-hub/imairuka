. "$PSScriptRoot\common.ps1"

$root = Get-ImairukaRoot

Write-Step "Imairuka を更新しています"
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
Write-Host "更新完了。Imairuka を開きます。" -ForegroundColor Green
Start-Process "http://localhost:3000"
