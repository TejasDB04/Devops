# PART 1: BLUE-GREEN DEPLOYMENT - HANDS-ON LAB

## Overview

You'll deploy an application in Blue-Green pattern:
- **Blue**: Current production version (v1.0)
- **Green**: New version being tested (v2.0)
- **Switch**: Instantly flip traffic from blue to green
- **Rollback**: Instant revert if issues detected

## Prerequisites

✅ kubectl configured
✅ Kubernetes cluster running (Docker Desktop)
✅ Understand Kubernetes Services & Deployments

---

## PART 1: Create Namespace

```bash
kubectl create namespace blue-green
kubectl config set-context --current --namespace=blue-green
```

---

## PART 2: Deploy BLUE (v1.0 - Current Production)

### Step 1: Create Blue Deployment

```yaml
# blue-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
  namespace: blue-green
  labels:
    app: my-app
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
      version: blue
  template:
    metadata:
      labels:
        app: my-app
        version: blue
    spec:
      containers:
      - name: app
        image: k8s-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: VERSION
          value: "v1.0-BLUE"
        - name: COLOR
          value: "BLUE"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
kubectl apply -f blue-deployment.yaml
```

### Step 2: Create Service (Points to BLUE)

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
  namespace: blue-green
  labels:
    app: my-app
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: my-app
    version: blue  # ← Key: Points to BLUE only
```

```bash
kubectl apply -f service.yaml
```

### Step 3: Verify BLUE is running

```bash
kubectl get pods -n blue-green -l version=blue
kubectl get svc -n blue-green
kubectl get endpoints app-service -n blue-green
```

Expected output: 3 pods running, service endpoints pointing to blue pods

---

## PART 3: Deploy GREEN (v2.0 - No Traffic Yet)

### Step 1: Create Green Deployment

```yaml
# green-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
  namespace: blue-green
  labels:
    app: my-app
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
      version: green
  template:
    metadata:
      labels:
        app: my-app
        version: green
    spec:
      containers:
      - name: app
        image: k8s-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: VERSION
          value: "v2.0-GREEN"
        - name: COLOR
          value: "GREEN"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
kubectl apply -f green-deployment.yaml
```

### Step 2: Verify GREEN is running (but NO traffic)

```bash
kubectl get pods -n blue-green -l version=green
kubectl get endpoints app-service -n blue-green  # Should show only BLUE endpoints
```

Expected: 3 green pods running, but service doesn't route to them yet

---

## PART 4: Validate GREEN (Smoke Tests)

### Step 1: Direct test GREEN (without service)

```bash
# Get a green pod
GREEN_POD=$(kubectl get pods -n blue-green -l version=green -o jsonpath='{.items[0].metadata.name}')

# Test green directly (bypassing service)
kubectl exec -it $GREEN_POD -n blue-green -- curl -s http://localhost:3000/

# Expected response: VERSION: v2.0-GREEN, COLOR: GREEN
```

### Step 2: Run smoke tests against GREEN

```bash
# Port-forward to green pod (test in isolation)
kubectl port-forward -n blue-green pod/$GREEN_POD 3000:3000 &
# In another window: curl http://localhost:3000/
# Kill port-forward when done
```

### Step 3: Once validated, proceed to traffic switch

---

## PART 5: Switch Traffic from BLUE to GREEN

### Critical Step: Update Service Selector

```bash
# Option 1: Using kubectl patch (quickest)
kubectl patch service app-service -n blue-green \
  -p '{"spec":{"selector":{"version":"green"}}}'

# Option 2: Using kubectl edit (your chance to review first)
# kubectl edit svc app-service -n blue-green
# Change: version: blue → version: green
```

### Verify Switch Happened

```bash
# Check endpoints updated
kubectl get endpoints app-service -n blue-green
# Should now show GREEN pod IPs only

# Check service still works
kubectl get svc -n blue-green

# Test traffic reaches GREEN
BLUE_POD=$(kubectl get pods -n blue-green -l version=blue -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $BLUE_POD -n blue-green -- curl -s http://app-service/
# Response should come from GREEN now!
```

---

## PART 6: Monitor GREEN in Production

After switching, monitor these metrics:
- **Error rates** (should stay low or drop)
- **Response latency** (should not increase)
- **CPU/Memory usage** (should be normal)
- **Business metrics** (transactions, conversions)

```bash
# Watch pod restarts/errors
kubectl get pods -n blue-green -w

# Check logs for errors
kubectl logs -n blue-green -l version=green --tail=20

# Check resource usage
kubectl top pods -n blue-green
```

---

## PART 7: Rollback if Issues (Keep BLUE Running!)

If GREEN fails, instantly rollback:

### Quick Rollback Steps

```bash
# Plan A: Switch service back to BLUE immediately
kubectl patch service app-service -n blue-green \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# Plan B: If BLUE pods crashed, scale GREEN back to 0
kubectl scale deployment app-green -n blue-green --replicas=0
kubectl scale deployment app-blue -n blue-green --replicas=3

# Plan C: If database transaction failed, restore from backup
# (your backup strategy here)
```

### Verification

```bash
# Confirm back to BLUE
kubectl get endpoints app-service -n blue-green  # Should show BLUE IPs again
curl http://app-service/  # Should get v1.0-BLUE response
```

---

## PART 8: Cleanup (After GREEN Stabilizes)

After 24-48 hours of successful GREEN operation:

```bash
# Delete OLD BLUE deployment
kubectl delete deployment app-blue -n blue-green

# Relabel GREEN as now being the "current" version
# (optional, for clarity)
kubectl label deployment app-green -n blue-green version=current --overwrite
```

---

## Complete Blue-Green Workflow Diagram

```
0. INITIAL STATE
┌─────────────────────────┐
│ Service → [BLUE pods]   │
│         (3 running)     │
└─────────────────────────┘

1. DEPLOY GREEN (parallel)
┌─────────────────────────┐
│ Service → [BLUE pods]   │
│ (still here)            │
│                         │
│ [GREEN pods]            │
│ (deployed, no traffic)  │
└─────────────────────────┘

2. VALIDATE GREEN (offline tests)
GREEN pod status: ✓ Running
Network access: ✓ Works
Health checks: ✓ Pass
Smoke tests: ✓ OK

3. SWITCH SERVICE SELECTOR
Before: selector → version: blue
After:  selector → version: green

4. INSTANT TRAFFIC SWITCH
┌─────────────────────────┐
│ Service → [GREEN pods]  │
│         (3 running)     │
│                         │
│ [BLUE pods] ← old, can  │
│ (still here) delete     │
└─────────────────────────┘

5. MONITOR PRODUCTION
- Error rates ✓
- Latency ✓
- Database ✓
- CPU/Memory ✓

6. DECISION
A) GREEN stable → Delete BLUE
B) GREEN has issues → Rollback to BLUE (instant)

7. CLEANUP
Delete BLUE, keep GREEN as new stable
```

---

## Command Quick Reference

```bash
# Setup
kubectl create namespace blue-green
kubectl config set-context --current --namespace=blue-green

# Deploy BLUE
kubectl apply -f blue-deployment.yaml
kubectl apply -f service.yaml

# Deploy GREEN
kubectl apply -f green-deployment.yaml

# Validate
kubectl get pods -l version=blue
kubectl get pods -l version=green
kubectl get endpoints app-service

# Switch Traffic
kubectl patch service app-service -p '{"spec":{"selector":{"version":"green"}}}'

# Test
kubectl exec <blue-pod> -- curl http://app-service/

# Rollback
kubectl patch service app-service -p '{"spec":{"selector":{"version":"blue"}}}'

# Cleanup
kubectl delete deployment app-blue
```

---

## Key Benefits Demonstrated

✅ **Zero Downtime**: Service never unavailable during switch
✅ **Instant Rollback**: Switch back in 2 seconds if issues
✅ **Full Testing**: Test GREEN 100% before exposing to users
✅ **Resource Control**: Know exact resource needs (2x during deployment)
✅ **Simple Implementation**: Works with vanilla Kubernetes
✅ **Easy to Understand**: Everyone sees it (visual)

---

## Next: Canary Deployment

Once you're comfortable with Blue-Green, we'll show Canary:
- Gradual traffic shift (10% → 50% → 100%)
- Real-user validation
- Requires Istio or similar traffic mesh
- More sophisticated but higher risk mitigation

Ready to implement this lab?
