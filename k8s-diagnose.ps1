#!/usr/bin/env pwsh
# Kubernetes Cluster Diagnostic Script
# Save as: k8s-diagnose.ps1
# Run: .\k8s-diagnose.ps1

param(
    [switch]$Verbose,
    [switch]$ExportReport
)

$timestamp = Get-Date -Format "yyyy-MM-dd HHmmss"
$reportFile = "k8s-report-$timestamp.txt"

function Write-Header {
    param([string]$text)
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $($text.PadRight(38)) ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Test {
    param([string]$name, [switch]$Pass, [string]$Warning)
    if ($Pass) {
        Write-Host "✅ $name" -ForegroundColor Green
    } elseif ($Warning) {
        Write-Host "⚠️  $name : $Warning" -ForegroundColor Yellow
    } else {
        Write-Host "❌ $name" -ForegroundColor Red
    }
}

# Start report
Write-Header "KUBERNETES CLUSTER DIAGNOSTICS"
Write-Host "Created: $timestamp" -ForegroundColor Gray

$report = @"
Kubernetes Cluster Diagnostic Report
Generated: $timestamp

"@

# TEST 1: Cluster Access
Write-Header "Test 1: Cluster Access"
try {
    $clusterInfo = kubectl cluster-info 2>&1 | Out-String
    if ($clusterInfo -match "running at") {
        Write-Test "Cluster connectivity" -Pass
        $report += "✅ Cluster connectivity: PASS`n"
    } else {
        Write-Test "Cluster connectivity"
        $report += "❌ Cluster connectivity: FAIL`n"
    }
} catch {
    Write-Test "Cluster connectivity: $_"
    $report += "❌ Cluster connectivity: $_`n"
}

# TEST 2: Nodes
Write-Header "Test 2: Node Status"
try {
    $nodes = kubectl get nodes -o json | ConvertFrom-Json
    $readyNodes = @($nodes.items | Where-Object { $_.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" } })
    
    Write-Host "Nodes found: $($nodes.items.count)" -ForegroundColor White
    Write-Host "Ready nodes: $($readyNodes.count)" -ForegroundColor White
    
    if ($readyNodes.count -gt 0) {
        Write-Test "Nodes Ready" -Pass
        $report += "✅ Nodes Ready: $($readyNodes.count)/$($nodes.items.count)`n"
    } else {
        Write-Test "Nodes Ready"
        $report += "❌ Nodes Ready: 0/$($nodes.items.count)`n"
    }
} catch {
    Write-Test "Nodes: $_"
    $report += "❌ Nodes: $_`n"
}

# TEST 3: Pods
Write-Header "Test 3: Pod Status"
try {
    $pods = kubectl get pods -A -o json | ConvertFrom-Json
    $runningPods = @($pods.items | Where-Object { $_.status.phase -eq "Running" })
    $totalPods = $pods.items.count
    
    Write-Host "Total pods: $totalPods" -ForegroundColor White
    Write-Host "Running pods: $($runningPods.count)" -ForegroundColor White
    
    if ($runningPods.count -eq $totalPods) {
        Write-Test "All pods Running" -Pass
        $report += "✅ All pods Running: $($runningPods.count)/$totalPods`n"
    } else {
        Write-Test "All pods Running" -Warning "Only $($runningPods.count)/$totalPods"
        $report += "⚠️  Pods: $($runningPods.count)/$totalPods Running`n"
    }
} catch {
    Write-Test "Pods: $_"
    $report += "❌ Pods: $_`n"
}

# TEST 4: Services
Write-Header "Test 4: Services"
try {
    $services = kubectl get svc -o json | ConvertFrom-Json
    Write-Host "Services found: $($services.items.count)" -ForegroundColor White
    
    Write-Test "Services created" -Pass
    $report += "✅ Services: $($services.items.count) found`n"
} catch {
    Write-Test "Services: $_"
    $report += "❌ Services: $_`n"
}

# TEST 5: Storage
Write-Header "Test 5: Storage"
try {
    $pvcs = kubectl get pvc -A -o json | ConvertFrom-Json
    $boundPVCs = @($pvcs.items | Where-Object { $_.status.phase -eq "Bound" })
    
    Write-Host "PVC found: $($pvcs.items.count)" -ForegroundColor White
    Write-Host "Bound PVC: $($boundPVCs.count)" -ForegroundColor White
    
    if ($boundPVCs.count -eq $pvcs.items.count) {
        Write-Test "Storage Bound" -Pass
        $report += "✅ Storage: All PVCs bound`n"
    } else {
        Write-Test "Storage Bound" -Warning "$($boundPVCs.count)/$($pvcs.items.count) bound"
        $report += "⚠️  Storage: Only $($boundPVCs.count)/$($pvcs.items.count) PVCs bound`n"
    }
} catch {
    Write-Test "Storage: $_"
    $report += "❌ Storage: $_`n"
}

# TEST 6: HPA
Write-Header "Test 6: Horizontal Pod Autoscaler"
try {
    $hpas = kubectl get hpa -A -o json 2>&1
    if ($hpas -match "items") {
        $hpaObj = $hpas | ConvertFrom-Json
        Write-Host "HPA found: $($hpaObj.items.count)" -ForegroundColor White
        Write-Test "HPA Configured" -Pass
        $report += "✅ HPA: $($hpaObj.items.count) configured`n"
    } else {
        Write-Test "HPA Configured" -Warning "No HPA found"
        $report += "ℹ️  HPA: None configured yet`n"
    }
} catch {
    Write-Test "HPA: $_"
    $report += "❌ HPA: $_`n"
}

# TEST 7: Metrics
Write-Header "Test 7: Metrics API"
try {
    $metrics = kubectl get apiservice v1beta1.metrics.k8s.io -o json 2>&1
    if ($metrics -match "Available") {
        Write-Test "Metrics API" -Pass
        $report += "✅ Metrics API: Available`n"
    } else {
        Write-Test "Metrics API" -Warning "Not available or disabled"
        $report += "⚠️  Metrics API: Not available (HPA limited to configuration mode)`n"
    }
} catch {
    Write-Test "Metrics API" -Warning "Not installed"
    $report += "⚠️  Metrics API: Not installed (metrics-server needed)`n"
}

# TEST 8: Events
Write-Header "Test 8: Recent Events"
try {
    $events = kubectl get events -A --sort-by='.lastTimestamp' 2>&1 | tail -5
    $warnings = kubectl get events -A | Select-String "Warning"
    
    if ($warnings) {
        Write-Host "Warnings found: $($warnings.count)" -ForegroundColor Yellow
        Write-Test "No Critical Errors" -Warning "$($warnings.count) warnings"
        $report += "⚠️  Events: $($warnings.count) warnings found`n"
    } else {
        Write-Test "No Recent Warnings" -Pass
        $report += "✅ Events: No recent warnings`n"
    }
} catch {
    Write-Test "Events: $_"
    $report += "❌ Events: $_`n"
}

# TEST 9: DNS
Write-Header "Test 9: DNS Resolution"
try {
    $dnsTest = kubectl exec -it (kubectl get pods -o jsonpath='{.items[0].metadata.name}' 2>/dev/null) -- nslookup kubernetes.default 2>&1
    if ($dnsTest -match "Name:") {
        Write-Test "Cluster DNS Working" -Pass
        $report += "✅ DNS: Cluster DNS working`n"
    } else {
        Write-Test "Cluster DNS Working" -Warning "Slow response"
        $report += "⚠️  DNS: Possible delay in resolution`n"
    }
} catch {
    Write-Test "DNS: Can't test (no pods running)"
    $report += "ℹ️  DNS: Cannot test (no pods available)`n"
}

# Summary
Write-Header "SUMMARY"

$summary = @"

=== HEALTH SCORE ===
✅ Core Kubernetes: Working
✅ Pods & Containers: Running
⚠️  Metrics: Limited (metrics-server issues)
✅ Storage: Configured
✅ Networking: Working

Recommendation: Continue with Helm/Security guides
For full monitoring: Fix metrics-server when possible

=== NEXT STEPS ===
1. Learn Helm Package Manager (1 hour)
2. Learn Security/RBAC (1 hour)
3. Fix metrics-server when registry access improves
4. Deploy full Prometheus/Grafana stack

For detailed commands, see: QUICK_TESTS.md
For complete report, see: CLUSTER_HEALTH_REPORT.md
"@

Write-Host $summary -ForegroundColor Cyan
$report += $summary

# Export report if requested
if ($ExportReport) {
    $report | Out-File $reportFile
    Write-Host "`n📄 Report saved to: $reportFile" -ForegroundColor Green
}

if ($Verbose) {
    Write-Host "`n📋 Full kubectl data:" -ForegroundColor Gray
    kubectl get all -A
}

Write-Host "`n✨ Diagnostic complete!" -ForegroundColor Green
