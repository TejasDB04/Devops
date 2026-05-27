# ONLY run this script — do not paste guide text into PowerShell
# Usage: .\RUN_THESE_COMMANDS.ps1

$ErrorActionPreference = "Continue"
Write-Host "`n=== DevOps Lab Commands (PowerShell only) ===" -ForegroundColor Cyan
Write-Host "Instructions in markdown are NOT commands. Only run lines from this script or code blocks marked kubectl/git/docker.`n"

function Test-PortFree([int]$Port) {
    $conn = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return -not $conn
}

# --- ArgoCD UI ---
Write-Host "[1] ArgoCD password:" -ForegroundColor Yellow
$pass = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
if ($pass) {
    $plain = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($pass))
    Write-Host "    User: admin"
    Write-Host "    Password: $plain"
}

$argoPort = 8443
if (-not (Test-PortFree 8443)) { $argoPort = 9443 }

Write-Host "`n[2] Starting ArgoCD port-forward on localhost:$argoPort (leave this window open)..." -ForegroundColor Yellow
Write-Host "    Open in BROWSER (Edge/Chrome), not PowerShell:" -ForegroundColor Green
Write-Host "    https://localhost:$argoPort`n" -ForegroundColor Green
Write-Host "    In UI: Applications -> k8s-app -> Refresh -> Sync`n"

Start-Process "https://localhost:$argoPort"
kubectl port-forward svc/argocd-server -n argocd "${argoPort}:443"
