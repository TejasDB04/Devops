# Verify Security lab (RBAC + NetworkPolicy)
$ErrorActionPreference = "Continue"
Write-Host "`n=== Security Lab Verification ===" -ForegroundColor Cyan

Write-Host "`n--- RBAC ---" -ForegroundColor Yellow
Write-Host "Developer can VIEW deployments:"
kubectl auth can-i get deployments --as=system:serviceaccount:default:developer
Write-Host "Developer can DELETE deployments (expect no):"
kubectl auth can-i delete deployments --as=system:serviceaccount:default:developer
Write-Host "Admin can DELETE deployments (expect yes):"
kubectl auth can-i delete deployments --as=system:serviceaccount:default:admin-user

Write-Host "`n--- Roles & bindings ---" -ForegroundColor Yellow
kubectl get roles,rolebindings -n default
kubectl get clusterrole admin-role 2>$null
kubectl get clusterrolebinding admin-binding 2>$null

Write-Host "`n--- Network policies ---" -ForegroundColor Yellow
kubectl get networkpolicies -n default

Write-Host "`n--- k8s-app health (after policies) ---" -ForegroundColor Yellow
kubectl get pods -l app=k8s-app
$p = kubectl get pods -l app=k8s-app -o jsonpath="{.items[0].metadata.name}" 2>$null
if ($p) {
    kubectl exec $p -- wget -qO- http://localhost:3000/api/health 2>$null
}

Write-Host "`n--- Secure pod ---" -ForegroundColor Yellow
kubectl get pod secure-app 2>$null

Write-Host "`nDone. See SECURITY_LAB_TODAY.md" -ForegroundColor Green
