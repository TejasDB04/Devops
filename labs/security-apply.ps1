# Apply all security lab manifests in order
$Root = Split-Path $PSScriptRoot -Parent
$files = @(
    "developer-role.yaml",
    "admin-role.yaml",
    "readonly-role.yaml",
    "developer-rolebinding.yaml",
    "admin-rolebinding.yaml",
    "default-deny-policy.yaml",
    "allow-ingress-to-web.yaml",
    "labs\security\allow-k8s-app.yaml",
    "db-secret.yaml",
    "secret-reader-role.yaml",
    "secret-reader-binding.yaml",
    "secure-pod.yaml"
)

Write-Host "Creating service accounts..." -ForegroundColor Cyan
kubectl create serviceaccount developer --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount admin-user --dry-run=client -o yaml | kubectl apply -f -

Write-Host "Applying security manifests..." -ForegroundColor Cyan
foreach ($f in $files) {
    $path = Join-Path $Root $f
    if (Test-Path $path) {
        kubectl apply -f $path
    } else {
        Write-Warning "Missing: $f"
    }
}

Write-Host "Labeling k8s-app deployment (tier=web)..." -ForegroundColor Cyan
kubectl apply -f (Join-Path $Root "deployment.yaml") 2>$null

Write-Host "`nRBAC check (developer should be 'no' for delete):" -ForegroundColor Yellow
kubectl auth can-i delete deployments --as=system:serviceaccount:default:developer 2>$null
kubectl auth can-i delete deployments --as=system:serviceaccount:default:admin-user 2>$null
kubectl get networkpolicies
Write-Host "`nRun full verification: .\labs\security-verify.ps1" -ForegroundColor Green
Write-Host "Guide: SECURITY_LAB_TODAY.md" -ForegroundColor Green
