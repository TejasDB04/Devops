# Deploy observability stack (Prometheus + Grafana + optional Loki)
# Prerequisites: Docker Desktop Kubernetes enabled, kubectl working

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

Write-Host "`n=== Observability deploy ===" -ForegroundColor Cyan

Write-Host "`n[1/5] Checking cluster..." -ForegroundColor Yellow
kubectl cluster-info | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cluster not reachable. Enable Kubernetes in Docker Desktop, then re-run." -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/5] Deploying Prometheus + Grafana (monitoring namespace)..." -ForegroundColor Yellow
kubectl apply -f "$ProjectRoot\prometheus-grafana-simple.yaml"
kubectl wait --for=condition=available deployment/prometheus -n monitoring --timeout=180s
kubectl wait --for=condition=available deployment/grafana -n monitoring --timeout=180s

Write-Host "`n[3/5] Optional: Loki + Promtail (centralized logs)..." -ForegroundColor Yellow
$installLoki = Read-Host "Install Loki log stack? (y/N)"
if ($installLoki -eq 'y' -or $installLoki -eq 'Y') {
    helm repo add grafana https://grafana.github.io/helm-charts 2>$null
    helm repo update
    helm upgrade --install loki grafana/loki-stack `
        -n monitoring `
        -f "$ProjectRoot\loki-stack-values.yaml" `
        --wait --timeout 5m
}

Write-Host "`n[4/5] Rebuild app image with /metrics (if Docker available)..." -ForegroundColor Yellow
$rebuild = Read-Host "Rebuild k8s-app Docker image locally? (y/N)"
if ($rebuild -eq 'y' -or $rebuild -eq 'Y') {
    Push-Location $ProjectRoot
    docker build -t k8s-app:latest .
    kubectl rollout restart deployment/k8s-app 2>$null
    Pop-Location
} else {
    Write-Host "Skip rebuild — ensure app image includes prom-client and /metrics endpoint." -ForegroundColor DarkYellow
}

Write-Host "`n[5/5] Verify targets..." -ForegroundColor Yellow
kubectl get pods -n monitoring
kubectl get pods -l app=k8s-app -n default 2>$null

Write-Host @"

=== Access UIs (run in separate terminals) ===

  Prometheus:  kubectl port-forward svc/prometheus -n monitoring 9090:9090
               http://localhost:9090  -> Status -> Targets (look for kubernetes-pods / k8s-app)

  Grafana:     kubectl port-forward svc/grafana -n monitoring 3000:3000
               http://localhost:3000  user: admin  password: admin123

=== Useful PromQL ===
  rate(k8s_app_http_requests_total[1m])
  histogram_quantile(0.95, rate(k8s_app_http_request_duration_seconds_bucket[5m]))

=== Logs in Grafana (after Loki) ===
  Explore -> Loki -> query: {namespace="default"} |= "k8s-app"

Full lab: OBSERVE_HANDS_ON.md

"@ -ForegroundColor Green
