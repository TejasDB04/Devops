# Menu: run remaining DevOps concept labs
param([int]$Lab = 0)

$Root = $PSScriptRoot
Set-Location $Root

function Test-Cluster {
    kubectl cluster-info 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

if (-not (Test-Cluster)) {
    Write-Host "Kubernetes not reachable. Enable Kubernetes in Docker Desktop." -ForegroundColor Red
    exit 1
}

$menu = @"
========================================
  Remaining DevOps Labs
========================================
  1  Observe     (Prometheus + Grafana + metrics)
  2  Security    (RBAC + Network Policies)
  3  Blue-Green  (zero-downtime deploy)
  4  Canary      (gradual rollout)
  5  GitOps      (ArgoCD install + app)
  6  CI/CD       (npm test locally)
  7  Pull images (fix ImagePullBackOff)
  0  Exit
========================================
"@

if ($Lab -eq 0) {
    Write-Host $menu
    $Lab = Read-Host "Enter lab number"
    $Lab = [int]$Lab
}

switch ($Lab) {
    1 {
        Write-Host "`n=== Lab 1: Observe ===" -ForegroundColor Cyan
        docker pull prom/prometheus:v0.47.0
        docker pull grafana/grafana:9.3.0
        kubectl apply -f deployment.yaml -f service.yaml
        kubectl apply -f prometheus-grafana-simple.yaml
        Write-Host "Port-forward: kubectl port-forward svc/prometheus -n monitoring 9090:9090"
        Write-Host "Port-forward: kubectl port-forward svc/grafana -n monitoring 3000:3000"
    }
    2 {
        Write-Host "`n=== Lab 2: Security ===" -ForegroundColor Cyan
        & "$Root\labs\security-apply.ps1"
    }
    3 {
        Write-Host "`n=== Lab 3: Blue-Green ===" -ForegroundColor Cyan
        kubectl apply -f "$Root\labs\blue-green\"
        kubectl get all -n blue-green
    }
    4 {
        Write-Host "`n=== Lab 4: Canary ===" -ForegroundColor Cyan
        kubectl apply -f "$Root\labs\canary\"
        kubectl get all -n canary
    }
    5 {
        Write-Host "`n=== Lab 5: GitOps ===" -ForegroundColor Cyan
        kubectl create namespace argocd 2>$null
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        kubectl apply -f "$Root\labs\gitops\k8s-app-argocd-application.yaml"
        Write-Host "Wait for argocd-server, then: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    }
    6 {
        Write-Host "`n=== Lab 6: CI/CD tests ===" -ForegroundColor Cyan
        npm test
    }
    7 {
        Write-Host "`n=== Pull monitoring images ===" -ForegroundColor Cyan
        docker pull prom/prometheus:v0.47.0
        docker pull grafana/grafana:9.3.0
        docker pull grafana/loki:2.9.0
        docker pull grafana/promtail:2.9.0
        kubectl delete pod -n monitoring --all
    }
    default { Write-Host "See DEVOPS_REMAINING_LABS.md" }
}

Write-Host "`nDetails: DEVOPS_REMAINING_LABS.md" -ForegroundColor Green
