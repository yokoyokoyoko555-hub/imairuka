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
    "$([Environment]::GetEnvironmentVariable('ProgramFiles(x86)'))\Docker\Docker\resources\bin\docker.exe"
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
    "$([Environment]::GetEnvironmentVariable('ProgramFiles(x86)'))\Docker\Docker\Docker Desktop.exe",
    "$Env:LocalAppData\Docker\Docker Desktop.exe"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  return $null
}

function Test-DockerReady {
  if (-not $script:DockerCli) {
    $script:DockerCli = Get-DockerCliPath
  }

  $process = New-Object System.Diagnostics.Process
  $process.StartInfo.FileName = $script:DockerCli
  $process.StartInfo.Arguments = "info"
  $process.StartInfo.UseShellExecute = $false
  $process.StartInfo.RedirectStandardOutput = $true
  $process.StartInfo.RedirectStandardError = $true
  $process.StartInfo.CreateNoWindow = $true

  try {
    $null = $process.Start()
    if (-not $process.WaitForExit(10000)) {
      $process.Kill()
      return $false
    }
    return $process.ExitCode -eq 0
  } finally {
    $process.Dispose()
  }
}

function Ensure-Docker {
  $script:DockerCli = Get-DockerCliPath
  if (-not $script:DockerCli) {
    Write-Host "Docker Desktop was not found." -ForegroundColor Yellow
    Write-Host "Install Docker Desktop, then run this installer again."
    Write-Host "Download: https://docs.docker.com/desktop/setup/install/windows-install/"
    Start-Process "https://docs.docker.com/desktop/setup/install/windows-install/"
    throw "Docker Desktop is not installed."
  }

  if (Test-DockerReady) {
    return
  }

  $dockerDesktop = Get-DockerDesktopPath
  if ($dockerDesktop) {
    Write-Step "Starting Docker Desktop"
    Start-Process $dockerDesktop | Out-Null
  }

  Write-Host "Waiting for Docker Desktop..."
  for ($i = 1; $i -le 60; $i++) {
    Start-Sleep -Seconds 3
    if (Test-DockerReady) {
      return
    }
  }

  Write-Host ""
  Write-Host "Docker Desktop is installed, but the Linux engine is not ready." -ForegroundColor Yellow
  Write-Host "Please open Docker Desktop and finish the first-run setup."
  Write-Host "If it asks for WSL2 or virtualization, enable it and restart Windows."
  throw "Docker Desktop engine is not ready."
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
