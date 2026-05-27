# Final DevOps labs — PowerShell commands ONLY
# Usage: .\FINAL_DEVOPS_LABS.ps1
# Then pick: 1=ArgoCD  2=CI verify  3=Blue-Green  4=Canary  5=Observe  6=Backup info

param([int]$Choice = 0)

$Root = $PSScriptRoot
Set-Location $Root

Write-Host @"

========================================
  FINAL DEVOPS LABS (commands only)
========================================
  Do NOT paste URLs or English sentences into PowerShell.
  URLs = open in Edge/Chrome.

"@ -ForegroundColor Cyan

if ($Choice -eq 0) {
    $Choice = Read-Host "Enter 1-6 (1=ArgoCD 2=CI 3=BlueGreen 4=Canary 5=Observe 6=Backup)"
    $Choice = [int]$Choice
}

switch ($Choice) {
    1 {
        $p = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
        if ($p) {
            $plain = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($p))
            Write-Host "ArgoCD login: admin / $plain" -ForegroundColor Green
        }
        kubectl apply -f "$Root\labs\gitops\k8s-app-argocd-application.yaml"
        Write-Host "Open BROWSER: https://localhost:8443" -ForegroundColor Yellow
        Write-Host "Running: kubectl port-forward svc/argocd-server -n argocd 8443:443" -ForegroundColor Yellow
        kubectl port-forward svc/argocd-server -n argocd 8443:443
    }
    2 {
        Write-Host "Local test:" -ForegroundColor Yellow
        npm test
        Write-Host "`nOpen BROWSER for GitHub Actions:" -ForegroundColor Green
        Write-Host "  https://github.com/TejasDB04/Devops/actions"
        Write-Host "`nSecrets (browser only):" -ForegroundColor Green
        Write-Host "  https://github.com/TejasDB04/Devops/settings/secrets/actions"
        Write-Host "  Add: DOCKER_USERNAME, DOCKER_PASSWORD"
    }
    3 {
        & "$Root\labs\blue-green\switch-to-green.ps1"
        Write-Host "BROWSER: http://localhost:8888/api/version" -ForegroundColor Green
        Write-Host "Port-forward (keep open):" -ForegroundColor Yellow
        kubectl port-forward svc/app-production -n blue-green 8888:80
    }
    4 {
        Write-Host "Terminal 1: kubectl port-forward svc/canary-stable -n canary 8081:80" -ForegroundColor Yellow
        Write-Host "Terminal 2: kubectl port-forward svc/canary-new -n canary 8082:80" -ForegroundColor Yellow
        kubectl port-forward svc/canary-stable -n canary 8081:80
    }
    5 {
        docker pull prom/prometheus:v0.47.0 2>$null
        docker pull grafana/grafana:9.3.0 2>$null
        kubectl apply -f "$Root\prometheus-grafana-simple.yaml"
        Write-Host "Terminal A: kubectl port-forward svc/prometheus -n monitoring 9090:9090" -ForegroundColor Yellow
        Write-Host "Terminal B: kubectl port-forward svc/grafana -n monitoring 3001:3000" -ForegroundColor Yellow
        Write-Host "BROWSER: http://localhost:9090  and  http://localhost:3001  (admin/admin123)" -ForegroundColor Green
    }
    6 {
        velero version --client-only 2>$null
        Write-Host "Backup needs Velero server in cluster + storage. Read:" -ForegroundColor Yellow
        Write-Host "  labs\velero\INSTALL_WINDOWS.md"
        Write-Host "  BACKUP_DISASTER_RECOVERY_GUIDE.md"
    }
    default { Write-Host "Read COMMANDS_ONLY.md" }
}
