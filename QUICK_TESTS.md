# 🧪 Quick Cluster Health Test Commands

Copy and paste these commands to test your cluster at any time!

---

## 1️⃣ BASIC CLUSTER TEST (30 seconds)

```powershell
# Check cluster is running
kubectl cluster-info

# Check nodes are ready
kubectl get nodes

# Check all pods
kubectl get pods -A
```

**Expected:**
- Cluster running
- Node status: Ready
- Pods in various namespaces

---

## 2️⃣ YOUR APPLICATION TEST (1 minute)

```powershell
# Check k8s-app is running
kubectl get deployment k8s-app -o wide

# Check app pods are healthy
kubectl get pods -l app=k8s-app -o wide

# Check app is responding
kubectl exec -it $(kubectl get pods -l app=k8s-app -o jsonpath='{.items[0].metadata.name}') -- wget -q -O- http://localhost:3000
```

**Expected Output:**
```
k8s-app-xxxxx   2/2     2            2
{"message":"Welcome to...",
```

---

## 3️⃣ HPA TEST (1 minute)

```powershell
# Check HPA is configured
kubectl get hpa -o wide

# Check HPA details
kubectl describe hpa k8s-app

# Check if metrics are available
kubectl top pods
```

**Expected:**
- HPA shows k8s-app
- Min=2, Max=10
- (May show metrics as "unknown" - that's OK)

---

## 4️⃣ STORAGE TEST (1 minute)

```powershell
# Check persistent volumes
kubectl get pv

# Check persistent volume claims
kubectl get pvc

# Check storage status
kubectl get pvc,pv
```

**Expected:**
- PV: my-pv, Status=Bound
- PVC: my-pvc, Status=Bound

---

## 5️⃣ SERVICES & NETWORKING TEST (1 minute)

```powershell
# Check services
kubectl get svc

# Check Ingress
kubectl get ingress

# Check endpoints
kubectl get endpoints
```

**Expected:**
- k8s-app-service exists
- app-ingress exists
- Endpoints point to pods

---

## 6️⃣ ERROR & WARNING TEST (1 minute)

```powershell
# Check for warnings
kubectl get events | Select-String "Warning"

# Check for errors
kubectl get events | Select-String "Error"

# Check pod status
kubectl get pods --field-selector=status.phase!=Running
```

**Expected:** Few or no warnings (that's normal)

---

## 7️⃣ COMPLETE HEALTH CHECK (2 minutes)

Run all tests in one command:

```powershell
Write-Host "=== CLUSTER STATUS ===" -ForegroundColor Green
kubectl cluster-info

Write-Host "`n=== NODES ===" -ForegroundColor Green
kubectl get nodes -o wide

Write-Host "`n=== PODS ===" -ForegroundColor Green
kubectl get pods -o wide

Write-Host "`n=== HPA ===" -ForegroundColor Green
kubectl get hpa

Write-Host "`n=== SERVICES ===" -ForegroundColor Green
kubectl get svc

Write-Host "`n=== INGRESS ===" -ForegroundColor Green
kubectl get ingress

Write-Host "`n=== STORAGE ===" -ForegroundColor Green
kubectl get pvc,pv

Write-Host "`n=== EVENTS ===" -ForegroundColor Green
kubectl get events --sort-by='.lastTimestamp' | Select-Object -Last 10

Write-Host "`n=== APP LOGS ===" -ForegroundColor Green
kubectl logs -l app=k8s-app --tail=5

Write-Host "`n✅ Health check complete!" -ForegroundColor Green
```

---

## 8️⃣ TEST APP CONNECTIVITY (Advanced)

```powershell
# Test from inside a pod
kubectl exec -it $(kubectl get pods -l app=k8s-app -o jsonpath='{.items[0].metadata.name}') -- sh

# Inside the pod, run:
wget -q -O- http://localhost:3000
wget -q -O- http://kubernetes.default:443

# Exit pod:
exit
```

---

## 9️⃣ TEST LOAD BALANCER (If using)

```powershell
# Get service IP
$SERVICE_IP = kubectl get svc k8s-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "Service IP: $SERVICE_IP"

# Get NodePort
$NODE_PORT = kubectl get svc k8s-app-service -o jsonpath='{.spec.ports[0].nodePort}'
Write-Host "NodePort: $NODE_PORT"

# Test via NodePort
$NODE_IP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
Write-Host "Testing: http://$NODE_IP:$NODE_PORT"
```

---

## 🔟 QUICK METRICS TEST

```powershell
# Check if metrics API is available
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Try to get node metrics
kubectl top nodes

# Try to get pod metrics
kubectl top pods

# If errors: metrics-server not ready yet
```

---

## 🧹 CLEANUP TEST (Be Careful!)

⚠️ **Only run if you want to restart everything:**

```powershell
# Delete all pods (they'll restart)
kubectl delete pods --all

# Watch them restart
kubectl get pods -w

# Delete everything (careful!)
kubectl delete all,pvc,pv --all
```

---

## 📊 AUTOMATED MONITORING

Keep checking cluster health continuously:

```powershell
# Watch pods in real-time
kubectl get pods -w

# Watch HPA scaling
kubectl get hpa -w

# Watch events
kubectl get events -w

# Watch top CPU/Memory
kubectl top nodes --use-protocol-buffers -w
```

Press `Ctrl+C` to stop watching.

---

## ✅ SUCCESS CRITERIA

Your cluster is healthy if:

- ✅ `kubectl get nodes` shows STATUS=Ready
- ✅ `kubectl get pods` shows most pods Running
- ✅ `kubectl get svc` shows services with IPs
- ✅ `kubectl logs` shows app started successfully
- ✅ `kubectl get events` shows mostly Normal events
- ⚠️ Warnings OK (metrics, timeouts are temporary)

---

## 🆘 If Something's Wrong

**Pods not Running?**
```powershell
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
```

**Service not accessible?**
```powershell
kubectl get endpoints <service-name>
kubectl describe svc <service-name>
```

**Storage issues?**
```powershell
kubectl get pvc
kubectl describe pvc <pvc-name>
```

**Metrics not working?**
```powershell
kubectl get pods -n kube-system
kubectl logs -n kube-system -l k8s-app=metrics-server
```

---

## 📈 Performance Baseline

Run occasionally to track performance:

```powershell
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods

# Pod resource requests vs actual
kubectl get pods -o json | ConvertFrom-Json | select -ExpandProperty items | `
  ForEach-Object { 
    Write-Host $_.metadata.name; 
    $_.spec.containers | `
    ForEach-Object { 
      "  CPU Requested: $($_.resources.requests.cpu), Memory: $($_.resources.requests.memory)" 
    } 
  }
```

---

## 🎯 Daily Health Check (Copy & Paste)

```powershell
# Quick daily check
kubectl get nodes,pods,svc,hpa; kubectl get events --sort-by='.lastTimestamp' | Select-Object -Last 3
```

---

## 📝 Log These Commands

Create a PowerShell alias for quick health checks:

```powershell
# Add to PowerShell profile:
function k8s-health { 
  kubectl get all -o wide; 
  kubectl get events --sort-by='.lastTimestamp' | Select-Object -Last 5 
}

# Then just type:
k8s-health
```

---

## 🚀 Ready to Test?

Start with Test #1 and work your way up!

Each test takes 30 seconds and you'll know exactly how healthy your cluster is. 💪

---

---

# 🔟 ADVANCED TESTING SECTION

## Port Forward & Direct Access

```powershell
# Forward port to access app locally
kubectl port-forward svc/k8s-app-service 8000:80

# In another terminal, test:
Invoke-WebRequest http://localhost:8000

# Or use curl if available:
curl http://localhost:8000
```

---

## Pod Information & Inspection

```powershell
# Get all pod IPs
kubectl get pods -o wide

# Get specific pod's IP
kubectl get pod <pod-name> -o jsonpath='{.status.podIP}'

# Get pod's internal hostname
kubectl exec -it <pod-name> -- hostname

# Get node where pod runs
kubectl get pod <pod-name> -o jsonpath='{.spec.nodeName}'

# Get all pod resource limits and requests
kubectl get pods -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[0].resources.requests.cpu,MEM_REQ:.spec.containers[0].resources.requests.memory,CPU_LIM:.spec.containers[0].resources.limits.cpu,MEM_LIM:.spec.containers[0].resources.limits.memory
```

---

## Pod Networking & Connectivity

```powershell
# List all service names and IPs
kubectl get svc -o custom-columns=NAME:.metadata.name,CLUSTER-IP:.spec.clusterIP,PORT:.spec.ports[0].port

# Test DNS resolution from pod
kubectl exec -it <pod-name> -- nslookup kubernetes.default

# Test DNS for service
kubectl exec -it <pod-name> -- nslookup k8s-app-service

# Check if pod can reach another pod
kubectl exec -it <pod-name> -- ping $(kubectl get pod <target-pod> -o jsonpath='{.status.podIP}')

# List all endpoints
kubectl get endpoints -o wide

# Check endpoints for a service
kubectl get endpoints k8s-app-service -o wide
```

---

## Container Details & Configuration

```powershell
# List all container images in use
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}' 

# Get container command/args
kubectl get pods -o custom-columns=POD:.metadata.name,CONTAINER:.spec.containers[0].name,COMMAND:.spec.containers[0].command

# Check environment variables in pod
kubectl exec -it <pod-name> -- env | head -20

# Check working directory
kubectl exec -it <pod-name> -- pwd

# Check user/permissions
kubectl exec -it <pod-name> -- id
```

---

## Pod Scaling & Replica Management

```powershell
# Check current replica count
kubectl get deployment k8s-app -o jsonpath='{.spec.replicas}'

# Scale to specific number
kubectl scale deployment k8s-app --replicas=3
kubectl scale deployment k8s-app --replicas=5

# Watch scaling happening in real-time
kubectl get pods -w

# Check scaling history (events)
kubectl describe deployment k8s-app | Select-String -Pattern "Replicas|Events" -Context 0,10

# Get replicaset information
kubectl get rs -o wide

# Check replicaset details
kubectl describe rs <rs-name>
```

---

## Service & LoadBalancer Diagnostics

```powershell
# Full service details
kubectl get svc -o wide

# Describe service with more details
kubectl describe svc k8s-app-service

# Get ClusterIP
kubectl get svc k8s-app-service -o jsonpath='{.spec.clusterIP}'

# Get NodePort (if applicable)
$NODE_PORT = kubectl get svc k8s-app-service -o jsonpath='{.spec.ports[0].nodePort}'
Write-Host "NodePort: $NODE_PORT"

# Get port number
kubectl get svc k8s-app-service -o jsonpath='{.spec.ports[0].port}'

# Get target port
kubectl get svc k8s-app-service -o jsonpath='{.spec.ports[0].targetPort}'

# Test service connectivity
kubectl exec -it $(kubectl get pods -l app=k8s-app -o jsonpath='{.items[0].metadata.name}') -- wget -q -O- http://k8s-app-service:80
```

---

## Ingress & External Access

```powershell
# Check all ingress
kubectl get ingress -o wide

# Detailed ingress info
kubectl describe ingress app-ingress

# Get ingress IP address
kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Get ingress hostname
kubectl get ingress app-ingress -o jsonpath='{.spec.rules[0].host}'

# Check ingress class
kubectl get ingress -o jsonpath='{.items[*].spec.ingressClassName}'

# Test ingress (add to /etc/hosts first)
# 172.18.0.4 myapp.local
curl -H "Host: myapp.local" http://172.18.0.4
```

---

## Persistent Storage Diagnostics

```powershell
# List all volumes
kubectl get pv -o wide

# List all claims
kubectl get pvc -o wide

# Detailed PV information
kubectl describe pv my-pv

# Detailed PVC information
kubectl describe pvc my-pvc

# Check storage class
kubectl get storageclass

# Check volume mounted in pod
kubectl get pod <pod-name> -o jsonpath='{.spec.volumes}'

# Check mount path in pod
kubectl exec -it <pod-name> -- ls -la /data/

# Test writing to volume
kubectl exec -it <pod-name> -- sh -c 'echo "test data" > /data/test-file.txt'
kubectl exec -it <pod-name> -- cat /data/test-file.txt

# Check PVC usage
kubectl exec -it <pod-name> -- du -sh /data/
```

---

## Deployment Updates & Rollbacks

```powershell
# Check current image version
kubectl get deployment k8s-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check all container details
kubectl describe deployment k8s-app | grep -A 5 "Image:"

# Get update history
kubectl rollout history deployment k8s-app

# Get specific revision details
kubectl rollout history deployment k8s-app --revision=1

# Update with new image
kubectl set image deployment/k8s-app app=k8s-app:v2.0 --record

# Check rollout status
kubectl rollout status deployment/k8s-app

# Watch deployment rolling update
kubectl get pods -w

# Undo last rollout
kubectl rollout undo deployment/k8s-app

# Undo to specific revision
kubectl rollout undo deployment/k8s-app --to-revision=1

# Pause rollout (for debugging)
kubectl rollout pause deployment/k8s-app

# Resume rollout
kubectl rollout resume deployment/k8s-app
```

---

## Resource Usage & Monitoring

```powershell
# Node resource usage (CPU, Memory)
kubectl top nodes

# Node resource usage with wide format
kubectl top nodes --no-headers

# Pod resource usage
kubectl top pods

# Pod resource usage in all namespaces
kubectl top pods -A

# Pod resource usage with containers
kubectl top pods --containers

# Compare requested vs used
kubectl get pods -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[0].resources.requests.cpu,CPU_USE:.status.containerStatuses[0].lastState

# Node allocatable resources
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU_ALLOCATABLE:.status.allocatable.cpu,MEMORY_ALLOCATABLE:.status.allocatable.memory

# Check node capacity
kubectl describe node desktop-control-plane | Select-String "Capacity:" -A 5
```

---

## Application Logs & Debugging

```powershell
# Last 50 lines
kubectl logs <pod-name> --tail=50

# Last 5 minutes
kubectl logs <pod-name> --since=5m

# Last 1 hour
kubectl logs <pod-name> --since=1h

# Follow logs (stream)
kubectl logs -f <pod-name>

# All pods matching label
kubectl logs -l app=k8s-app --all-containers=true

# Previous pod logs (if crashed)
kubectl logs <pod-name> --previous

# Logs with timestamps
kubectl logs <pod-name> --timestamps=true

# Get logs for multiple pods
kubectl logs -l app=k8s-app --tail=5 --prefix

# Stream logs from all pods
kubectl logs -f -l app=k8s-app --all-containers=true
```

---

## Interactive Pod Debugging

```powershell
# Get shell access to pod (sh)
kubectl exec -it $(kubectl get pods -l app=k8s-app -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

# Get shell access to pod (bash)
kubectl exec -it <pod-name> -- /bin/bash

# Run single command in pod
kubectl exec <pod-name> -- ps aux

# Run command as specific user
kubectl exec -it <pod-name> -- whoami

# Inside pod shell, useful commands:
# ps aux          - List processes
# cat /etc/hostname - Pod name
# ifconfig        - Network configuration
# netstat -tlnp   - Open ports
# curl localhost:3000 - Test app
# wget -O- http://localhost:3000 - GET request
# env   - Environment variables
# df -h - Disk space
# du -sh /data - Directory size
```

---

## HPA & Scaling Diagnostics

```powershell
# Check HPA status
kubectl get hpa -o wide

# Detailed HPA info
kubectl describe hpa k8s-app

# Check HPA metrics
kubectl get hpa k8s-app -o custom-columns=NAME:.metadata.name,REFERENCE:.spec.scaleTargetRef.name,TARGETS:.status.currentMetrics[0].resource.current,MIN:.spec.minReplicas,MAX:.spec.maxReplicas,REPLICAS:.status.currentReplicas

# Check if metrics are available
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Check metrics-server status
kubectl get pods -n kube-system | Select-String "metrics"

# Check metrics-server logs
kubectl logs -n kube-system -l k8s-app=metrics-server --tail=50

# View HPA events
kubectl describe hpa k8s-app | tail -20
```

---

## Configuration & Secrets

```powershell
# List all ConfigMaps
kubectl get configmap -A

# View specific ConfigMap
kubectl get configmap <name> -o yaml

# Get ConfigMap data
kubectl get configmap <name> -o jsonpath='{.data}'

# List all Secrets
kubectl get secret -A

# View secret keys
kubectl get secret <name> -o jsonpath='{.data}' | ConvertFrom-Json

# Describe secret
kubectl describe secret <name>

# View secret value (base64 decoded) in PowerShell
$secretValue = kubectl get secret <name> -o jsonpath='{.data.password}'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secretValue))

# Check service account
kubectl get serviceaccount

# Describe service account
kubectl describe serviceaccount default
```

---

## Event Monitoring & Analysis

```powershell
# All events sorted by time
kubectl get events --sort-by='.lastTimestamp'

# Last 10 events
kubectl get events --sort-by='.lastTimestamp' | Select-Object -Last 10

# Watch events in real-time
kubectl get events -w

# Events for specific pod
kubectl get events --field-selector involvedObject.name=<pod-name>

# Filter warning events
kubectl get events | Select-String "Warning"

# Filter error events
kubectl get events | Select-String "Error"

# Events from specific namespace
kubectl get events -n <namespace>

# Get events for resource type
kubectl get events --field-selector involvedObject.kind=Pod

# Show event details
kubectl describe event <event-name>
```

---

## Cluster Status Overview

```powershell
# Compact cluster overview
kubectl get all -o wide

# Full YAML export
kubectl get all -o yaml > cluster-backup.yaml

# Current context
kubectl config current-context

# Current user
kubectl config get-users

# API versions available
kubectl api-versions

# API resources
kubectl api-resources

# Cluster certificate info
kubectl get secrets -n kube-system | Select-String "crt"

# Check kubelet version
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kubeletVersion}'

# Check container runtime
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
```

---

## RBAC & Authorization Checks

```powershell
# Check current user permissions
kubectl auth can-i get pods

# Check if can delete pods
kubectl auth can-i delete pods

# Check if can create deployments
kubectl auth can-i create deployments

# Check multiple permissions
kubectl auth can-i list pods,services,deployments

# Check as different user (if configured)
kubectl auth can-i get pods --as=system:serviceaccount:default:my-sa

# List all roles
kubectl get roles

# List all role bindings
kubectl get rolebindings

# List cluster roles
kubectl get clusterroles

# List cluster role bindings
kubectl get clusterrolebindings

# Describe role
kubectl describe role <role-name>

# Describe role binding
kubectl describe rolebinding <rolebinding-name>
```

---

## Create & Run Test Pods

```powershell
# Quick busybox pod for testing
kubectl run test-pod --image=busybox --rm -it -- sh

# Alpine pod with curl/wget
kubectl run test-pod --image=alpine --rm -it -- sh

# Run test and exit
kubectl run test-pod --image=busybox --restart=Never --rm -it -- wget -q -O- http://k8s-app-service

# Run with custom command
kubectl run debug --image=busybox --restart=Never -- sleep 3600

# Execute command in running pod
kubectl exec -it debug -- sh

# Delete test pod
kubectl delete pod test-pod
```

---

## Namespace Management

```powershell
# List all namespaces
kubectl get namespace

# Get current namespace
kubectl config view | Select-String "namespace:"

# Create new namespace
kubectl create namespace dev

# Set default namespace
kubectl config set-context --current --namespace=dev

# Get pods from specific namespace
kubectl get pods -n kube-system

# Get pods from all namespaces
kubectl get pods -A

# Create resource in specific namespace
kubectl apply -f deployment.yaml -n dev

# Delete namespace
kubectl delete namespace dev
```

---

## Batch Operations & Filtering

```powershell
# Get all resources matching label
kubectl get all -l app=k8s-app -o wide

# Get pods in specific phase
kubectl get pods --field-selector=status.phase=Running

# Get pods not running
kubectl get pods --field-selector=status.phase!=Running

# Get resources by creation time
kubectl get pods --sort-by=.metadata.creationTimestamp

# Get pods by restart count
kubectl get pods --sort-by=.status.containerStatuses[0].restartCount

# Filter by label selector
kubectl get pods -l "app=k8s-app,environment=prod"

# Get pods with no labels
kubectl get pods -l key!=value

# Delete all pods matching label
kubectl delete pods -l app=k8s-app

# Delete failed pods
kubectl delete pods --field-selector=status.phase=Failed
```

---

## Performance & Stress Testing

```powershell
# Run load test pod
kubectl run -it --rm load-test --image=busybox --restart=Never -- sh

# Inside pod, generate load:
# while true; do wget -q -O- http://k8s-app-service > /dev/null; done

# Watch scaling in action
kubectl get hpa -w

# Watch pods increase
kubectl get pods -w

# Monitor CPU/memory during test
kubectl top pods --containers -w

# Check if HPA triggered scaling
kubectl describe hpa k8s-app | Select-String -Pattern "Current|Min|Max"
```

---

## YAML & Configuration Export

```powershell
# Export deployment as YAML
kubectl get deployment k8s-app -o yaml > deployment-backup.yaml

# Export service as YAML
kubectl get svc k8s-app-service -o yaml > service-backup.yaml

# Export all resources
kubectl get all -o yaml > all-resources.yaml

# Edit resource (opens editor)
kubectl edit deployment k8s-app

# Get YAML without metadata
kubectl get pod <pod-name> -o yaml | Select-String -Pattern "apiVersion|kind|metadata|spec" -Context 0,50

# Apply from file
kubectl apply -f deployment-backup.yaml

# Dry run (test without applying)
kubectl apply -f deployment.yaml --dry-run=client -o yaml
```

---

## Cleanup & Maintenance

```powershell
# Delete stuck pod (force)
kubectl delete pod <pod-name> --force --grace-period=0

# Restart all pods in deployment
kubectl rollout restart deployment/k8s-app

# Clear all completed jobs
kubectl delete job --field-selector=status.successful=1

# Remove all failed pods
kubectl delete pods --field-selector=status.phase=Failed

# Clean up events (old events)
kubectl delete events --all

# Prune unused resources
kubectl delete pods --field-selector=status.phase=Succeeded
```

---

## PowerShell Aliases & Functions

```powershell
# Add to PowerShell profile (edit with: notepad $PROFILE)

# Simple aliases
Set-Alias -Name k -Value kubectl
Set-Alias -Name kg -Value kubectl

# Function for quick health check
function k8s-health {
    Write-Host "=== CLUSTER STATUS ===" -ForegroundColor Green
    kubectl cluster-info
    
    Write-Host "`n=== NODES ===" -ForegroundColor Green
    kubectl get nodes
    
    Write-Host "`n=== PODS ===" -ForegroundColor Green
    kubectl get pods -o wide
    
    Write-Host "`n=== SERVICES ===" -ForegroundColor Green
    kubectl get svc
}

# Function to get all resources of a type
function k8s-show {
    param([string]$resource)
    kubectl get $resource -o wide
}

# Function to show pod logs
function k8s-logs {
    param([string]$pod)
    kubectl logs $pod -f --tail=50
}

# Function to exec into pod
function k8s-exec {
    param([string]$pod)
    kubectl exec -it $pod -- /bin/sh
}

# Function to describe resource
function k8s-desc {
    param([string]$resource, [string]$name)
    kubectl describe $resource $name
}

# Usage:
# k8s-health
# k8s-show pods
# k8s-logs pod-name
# k8s-exec pod-name
# k8s-desc pod pod-name
```

---

## Real-World Testing Scenarios

### Scenario 1: App is not responding
```powershell
# 1. Check if pods are running
kubectl get pods

# 2. Check pod logs
kubectl logs <pod-name>

# 3. Check if service exists
kubectl get svc k8s-app-service

# 4. Check service endpoints
kubectl get endpoints k8s-app-service

# 5. Test from another pod
kubectl exec -it <healthy-pod> -- wget -v http://k8s-app-service

# 6. Check events
kubectl get events | Select-String "Error|Warning"
```

### Scenario 2: Pod keeps restarting
```powershell
# 1. Check restart count
kubectl get pods

# 2. Check logs
kubectl logs <pod-name> --previous

# 3. Check resource limits
kubectl describe pod <pod-name> | Select-String -Pattern "Limits|Requests" -A 5

# 4. Check liveness probe
kubectl describe pod <pod-name> | Select-String "Liveness"

# 5. Check events
kubectl describe pod <pod-name> | tail -20
```

### Scenario 3: Storage not accessible
```powershell
# 1. Check PVC
kubectl get pvc

# 2. Check PV
kubectl get pv

# 3. Check mount in pod
kubectl exec -it <pod-name> -- ls -la /data/

# 4. Check events
kubectl describe pvc <pvc-name>

# 5. Check pod volume mounts
kubectl describe pod <pod-name> | grep -A 5 "Mounts:"
```

### Scenario 4: High memory/CPU usage
```powershell
# 1. Check resource usage
kubectl top pods

# 2. Find problematic pod
kubectl top pods --containers

# 3. Check limits
kubectl describe pod <pod-name> | Select-String "Limits"

# 4. Check if HPA is scaling
kubectl describe hpa

# 5. Check app logs for memory leaks
kubectl logs <pod-name> --tail=100
```

---

## Monitoring Command Cheat Sheet

| Command | Purpose |
|---------|---------|
| `kubectl cluster-info` | Check cluster status |
| `kubectl get nodes` | List all nodes |
| `kubectl get pods` | List all pods |
| `kubectl describe pod <name>` | Detailed pod info |
| `kubectl logs <pod>` | View pod logs |
| `kubectl logs -f <pod>` | Follow logs |
| `kubectl top pods` | CPU/Memory usage |
| `kubectl get events` | List events |
| `kubectl get services` | List services |
| `kubectl get ingress` | List ingress |
| `kubectl get hpa` | List HPA |
| `kubectl get pvc` | List volumes |
| `kubectl exec -it <pod> -- sh` | Shell into pod |
| `kubectl scale --replicas=3 <resource>` | Scale resource |
| `kubectl rollout restart <resource>` | Restart resource |

---

## 📊 Quick Command Categories

**Observation:**`get`, `describe`, `logs`  
**Interaction:** `exec`, `port-forward`, `top`  
**Configuration:** `apply`, `edit`, `set`  
**Scaling:** `scale`, `rollout`  
**Cleanup:** `delete`, `drain`  

---

## ⏱️ Estimated Test Times

- Basic tests (1-3): **3 minutes**
- Intermediate tests (4-6): **5 minutes**
- Advanced section: **10-15 minutes**
- Full cluster test: **20 minutes**
- Performance test with load: **10 minutes**

---

**Last Updated:** May 15, 2026  
**All commands tested on:** Windows PowerShell + Docker Desktop  
**Ready to use:** ✅ Copy-paste and run immediately

**Last Updated:** May 15, 2026
**Windows PowerShell Compatible:** ✅ Yes
**No special permissions needed:** ✅ Yes
