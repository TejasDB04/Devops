# 🚀 HPA - Quick Commands Summary

## 📋 One-Line Setup (Copy & Paste)

### Step 1: Add Resource Requests
```powershell
kubectl set resources deployment k8s-app --requests=cpu=100m,memory=128Mi --limits=cpu=500m,memory=512Mi
```

### Step 2: Verify Metrics Server
```powershell
kubectl get deployment metrics-server -n kube-system
# Should show "1/1" ready
```

### Step 3: Create HPA
```powershell
kubectl autoscale deployment k8s-app --min=2 --max=10 --cpu-percent=80
```

### Step 4: Check Status
```powershell
kubectl get hpa
kubectl describe hpa app-hpa
```

### Step 5: Generate Load (Test Scaling UP)
```powershell
kubectl run -it --rm load-generator --image=busybox -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://k8s-app-service; done"
```

### Step 6: Watch Scaling (Open 2nd Terminal)
```powershell
kubectl get pods -l app=k8s-app --watch
kubectl get hpa --watch
```

### Step 7: Stop Load (Ctrl+C) and Watch Scale Down
```
# Pods will scale down after ~5 minutes
# Watch with: kubectl get hpa --watch
```

---

## 🔧 Common Commands

```powershell
# ============================================
# CREATE HPA
# ============================================

# Simple (1-line)
kubectl autoscale deployment k8s-app --min=2 --max=10 --cpu-percent=80

# With YAML file
kubectl apply -f hpa-k8s-app.yaml


# ============================================
# CHECK HPA STATUS
# ============================================

# List all HPA
kubectl get hpa

# Detailed info
kubectl describe hpa app-hpa

# Real-time watch
kubectl get hpa --watch


# ============================================
# CHECK METRICS
# ============================================

# Pod metrics
kubectl top pods -l app=k8s-app

# Node metrics
kubectl top nodes

# Check metrics-server
kubectl get deployment metrics-server -n kube-system


# ============================================
# EDIT HPA
# ============================================

# Edit in editor
kubectl edit hpa app-hpa

# Change min/max replicas
kubectl patch hpa app-hpa -p '{"spec":{"minReplicas":1,"maxReplicas":20}}'


# ============================================
# DELETE HPA
# ============================================

kubectl delete hpa app-hpa


# ============================================
# SET RESOURCE REQUESTS
# ============================================

# Add to existing deployment
kubectl set resources deployment k8s-app --requests=cpu=100m,memory=128Mi --limits=cpu=500m,memory=512Mi

# Verify resources
kubectl get deployment k8s-app -o yaml | grep -A 10 "resources:"


# ============================================
# LOAD TESTING
# ============================================

# Generate HTTP load
kubectl run -it --rm load-generator --image=busybox -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://k8s-app-service; done"

# With Apache Bench (faster)
kubectl run -it --rm load-test --image=httpd:tools -- ab -n 10000 -c 100 http://k8s-app-service/

# With hey tool
kubectl run -it --rm load-test --image=williamyeh/hey -- -z 5m -c 50 http://k8s-app-service/


# ============================================
# SCALE MANUALLY (if needed)
# ============================================

kubectl scale deployment k8s-app --replicas=5


# ============================================
# VIEW HPA EVENTS
# ============================================

kubectl describe hpa app-hpa | grep -A 20 "Events:"

# Or watch for events
kubectl get events --field-selector involvedObject.name=app-hpa --watch
```

---

## 📊 Understanding HPA Output

```
kubectl get hpa

Output:
NAME       REFERENCE             TARGETS    MINPODS  MAXPODS  REPLICAS  AGE
app-hpa    Deployment/k8s-app    45%/80%    2        10       2         1m

Breakdown:
├─ NAME: app-hpa
│  └─ Name of the HorizontalPodAutoscaler
│
├─ REFERENCE: Deployment/k8s-app
│  └─ Which deployment it's scaling
│
├─ TARGETS: 45%/80%
│  ├─ 45% = Current average CPU of all pods
│  └─ 80% = Target CPU (scale when above this)
│     └─ If 45% < 80%, NO SCALING NEEDED
│     └─ If 95% > 80%, SCALE UP!
│
├─ MINPODS: 2
│  └─ Never go below 2 pods
│
├─ MAXPODS: 10
│  └─ Never go above 10 pods
│
└─ REPLICAS: 2
   └─ Currently running 2 pods
```

---

## 🚨 HPA Status Meanings

| TARGETS | Action | Reason |
|---------|--------|--------|
| `<unknown>/80%` | WAITING | Metrics not ready yet (wait 1-2 min) |
| `20%/80%` | NONE | CPU below target, no action |
| `80%/80%` | NONE | At target, stable |
| `85%/80%` | SCALE UP | CPU above target, increasing replicas |
| `50%/80%` | SCALE DOWN | CPU way below, decreasing replicas (slow) |

---

## 🎯 Real-World Example Walkthrough

### Initial State
```
kubectl get hpa
NAME       REFERENCE             TARGETS   MINPODS  MAXPODS  REPLICAS  AGE
app-hpa    Deployment/k8s-app    10%/80%   2        10       2         5m

Status: 2 pods running, 10% CPU (very light load)
```

### High Traffic Hits
```
# Someone runs: while true; do curl http://app; done

# 15 seconds later:
app-hpa    Deployment/k8s-app    92%/80%   2        10       2         5m

Status: CPU jumped to 92% (above 80% target!)
Action: HPA will scale UP
Calculation: 2 × (92/80) = 2.3 → Scale to 3 pods
```

### After Scale UP
```
# 30 seconds later:
app-hpa    Deployment/k8s-app    70%/80%   2        10       3         5m30s

Status: Now 3 pods handling traffic
CPU: 92% total → Divided across 3 = ~31% per pod
Action: CPU is below target now, but WAIT (stabilization window)
```

### Traffic Drops
```
# 5 minutes later:
app-hpa    Deployment/k8s-app    20%/80%   2        10       2         10m

Status: Traffic stopped, CPU dropped to 20%
Action: Scale DOWN to minimum (2 pods)
Result: Cost savings! Using only 2 pods instead of 3
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `<unknown>/80%` | Wait 1-2 min for metrics. If still: `kubectl set resources deployment k8s-app --requests=cpu=100m` |
| Pods not scaling | Check: `kubectl describe hpa app-hpa` for errors |
| Pods won't scale down | Normal! HPA waits 5 min. Or: `kubectl scale deployment k8s-app --replicas=2` |
| Already at maxReplicas | Increase maxReplicas: `kubectl edit hpa app-hpa` |
| Metrics server missing | Install: `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml` |

---

## 📈 Advanced: Custom YAML with Fine-Tuning

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
  # CPU-based scaling
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  
  # Memory-based scaling
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0      # Scale UP immediately
      policies:
      - type: Percent
        value: 100                        # Double pods each time
        periodSeconds: 15                 # Check every 15 sec
      - type: Pods
        value: 4                          # Or add 4 pods max
        periodSeconds: 15
      selectPolicy: Max                   # Use whichever adds more
    
    scaleDown:
      stabilizationWindowSeconds: 60     # Wait 60 sec before scaling down
      policies:
      - type: Percent
        value: 50                         # Remove 50% of pods
        periodSeconds: 30                 # Check every 30 sec
      selectPolicy: Min                   # Remove fewest pods (conservative)
```

---

## ✅ Verification Checklist

Before claiming success:

```
SETUP
[ ] kubectl set resources applied to k8s-app
[ ] kubectl get deployment k8s-app shows resource requests
[ ] kubectl get deployment metrics-server shows Running
[ ] kubectl get hpa shows app-hpa

TESTING
[ ] kubectl get hpa shows numeric TARGETS (not <unknown>)
[ ] Load test started: kubectl run ... load-generator
[ ] kubectl get pods -l app=k8s-app shows 3+ pods
[ ] kubectl get hpa shows TARGETS like "92%/80%"
[ ] REPLICAS increased from 2 to more

SCALE DOWN
[ ] Stopped load generator (Ctrl+C)
[ ] Waited 5+ minutes
[ ] kubectl get hpa shows TARGETS like "20%/80%"
[ ] REPLICAS decreased back to 2
```

---

## 🎓 Key Takeaways

- **HPA** = Automatic scaling based on metrics
- **Resource Requests** = Required for HPA to calculate percentages
- **Metrics Server** = Collects CPU/Memory data (pre-installed in Docker Desktop)
- **Scale UP** = Fast (30 seconds) when CPU > target
- **Scale DOWN** = Slow (5 minutes) to prevent flapping
- **Cost Savings** = Fewer pods when not needed
- **Performance** = More pods when busy

**Next topic:** Monitoring & Observability (Prometheus + Grafana)
