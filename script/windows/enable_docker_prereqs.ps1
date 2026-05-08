$ErrorActionPreference = "Stop"

function Test-Admin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
  $scriptPath = $MyInvocation.MyCommand.Path
  Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`""
  exit
}

Write-Host "Enabling Windows features required by Docker Desktop..." -ForegroundColor Cyan

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
if ($LASTEXITCODE -ne 0) { throw "Failed to enable WSL feature." }

dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
if ($LASTEXITCODE -ne 0) { throw "Failed to enable VirtualMachinePlatform feature." }

dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart
if ($LASTEXITCODE -ne 0) { throw "Failed to enable Hyper-V feature." }

bcdedit /set hypervisorlaunchtype auto
if ($LASTEXITCODE -ne 0) { throw "Failed to set hypervisorlaunchtype." }

Write-Host ""
Write-Host "Done. Restart Windows now." -ForegroundColor Green
Write-Host "After restart, open Docker Desktop and run install_imairuka.bat again."
