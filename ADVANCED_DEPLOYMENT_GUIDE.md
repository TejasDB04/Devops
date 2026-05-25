# 🚀 Advanced Deployment Strategies - Blue-Green & Canary

Zero-downtime deployments! Release new versions safely.

---

## The Problem: Traditional Deployments

```
OLD VERSION (v1.0) RUNNING
         ↓
kubectl apply -f deployment.yaml  (Deploy v2.0)
         ↓
ALL PODS STOP & RESTART (downtime! 😱)
         ↓
v2.0 has a bug!
         ↓
kubectl apply -f old-version.yaml (Rollback)
         ↓
Users angry 😠
```

---

## Solution 1: Blue-Green Deployment

**Concept:** Two identical environments, switch traffic instantly!

```
BLUE (v1.0) Running        GREEN (v2.0) Testing
┌──────────────┐           ┌──────────────┐
│ 3 Pods v1.0  │◄─────────┤ 3 Pods v2.0  │
└──────────────┘   Traffic └──────────────┘
   (Active)        Routed    (Standby)
                  by Service

User: "Everything works fine"

        ↓ Deploy v2.0 to GREEN

BLUE (v1.0) Running        GREEN (v2.0) Ready
┌──────────────┐           ┌──────────────┐
│ 3 Pods v1.0  │           │ 3 Pods v2.0  │
└──────────────┘           └──────────────┘
   (Standby)               (Active)
                   Switch! ↓

        SERVICE POINTS TO GREEN

Users instantly on v2.0 ✅
OLD VERSION STILL RUNNING (instant rollback!)

        ↓ 1 hour passes, no issues

DELETE BLUE (v1.0)
```

### How It Works

```yaml
# Service (routes traffic)
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    version: blue  # ← Points to blue deployment!
  ports:
  - port: 80
    targetPort: 3000

---
# BLUE DEPLOYMENT (v1.0)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: myapp
        image: myapp:v1.0  # Version 1

---
# GREEN DEPLOYMENT (v2.0) - Initially stopped
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  replicas: 0  # ← Not running yet!
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0  # Version 2
```

**Deployment process:**
```powershell
# Step 1: Scale up green (v2.0)
kubectl patch deployment myapp-green -p '{"spec":{"replicas":3}}'

# Step 2: Wait for health checks
kubectl get pods -l version=green  # Wait for Ready!

# Step 3: Test! (port-forward and test)
kubectl port-forward svc/myapp-green 8000:80
# Visit http://localhost:8000, test everything

# Step 4: Switch traffic
kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'

# Step 5: Users now on v2.0! ✅

# Step 6: Keep blue running for 1 hour (instant rollback option)

# Step 7: If no issues, delete blue
kubectl patch deployment myapp-blue -p '{"spec":{"replicas":0}}'
```

---

## Solution 2: Canary Deployment

**Concept:** Release to 5% of users first, then more!

```
v1.0 (95% of traffic)      v2.0 (5% of traffic)
┌──────────────┐           ┌──────────────┐
│ 19 Pods      │           │ 1 Pod        │
│ Old Version  │◄─────────┤│ New Version  │
└──────────────┘   Service └──────────────┘
              Routes traffic proportionally

User 1-95: "Using v1.0 (stable)"
User 96-100: "Using v2.0 (canary)"

Monitor metrics for v2.0:
- No errors? ✅
- Performance OK? ✅
  ↓
Scale to 25% of users (5 pods v2.0, 15 pods v1.0)

Still no issues?
  ↓
Scale to 50% (10 pods v2.0, 10 pods v1.0)

  ↓
100% on v2.0 ✅
```

### How It Works

```yaml
# Both deployments running!
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-v1
spec:
  replicas: 19  # 95% of traffic
  selector:
    matchLabels:
      app: myapp
      version: v1
  template:
    metadata:
      labels:
        app: myapp
        version: v1
    spec:
      containers:
      - name: myapp
        image: myapp:v1.0

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-v2
spec:
  replicas: 1  # 5% of traffic (canary)
  selector:
    matchLabels:
      app: myapp
      version: v2
  template:
    metadata:
      labels:
        app: myapp
        version: v2
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0

---
# Service routes to both!
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp  # ← Matches BOTH v1 AND v2!
  ports:
  - port: 80
    targetPort: 3000
```

**Canary process:**
```powershell
# Step 1: Deploy v2.0 with 1 replica
kubectl apply -f myapp-v2-canary.yaml

# Step 2: Monitor metrics
# Set up alerts on v2.0 errors, latency, memory

# Step 3: If OK after 15 minutes, scale up
kubectl patch deployment myapp-v2 -p '{"spec":{"replicas":5}}'
kubectl patch deployment myapp-v1 -p '{"spec":{"replicas":15}}'

# Step 4: Monitor for 30 minutes

# Step 5: If still OK, scale more
kubectl patch deployment myapp-v2 -p '{"spec":{"replicas":10}}'
kubectl patch deployment myapp-v1 -p '{"spec":{"replicas":10}}'

# Step 6: 100% on v2.0
kubectl patch deployment myapp-v2 -p '{"spec":{"replicas":20}}'
kubectl patch deployment myapp-v1 -p '{"spec":{"replicas":0}}'

# Step 7: Delete v1.0
kubectl delete deployment myapp-v1
```

---

## Blue-Green vs Canary

| Aspect | Blue-Green | Canary |
|--------|-----------|--------|
| **Rollover Speed** | Instant | Gradual (30 min - 2 hours) |
| **Risk** | Higher (instant switch) | Lower (slow rollout) |
| **Rollback** | Instant (keep blue running) | Instant (revert replicas) |
| **Resource Usage** | 2x during deployment | Same + canary pods |
| **Best For** | Critical fixes, coordinated releases | Features, experimental changes |
| **User Impact** | Everyone switches at once | Some users on new version |
| **Testing** | Full before switch | Real users test it! |

---

## Real World: Istio Service Mesh (Advanced)

More control with **weighted traffic routing:**

```yaml
# Route 90% to v1, 10% to v2
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: myapp
        port:
          number: 80
        subset: v1
      weight: 90
    - destination:
        host: myapp
        port:
          number: 80
        subset: v2
      weight: 10  # Canary!
```

---

## 🎯 When to Use Each

**Use Blue-Green for:**
- Database migrations (need instant rollback)
- Major feature releases
- Time-sensitive deployments
- Critical security patches

**Use Canary for:**
- New features (test with real users)
- Performance changes
- UI updates
- API changes (gradual migration)

**Use Rolling Update (default) for:**
- Small patches
- Non-critical services
- When downtime is acceptable

---

## 📊 Complete Deployment Strategy

```
┌─────────────────────────────────────────────┐
│        Deployment Checklist                 │
├─────────────────────────────────────────────┤
│ 1. Build image: docker build                │
│ 2. Push to registry: docker push            │
│ 3. Deploy to staging: Blue-Green            │
│ 4. Test thoroughly (functional + load)      │
│ 5. Deploy to production: Canary             │
│ 6. Monitor metrics (errors, latency, CPU)   │
│ 7. Gradually increase traffic               │
│ 8. Full rollover when confident             │
│ 9. Keep old version for 24 hours (backup)   │
│ 10. Archive metrics for analysis            │
└─────────────────────────────────────────────┘
```

---

## 🚀 Tools That Help

**Flagger** - Automated canary deployments
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  progressDeadlineSeconds: 300
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 5
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
```

**Argo Rollouts** - Sophisticated deployment strategies

**GitOps + Helm** - Version control your deployments

---

## 💡 Key Points

✅ **Blue-Green:** Instant switch, instant rollback, 2x resources  
✅ **Canary:** Safe gradual rollout, real user testing, normal resources  
✅ **Monitor closely:** Have alerts on errors, latency, resource usage  
✅ **Have rollback plan:** Keep old version running  
✅ **Test staging first:** Blue-Green in staging before production canary  

---

## Next Steps

**Recommended order for last 3 topics:**
1. ✅ Advanced Deployment (YOU ARE HERE)
2. 🎯 **GitOps with ArgoCD** (Automate deployments)
3. 🔄 **Backup & Disaster Recovery** (Protect data)

Ready for GitOps? 🚀
