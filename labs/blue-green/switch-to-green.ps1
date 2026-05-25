# Switch production traffic from blue to green (instant cutover)
kubectl patch svc app-production -n blue-green -p '{"spec":{"selector":{"app":"my-app","version":"green"}}}'
Write-Host "Production now routes to GREEN. Test:" -ForegroundColor Green
Write-Host "  kubectl port-forward svc/app-production -n blue-green 8080:80"
Write-Host "  curl http://localhost:8080/api/version"
