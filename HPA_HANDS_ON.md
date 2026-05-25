# 🔧 HPA (Horizontal Pod Autoscaler) HANDS-ON LAB

## Objective
Set up automatic scaling for your `k8s-app` deployment and watch it:
- ✅ Scale UP when traffic increases (high CPU)
- ✅ Scale DOWN when traffic decreases (low CPU)
- ✅ Never go below 2 or above 10 pods

---

## 📋 Pre-Lab Check (5 minutes)

### Check Your Current Deployment

```powershell
# See what you have
kubectl get deployment k8s-app -o wide

# Should show:
# NAME      READY   UP-TO-DATE   AVAILABLE   AGE
# k8s-app   2/2     2            2           34d
```

### Check Resource Requests

```powershell
# This is CRITICAL for HPA!
kubectl get deployment k8s-app -o yaml | findstr -A 5 "resources:"

# Look for something like:
# resources:
#   requests:
#     cpu: 100m
#     memory: 128Mi
```

---

## 🚀 Part 1: Add Resource Requests to Your Deployment (5 minutes)

HPA needs to know the pod capacity to calculate CPU percentage. If your deployment doesn't have resource requests, add them:

```powershell
# ============================================
# Add resource requests to k8s-app
# ============================================

kubectl set resources deployment k8s-app \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=512Mi

# Verify it was applied
kubectl get deployment k8s-app -o yaml | findstr -A 10 "resources:"

# Should show:
# resources:
#   limits:
#     cpu: 500m
#     memory: 512Mi
#   requests:
#     cpu: 100m
#     memory: 128Mi
```

**Why these values?**
- `requests.cpu: 100m` = Pod uses 100 millicores (0.1 CPU core)
- `limits.cpu: 500m` = Pod can't use more than 0.5 CPU core
- When pod uses 80m CPU: percentage = (80m / 100m) × 100 = **80%**

---

## ✅ Part 2: Verify Metrics Server (2 minutes)

HPA needs the Metrics Server to collect CPU/Memory data. Docker Desktop has it pre-installed.

```powershell
# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# Expected:
# NAME             READY   UP-TO-DATE   AVAILABLE   AGE
# metrics-server   1/1     1            1           35d
```

If missing, install it:

```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
Start-Sleep -Seconds 30
```

---

## 🏗️ Part 3: Create HPA (Horizontal Pod Autoscaler) (5 minutes)

### Option A: Quick Command (Easiest)

```powershell
# ============================================
# Create HPA with simple command
# ============================================

kubectl autoscale deployment k8s-app `
  --min=2 `
  --max=10 `
  --cpu-percent=80

# This means:
# - Minimum 2 pods (even if no traffic)
# - Maximum 10 pods (even if massive traffic)
# - Scale when CPU usage goes ABOVE 80%
# - Scale down when CPU usage goes BELOW 80%
```

### Option B: YAML File (Better for Production)

Create a file named `hpa-k8s-app.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: k8s-app
  
  minReplicas: 2
  maxReplicas: 10
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 30
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
```

Apply it:

```powershell
kubectl apply -f hpa-k8s-app.yaml
```

---

## ✅ Part 4: Verify HPA is Running (3 minutes)

```powershell
# ============================================
# Check HPA status
# ============================================

kubectl get hpa

# Expected output:
# NAME       REFERENCE             TARGETS    MINPODS  MAXPODS  REPLICAS  AGE
# app-hpa    Deployment/k8s-app    5%/80%     2        10       2         10s

# TARGETS: 5%/80%
#   = Current CPU: 5%
#   = Target CPU: 80%
#   = Action: NONE (5% < 80%, no need to scale)

# REPLICAS: 2
#   = Currently running 2 pods
```

Get more details:

```powershell
kubectl describe hpa app-hpa

# Look for "Events:" section at bottom for scaling info
```

---

## 🧪 Part 5: Test Scaling - Generate Load (15 minutes)

### Terminal 1: Watch Pods Scale

```powershell
# Open a NEW PowerShell terminal and run:

kubectl get pods -l app=k8s-app --watch

# You'll see pods appear/disappear as load changes
# Leave this running!
```

### Terminal 2: Watch HPA Metrics

```powershell
# Open ANOTHER NEW PowerShell terminal and run:

kubectl get hpa --watch

# You'll see CPU percentage change in real-time
# Leave this running!
```

### Terminal 3: Generate Load

```powershell
# Open ANOTHER NEW PowerShell terminal (you should have 3 total)
# Generate traffic to increase CPU usage

kubectl run -it --rm load-generator `
  --image=busybox `
  --restart=Never `
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://k8s-app-service; done"

# This will:
# 1. Send HTTP requests to your app
# 2. Increase CPU usage on pods
# 3. Trigger HPA to scale UP

# Watch Terminal 1 and 2 for changes!
```

### What You Should See

**Terminal 1 (Pods):**
```
NAME                       READY   STATUS    RESTARTS   AGE
k8s-app-86cb45f5c8-97g8j   1/1     Running   0          5m
k8s-app-86cb45f5c8-shmd9   1/1     Running   0          5m

# After ~30 seconds of load:
k8s-app-86cb45f5c8-97g8j   1/1     Running   0          5m
k8s-app-86cb45f5c8-shmd9   1/1     Running   0          5m
k8s-app-5bd8f6c9c9-abcde   0/1     Pending   0          5s     ← NEW POD!
k8s-app-5bd8f6c9c9-fghij   0/1     Pending   0          4s     ← NEW POD!
```

**Terminal 2 (HPA):**
```
NAME       REFERENCE             TARGETS    MINPODS  MAXPODS  REPLICAS  AGE
app-hpa    Deployment/k8s-app    5%/80%     2        10       2         2m

# After load starts:
app-hpa    Deployment/k8s-app    92%/80%    2        10       2         2m  ← CPU went UP!

# After 15-30 seconds:
app-hpa    Deployment/k8s-app    82%/80%    2        10       4         2m30s ← SCALED TO 4!

# After more time:
app-hpa    Deployment/k8s-app    85%/80%    2        10       6         3m ← SCALED TO 6!
```

---

## 📊 Part 6: Stop Load and Watch Scale Down (10 minutes)

### Stop Load Generation

In **Terminal 3**, press **Ctrl+C** to stop the load generator.

```powershell
# Load generator will stop
# CPU usage will drop
# HPA will wait ~5 minutes, then scale DOWN
```

### Watch the Scale-Down

Continue watching **Terminal 1** and **Terminal 2**:

```
# Terminal 2 (HPA) after ~5 minutes:
NAME       REFERENCE             TARGETS    MINPODS  MAXPODS  REPLICAS  AGE
app-hpa    Deployment/k8s-app    15%/80%    2        10       4         8m ← CPU dropped!

# After scaling decision:
app-hpa    Deployment/k8s-app    15%/80%    2        10       3         8m30s ← Reduced to 3
app-hpa    Deployment/k8s-app    12%/80%    2        10       2         9m ← Back to 2 (minimum)

# Terminal 1 (Pods):
# Numbers decrease back to 2 pods
```

### Why Scale-Down is Slow

- HPA scales UP quickly (30 seconds) to handle traffic
- HPA scales DOWN slowly (5 minutes) to avoid "flapping"
- **Flapping** = constantly scaling up and down (wastes resources)

---

## 🔍 Part 7: Check Metrics (5 minutes)

While load is running, see actual CPU/Memory usage:

```powershell
# ============================================
# Check top pods (memory/cpu usage)
# ============================================

kubectl top pods -l app=k8s-app

# Example output:
# NAME                       CPU(cores)   MEMORY(bytes)
# k8s-app-86cb45f5c8-97g8j   120m         50Mi
# k8s-app-86cb45f5c8-shmd9   110m         48Mi
# k8s-app-5bd8f6c9c9-abcde   105m         45Mi

# INTERPRETATION:
# Pod requested: 100m CPU
# Pod using: 120m CPU
# Percentage: (120m / 100m) × 100 = 120%!
# → Way above 80% target, so more pods scale up
```

Check nodes:

```powershell
kubectl top nodes

# Example:
# NAME                 CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# docker-desktop       1500m        15%    2500Mi          32%
```

---

## ✅ Part 8: Verification Checklist

Go through this to confirm everything works:

```
HPA SETUP
[ ] Deployment k8s-app has resource requests (cpu: 100m, memory: 128Mi)
[ ] Metrics server is running in kube-system namespace
[ ] HPA app-hpa is created and ACTIVE

UNDER NORMAL LOAD
[ ] HPA shows 2 replicas (minimum)
[ ] CPU percentage is low (< 50%)
[ ] No scaling happening

UNDER HIGH LOAD
[ ] Load generator is sending requests
[ ] CPU percentage goes above 80%
[ ] Should see NEW PODS being created
[ ] HPA increases replica count to 4, 6, or more
[ ] kubectl top pods shows high CPU usage

SCALE DOWN TEST
[ ] Stopped load generator
[ ] Waited 5+ minutes
[ ] HPA reduced pods back to 2 (minimum)
[ ] CPU percentage back to normal (< 30%)
```

---

## 📈 Understanding HPA Scaling Formula

```
Desired Replicas = current_replicas × (current_cpu / target_cpu)

Example:
- Current replicas: 2
- Current CPU: 92% (from metrics)
- Target CPU: 80%

Desired = 2 × (92 / 80) = 2 × 1.15 = 2.3 → **Round to 3 replicas**

After scaling to 3:
- New CPU: 92 / 3 = ~30% per pod average
- 30% < 80%, so wait for stabilization
- In ~1 minute, check again...
- If still high, scale to more pods
```

---

## 🐛 Troubleshooting During Lab

### HPA Shows `<unknown>/80%` for Targets

```powershell
# Metrics not collected yet
# Solution: WAIT 1-2 minutes

# Then check:
kubectl get hpa --watch

# If still unknown after 2 minutes:
# Your deployment might not have resource requests!
# Fix with: kubectl set resources deployment k8s-app --requests=cpu=100m
```

### Load Generator Won't Start

```powershell
# Error: "image busybox not found"
# Solution: Use different image:

kubectl run -it --rm load-generator `
  --image=alpine `
  -- sh -c "while sleep 0.01; do wget -q -O- http://k8s-app-service; done"

# Or install wget first:
kubectl run -it --rm load-generator `
  --image=alpine `
  -- sh -c "apk add --no-cache wget; while sleep 0.01; do wget -q -O- http://k8s-app-service; done"
```

### Pods Not Scaling Even with High CPU

```powershell
# Check HPA status
kubectl describe hpa app-hpa

# Look for errors in Events section
# Common fixes:
# 1. Increase maxReplicas if at limit
# 2. Check resource requests are set
# 3. Check metrics server is running
# 4. Wait longer (metrics take time)
```

### Pods Won't Scale Down

```powershell
# This is normal! HPA waits 5 minutes before scaling down
# This prevents "flapping" (constantly up-down scaling)

# If you need to scale down immediately:
kubectl scale deployment k8s-app --replicas=2

# Or edit HPA to reduce scaleDownStabilizationWindowSeconds:
kubectl edit hpa app-hpa
# Change "scaleDownStabilizationWindowSeconds: 60" to "30"
```

---

## 📊 Real-World Scenarios

### Scenario 1: E-Commerce During Sales Event
```
Normal traffic:   2 pods (CPU 30%)
Sale starts:      Load increases
15 seconds later: HPA scales to 6 pods
30 seconds later: HPA scales to 12 pods (hitting service limit)
Peak traffic:     10,000 requests/second across 12 pods

Sale ends:
Load drops:       CPU falls to 20%
5 minutes later:  HPA scales back to 2 pods
Money saved! 💰
```

### Scenario 2: Data Processing Pipeline
```
minReplicas: 1        # Start small
maxReplicas: 50       # Go huge when needed
targetCPU: 90%

Only scales when CPU is REALLY high
Useful for batch jobs that can tolerate delays
```

---

## 🎓 Key Learnings

After this lab, you understand:

✅ **Resource Requests** - How HPA calculates CPU percentage
✅ **Metrics** - Real-time CPU/Memory collection
✅ **Scaling Triggers** - When HPA decides to scale
✅ **Scale UP vs DOWN** - Why scaling down is slower
✅ **Cost Savings** - Fewer pods when not needed
✅ **Performance** - More pods when busy

---

## 🎯 Quick Commands Reference

```powershell
# Create HPA
kubectl autoscale deployment k8s-app --min=2 --max=10 --cpu-percent=80

# Check HPA
kubectl get hpa
kubectl describe hpa app-hpa
kubectl get hpa --watch

# Check metrics
kubectl top pods
kubectl top nodes

# Set resource requests
kubectl set resources deployment k8s-app --requests=cpu=100m,memory=128Mi

# Generate load
kubectl run -it --rm load-generator --image=busybox -- sh -c "while true; do wget -q -O- http://k8s-app-service; done"

# Edit HPA
kubectl edit hpa app-hpa

# Delete HPA
kubectl delete hpa app-hpa
```

---

## 🎉 Lab Complete!

When you finish:

1. ✅ Deployment has resource requests
2. ✅ HPA is created and monitoring CPU
3. ✅ Verified scaling UP with load test
4. ✅ Verified scaling DOWN after stopping load
5. ✅ Understand how HPA works in production

**Message when done:** "HPA scaling complete! Ready for Monitoring & Observability."

