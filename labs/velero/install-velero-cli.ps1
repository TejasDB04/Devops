# Download Velero CLI for Windows amd64 and add to user PATH
$ErrorActionPreference = "Stop"
$Version = "v1.13.2"
$InstallDir = "$env:LOCALAPPDATA\velero"
$ZipUrl = "https://github.com/vmware-tanzu/velero/releases/download/$Version/velero-$Version-windows-amd64.tar.gz"
$TempTar = Join-Path $env:TEMP "velero-$Version-windows-amd64.tar.gz"

Write-Host "Installing Velero CLI $Version to $InstallDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
    Write-Host "Windows 'tar' is required (Windows 10+). Extract manually from:" -ForegroundColor Yellow
    Write-Host $ZipUrl
    exit 1
}

Invoke-WebRequest -Uri $ZipUrl -OutFile $TempTar -UseBasicParsing
tar -xzf $TempTar -C $env:TEMP
$Extracted = Join-Path $env:TEMP "velero-$Version-windows-amd64"
Copy-Item -Path (Join-Path $Extracted "velero.exe") -Destination (Join-Path $InstallDir "velero.exe") -Force

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    $env:Path = "$env:Path;$InstallDir"
}

Write-Host "Velero installed. Open a NEW terminal and run: velero version --client-only" -ForegroundColor Green
& (Join-Path $InstallDir "velero.exe") version --client-only
