. "$PSScriptRoot\common.ps1"

$root = Get-ImairukaRoot
$backupDir = Join-Path $root "backups"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path $backupDir "imairuka-$timestamp.sql"

Write-Step "データベースをバックアップしています"
Ensure-Docker
Push-Location $root
try {
  & docker compose -f docker-compose.install.yml exec -T db pg_dump -U imairuka imairuka_production | Out-File -FilePath $backupPath -Encoding utf8
  if ($LASTEXITCODE -ne 0) {
    throw "Database backup failed."
  }
} finally {
  Pop-Location
}

Write-Host "バックアップ完了: $backupPath" -ForegroundColor Green
