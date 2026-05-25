kubectl patch svc app-production -n blue-green -p '{"spec":{"selector":{"app":"my-app","version":"blue"}}}'
Write-Host "Rolled back to BLUE." -ForegroundColor Yellow
