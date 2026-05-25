# 🚀 Horizontal Pod Autoscaler (HPA) - Complete Guide

## What is HPA?

**HPA automatically scales your pods based on metrics** (CPU, Memory, or custom metrics).

```
Normal Load (2 pods)  →  High Traffic  →  Auto-scales to 10 pods  →  Traffic drops  →  Scales back to 2
```

---

## 🔍 How It Works

### Without HPA (Manual Scaling)
```
Morning: 2 pods running (no traffic)
Noon: Traffic spikes!
     But you have only 2 pods → SLOW! Users get timeouts 😭
     Manual fix: kubectl scale deployment web --replicas=10
     Takes 5 minutes to apply...

Evening: Traffic drops
     But you have 10 pods → WASTED RESOURCES 💸
     Manual fix: kubectl scale deployment web --replicas=2
     Takes another 5 minutes...
```

### With HPA (Automatic Scaling)
```
Morning: 2 pods (low CPU ~30%)
Noon: Traffic spikes!
     HPA detects: CPU 80% → Auto-scales to 10 pods (in seconds!)
     ✅ Users happy, fast response times

Evening: Traffic drops
     HPA detects: CPU 30% → Auto-scales back to 2 pods
     ✅ Money saved, no manual intervention needed
```

---

## 📊 Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  HPA Controller (Runs every 15 seconds)                 │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │  1. Read metrics from Metrics Server                    │ │
│  │  2. Calculate current CPU/Memory usage                  │ │
│  │  3. Compare with target (80% CPU)                       │ │
│  │  4. Decide: Scale UP, DOWN, or STAY                     │ │
│  │  5. Apply scale to Deployment                           │ │
│  └─────────────────────────────────────────────────────────┘ │
│                          ↓                                     │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Metrics Server (Collects metrics every 15 seconds)     │ │
│  │  └─ Gets CPU/Memory from each pod's kubelet            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                          ↓                                     │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────────┐ │
│  │  Pod 1   │  Pod 2   │  Pod 3   │  Pod 4   │  Pod 5       │ │
│  │ CPU:70%  │ CPU:75%  │ CPU:80%  │ CPU:72%  │ CPU:78%      │ │
│  │ MEM:60%  │ MEM:65%  │ MEM:70%  │ MEM:62%  │ MEM:68%      │ │
│  └──────────┴──────────┴──────────┴──────────┴──────────────┘ │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Concepts

### 1. **Metrics Server** (REQUIRED!)
- Collects CPU/Memory metrics from all pods
- Runs in `kube-system` namespace
- Docker Desktop: **Already installed!** ✅

```bash
# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# If not installed:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 2. **Resource Requests** (REQUIRED!)
HPA needs to know pod resource limits to calculate percentages:

```yaml
containers:
- name: app
  resources:
    requests:      # ← HPA calculates percentage based on THIS
      cpu: 100m    # 0.1 CPU cores
      memory: 128Mi # 128 Megabytes
    limits:        # ← Max allowed
      cpu: 500m
      memory: 512Mi
```

**Example:**
- Pod requests 100m CPU
- Current usage: 80m CPU
- CPU percentage: (80m / 100m) × 100 = **80%** ← HPA checks this!

### 3. **Target Metric**
HPA makes decisions based on one metric:

```yaml
targetCPUUtilizationPercentage: 80  # Scale when CPU > 80%
# OR
targetMemoryUtilizationPercentage: 70  # Scale when Memory > 70%
# OR custom metrics
```

### 4. **Min/Max Replicas**
```yaml
minReplicas: 2    # Never scale below 2 pods
maxReplicas: 10   # Never scale above 10 pods
```

---

## 📋 HPA YAML Structure

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: k8s-app          # ← Which deployment to scale?
  
  minReplicas: 2           # ← Minimum pods
  maxReplicas: 10          # ← Maximum pods
  
  metrics:
  - type: Resource
    resource:
      name: cpu            # ← Metric to track
      target:
        type: Utilization
        averageUtilization: 80   # ← Scale when this is reached
  
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  
  behavior:               # ← Advanced: how fast to scale
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

---

## 🎯 Common Scenarios

### Scenario 1: Web API with Traffic Spikes

```yaml
minReplicas: 3
maxReplicas: 20
targetCPUUtilizationPercentage: 75

Timeline:
┌─────────────┬────────────────────┬──────────────────┐
│ Time        │ Traffic            │ Replicas         │
├─────────────┼────────────────────┼──────────────────┤
│ 9:00 AM     │ Morning (low)       │ 3 pods           │
│ 12:00 PM    │ Lunch spike! ↑↑↑    │ 6 → 12 → 18 pods │
│ 1:00 PM     │ Peak traffic        │ 20 pods (max)    │
│ 3:00 PM     │ Traffic drops       │ 15 → 10 pods     │
│ 6:00 PM     │ Evening (low)       │ 3 pods           │
└─────────────┴────────────────────┴──────────────────┘
```

### Scenario 2: Batch Processing Job

```yaml
minReplicas: 1           # Start small
maxReplicas: 50          # Go big when needed
targetCPUUtilizationPercentage: 90  # Only scale when REALLY busy

Use case: Processing video uploads, image resizing, data analysis
```

### Scenario 3: Database Read Replicas

```yaml
minReplicas: 2
maxReplicas: 5
targetCPUUtilizationPercentage: 80

Why not higher max? Database connections are limited!
```

---

## 🚀 Step-by-Step HPA Setup

### Step 1: Verify Your Deployment Has Resource Requests

```bash
kubectl get deployment k8s-app -o yaml | grep -A 5 "resources:"

# Must show:
# resources:
#   requests:
#     cpu: 100m
#     memory: 128Mi
```

If your deployment doesn't have resource requests, **add them:**

```bash
kubectl set resources deployment k8s-app \
  --requests=cpu=100m,memory=128Mi \
  --limits=cpu=500m,memory=512Mi
```

### Step 2: Verify Metrics Server is Running

```bash
kubectl get deployment metrics-server -n kube-system

# Should show:
# NAME             READY   UP-TO-DATE   AVAILABLE
# metrics-server   1/1     1            1
```

**Docker Desktop has it built-in!** But if missing:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait 30 seconds for it to start
Start-Sleep -Seconds 30
```

### Step 3: Create HPA for Your Deployment

```bash
kubectl autoscale deployment k8s-app \
  --min=2 \
  --max=10 \
  --cpu-percent=80
```

Or use YAML (better):

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
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
```

### Step 4: Verify HPA is Running

```bash
kubectl get hpa

# Should show:
# NAME       REFERENCE             TARGETS   MINPODS  MAXPODS  REPLICAS
# app-hpa    Deployment/k8s-app    8%/80%    2        10       2

# Check detailed status
kubectl describe hpa app-hpa
```

### Step 5: Generate Load to Test Scaling

```bash
# Terminal 1: Watch pods scale
kubectl get pods --watch

# Terminal 2: Run load test
kubectl run -it --rm load-generator \
  --image=busybox \
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://k8s-app-service; done"

# Watch pods scale up as CPU rises!
# After ~30 seconds, you should see new pods being created

# Stop load test: Ctrl+C
# Watch pods scale back down (takes ~5 minutes)
```

---

## 📊 Understanding HPA Status

```bash
kubectl get hpa

# Output:
# NAME       REFERENCE             TARGETS    MINPODS  MAXPODS  REPLICAS  AGE
# app-hpa    Deployment/k8s-app    45%/80%    2        10       2         5m

# What this means:
# TARGETS: 45%/80% = Current CPU is 45%, target is 80%
#          Since 45% < 80%, no scaling needed
#
# REPLICAS: 2 = Currently running 2 pods
#
# If targets were "92%/80%", it would scale up because 92% > 80%
```

---

## 🐛 Troubleshooting HPA

### HPA Shows `<unknown>/80%`

```bash
# Metrics not available yet
# Solution: Wait 2-3 minutes for metrics to be collected
# Then run: kubectl get hpa

# If still unknown, check:
kubectl get deployment k8s-app -o yaml | grep -A 5 "resources:"

# Must have requests defined!
```

### HPA Not Scaling Despite High CPU

```bash
# Check if HPA is active
kubectl describe hpa app-hpa
# Look for "Events:" section for messages

# Common causes:
# 1. Deployment doesn't have resource requests
#    → Fix: kubectl set resources deployment k8s-app --requests=cpu=100m
#
# 2. Already at maxReplicas
#    → Fix: Increase maxReplicas in HPA
#
# 3. Metrics server down
#    → Fix: kubectl get deployment metrics-server -n kube-system
```

### Pods Won't Scale Down

```bash
# Pods will only scale down after:
# 1. 5 minutes of low CPU (scaleDownStabilizationWindow)
# 2. To prevent flapping (scaling up and down rapidly)

# Manual fix if needed:
# Just wait, or scale manually if urgent:
kubectl scale deployment k8s-app --replicas=2
```

---

## 🎓 Key Takeaways

✅ HPA automatically scales pods based on CPU/Memory
✅ Requires Resource Requests to calculate percentages
✅ Requires Metrics Server to collect metrics
✅ Scales UP quickly, DOWN slowly (to prevent flapping)
✅ Saves money in production (fewer resources when not needed)
✅ Improves user experience (more pods when busy)

---

## Quick Reference Commands

```bash
# Create HPA (simple)
kubectl autoscale deployment k8s-app --min=2 --max=10 --cpu-percent=80

# Get HPA status
kubectl get hpa
kubectl describe hpa app-hpa

# Watch HPA scaling in real-time
kubectl get hpa --watch

# Edit HPA
kubectl edit hpa app-hpa

# Delete HPA
kubectl delete hpa app-hpa

# Generate load for testing
kubectl run -it --rm load-generator --image=busybox \
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://k8s-app-service; done"

# Check metrics
kubectl top nodes
kubectl top pods
```

---

## Next Steps

You have an existing `k8s-app` deployment! We'll:
1. Add resource requests to it
2. Create an HPA
3. Generate load and watch it scale
4. Verify it scales back down

**Ready for the hands-on lab?** Move to [HPA_HANDS_ON.md](HPA_HANDS_ON.md)
