. "$PSScriptRoot\common.ps1"

$root = Get-ImairukaRoot

Write-Step "Imairuka インストールを開始します"
Ensure-Docker

Write-Step "設定ファイル install.env を準備しています"
Ensure-InstallEnv

Write-Step "コンテナをビルドして起動しています"
Invoke-Compose up -d --build

Write-Step "サンプルデータを投入しています"
Invoke-Compose exec -T web ./bin/rails db:seed

Write-Step "デスクトップショートカットを作成しています"
New-ImairukaShortcut -Name "Imairuka 起動" -Target (Join-Path $root "start_imairuka.bat")
New-ImairukaShortcut -Name "Imairuka 停止" -Target (Join-Path $root "stop_imairuka.bat")
New-ImairukaShortcut -Name "Imairuka バックアップ" -Target (Join-Path $root "backup_imairuka.bat")

Write-Step "Imairuka を開きます"
Start-Process "http://localhost:3000"

Write-Host ""
Write-Host "インストール完了" -ForegroundColor Green
Write-Host "URL: http://localhost:3000"
Write-Host "ログイン: admin@example.com / password1"
