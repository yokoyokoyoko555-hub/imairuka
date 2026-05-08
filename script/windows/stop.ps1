. "$PSScriptRoot\common.ps1"

Write-Step "Imairuka を停止しています"
Ensure-Docker
Invoke-Compose down
Write-Host "停止しました。" -ForegroundColor Green
