$ErrorActionPreference = "Stop"

function Get-ImairukaRoot {
  return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-DockerCliPath {
  $command = Get-Command docker -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $candidates = @(
    "$Env:ProgramFiles\Docker\Docker\resources\bin\docker.exe",
    "${Env:ProgramFiles(x86)}\Docker\Docker\resources\bin\docker.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  return $null
}

function Get-DockerDesktopPath {
  $candidates = @(
    "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
    "${Env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe",
    "$Env:LocalAppData\Docker\Docker Desktop.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  return $null
}

function Ensure-Docker {
  $script:DockerCli = Get-DockerCliPath
  if (-not $script:DockerCli) {
    Write-Host "Docker Desktop が見つかりません。" -ForegroundColor Yellow
    Write-Host "Docker Desktop をインストールしてから、もう一度このインストーラーを実行してください。"
    Write-Host "ダウンロード: https://docs.docker.com/desktop/setup/install/windows-install/"
    Start-Process "https://docs.docker.com/desktop/setup/install/windows-install/"
    throw "Docker Desktop is not installed."
  }

  $dockerInfo = & $script:DockerCli info 2>$null
  if ($LASTEXITCODE -eq 0) {
    return
  }

  $dockerDesktop = Get-DockerDesktopPath
  if ($dockerDesktop) {
    Write-Step "Docker Desktop を起動しています"
    Start-Process $dockerDesktop | Out-Null
  }

  Write-Host "Docker Desktop の起動を待っています..."
  for ($i = 1; $i -le 60; $i++) {
    Start-Sleep -Seconds 3
    & $script:DockerCli info 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
      return
    }
  }

  throw "Docker Desktop could not be started. Open Docker Desktop manually and retry."
}

function Invoke-Compose {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  $root = Get-ImairukaRoot
  Push-Location $root
  try {
    if (-not $script:DockerCli) {
      $script:DockerCli = Get-DockerCliPath
    }
    & $script:DockerCli compose -f docker-compose.install.yml @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "docker compose failed: $($Arguments -join ' ')"
    }
  } finally {
    Pop-Location
  }
}

function New-SecretKeyBase {
  $bytes = New-Object byte[] 64
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
  return [Convert]::ToBase64String($bytes)
}

function Ensure-InstallEnv {
  $root = Get-ImairukaRoot
  $envPath = Join-Path $root "install.env"
  $examplePath = Join-Path $root "install.env.example"

  if (Test-Path $envPath) {
    return
  }

  Copy-Item $examplePath $envPath
  $secret = New-SecretKeyBase
  $content = Get-Content $envPath -Raw
  $content = $content -replace "replace-this-with-a-long-random-secret-before-production-use", $secret
  Set-Content -Path $envPath -Value $content -Encoding UTF8
}

function New-ImairukaShortcut {
  param(
    [string]$Name,
    [string]$Target
  )

  $desktop = [Environment]::GetFolderPath("Desktop")
  $shortcutPath = Join-Path $desktop "$Name.lnk"
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = $Target
  $shortcut.WorkingDirectory = Split-Path $Target
  $shortcut.Save()
}
