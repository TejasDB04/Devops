# PART 2: CANARY DEPLOYMENT - WITH ISTIO

## Overview

Canary deployment gradually shifts traffic to a new version:
- Deploy v2.0 with 1 pod (5% traffic)
- Monitor metrics closely
- If all good → increase to 50% traffic
- If still good → promote to 100%
- Instant rollback if issues detected

## Why Istio?

Requires fine-grained traffic splitting:
- Split traffic by percentage (5%, 10%, 50%)
- Retry failed requests
- Circuit breaking
- Automatic rollback on error rates

## Prerequisites

```bash
kubectl get nodes                    # Cluster ready
kubectl version --short              # Both client & server required
helm version                         # Helm installed
```

---

## PART 1: Install Istio Service Mesh

### Step 1: Download Istio

```bash
# Download Istio 1.17+ (LTS)
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.17.0
export PATH=$PWD/bin:$PATH
```

### Step 2: Install Istio

```bash
# Verify environment
istioctl verify-install

# Install Istio with default profile
istioctl install --set profile=demo -y

# Enable sidecar injection for default namespace
kubectl label namespace default istio-injection=enabled
```

### Step 3: Verify Installation

```bash
kubectl get pods -n istio-system
# Should see: istiod, ingressgateway, egressgateway pods

kubectl get crd | grep istio
# Should see: virtualservices.networking.istio.io, destinationrules, etc.
```

---

## PART 2: Deploy Stable Version (v1.0 - 100% Traffic)

### Step 1: Create Deployment

```yaml
# app-v1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
  labels:
    app: my-app
    version: v1
spec:
  replicas: 8  # 8 pods for 100% traffic
  selector:
    matchLabels:
      app: my-app
      version: v1
  template:
    metadata:
      labels:
        app: my-app
        version: v1
    spec:
      containers:
      - name: app
        image: k8s-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: VERSION
          value: "v1.0-STABLE"
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

### Step 2: Create Service

```yaml
# app-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
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
    app: my-app  # Selects BOTH v1 and v2!
```

### Step 3: Create Istio VirtualService (100% to v1)

```yaml
# vs-app.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: app-vs
spec:
  hosts:
  - app-service
  http:
  - match: []
    route:
    - destination:
        host: app-service
        subset: v1
      weight: 100  # 100% to v1
    - destination:
        host: app-service
        subset: v2
      weight: 0    # 0% to v2
    timeout: 10s
    retries:
      attempts: 3
      perTryTimeout: 5s
```

### Step 4: Create DestinationRule (Defines subsets)

```yaml
# dr-app.yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: app-dr
spec:
  host: app-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        h2UpgradePolicy: UPGRADE
    loadBalancer:
      simple: ROUND_ROBIN
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

```bash
kubectl apply -f app-v1.yaml app-service.yaml vs-app.yaml dr-app.yaml
kubectl get pods -l app=my-app  # 8 v1 pods running
```

---

## PART 3: Deploy Canary Version (v2.0 - 5% Traffic)

### Step 1: Deploy v2.0

```yaml
# app-v2-canary.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2-canary
  labels:
    app: my-app
    version: v2
spec:
  replicas: 1  # Just 1 pod for canary!
  selector:
    matchLabels:
      app: my-app
      version: v2
  template:
    metadata:
      labels:
        app: my-app
        version: v2
    spec:
      containers:
      - name: app
        image: k8s-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: VERSION
          value: "v2.0-CANARY"
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
kubectl apply -f app-v2-canary.yaml
kubectl get pods  # Should see 8 v1 + 1 v2 pods
```

### Step 2: Update VirtualService (5% to v2)

```bash
# Update VirtualService to send 5% traffic to v2
kubectl patch virtualservice app-vs --type merge -p '
spec:
  http:
  - route:
    - destination:
        host: app-service
        subset: v1
      weight: 95
    - destination:
        host: app-service
        subset: v2
      weight: 5
'
```

---

## PART 4: Monitor Canary (Phase 1: 5%)

```bash
# Setup monitoring
kubectl logs -l version=v2 -f       # Watch v2 logs
kubectl top pods -l version=v2      # Monitor v2 resource usage

# Send traffic and observe
for i in {1..100}; do kubectl exec -it <v1-pod> -- curl http://app-service/; done

# Expected: ~5 requests land on v2, ~95 on v1

# Check metrics for v2
# - Error rate (should be 0)
# - Latency (should match v1)
# - CPU/Memory (should be normal)
```

---

## PART 5: Gradually Increase to 50%

Once confident (5-10 min monitoring):

```bash
# Phase 2: Increase to 50% traffic
kubectl patch virtualservice app-vs --type merge -p '
spec:
  http:
  - route:
    - destination:
        host: app-service
        subset: v1
      weight: 50
    - destination:
        host: app-service
        subset: v2
      weight: 50
'

# Scale up v2 for fairness
kubectl scale deployment app-v2-canary --replicas=4
# Now: 8 v1 + 4 v2 pods (50% traffic)
```

---

## PART 6: Monitor Phase 2 (50%)

```bash
# Continue monitoring v2
kubectl logs -l version=v2 --tail=50
kubectl top pods -l version=v2
kubectl get pods  # Should see 4 v2 pods

# Send more traffic
# Check: error rates, latency, database load
```

---

## PART 7: Full Promotion (100%)

Once v2 is stable for 10+ minutes:

```bash
# Phase 3: Move 100% traffic to v2
kubectl patch virtualservice app-vs --type merge -p '
spec:
  http:
  - route:
    - destination:
        host: app-service
        subset: v1
      weight: 0
    - destination:
        host: app-service
        subset: v2
      weight: 100
'

# Scale down/remove v1
kubectl scale deployment app-v1 --replicas=0
# Or just delete it if confident
```

---

## PART 8: Instant Rollback (If Issues Detected)

If at ANY phase you detect issues:

```bash
# Option A: Immediately revert to 100% v1
kubectl patch virtualservice app-vs --type merge -p '
spec:
  http:
  - route:
    - destination:
        host: app-service
        subset: v1
      weight: 100
    - destination:
        host: app-service
        subset: v2
      weight: 0
'

# Option B: Scale down v2, delete pods
kubectl scale deployment app-v2-canary --replicas=0

# Option C: Instant verification
kubectl exec <v1-pod> -- curl http://app-service/
# Should get v1.0-STABLE response
```

---

## Complete Canary Workflow Timeline

```
10:00 AM - PHASE 1: Launch Canary
  Deploy v2.0: 1 pod
  Traffic split: v1=95%, v2=5%
  Monitor: Error rates, latency, logs
  ✓ All metrics normal

10:10 AM - PHASE 2: Growing Confidence
  Increase traffic: v1=50%, v2=50%
  Scale v2: 1 → 4 pods
  Monitor: Broader real-user base
  ✓ Latency slightly better, fewer errors

10:20 AM - PHASE 3: Full Promotion
  Move traffic: v1=0%, v2=100%
  Scale v1: 8 → 0 pods
  Delete v1 deployment
  v2.0 is now the stable version!

10:25 AM - COMPLETE
  v2.0 serving 100% of production traffic
  Gradual rollout took 25 minutes
  v1.0 is decommissioned
```

---

## Decision Tree

```
Deploy v2.0 canary (1 pod, 5%)
│
├─→ Errors high? YES → ROLLBACK (instant to v1=100%)
│
├─→ Latency worse? YES → ROLLBACK
│
├─→ CPU spike? YES → Hold at 5%, investigate
│
└─→ All good? → Increase to 50%
    │
    ├─→ Still good for 5 min? YES → Increase to 100%
    │   │
    │   ├─→ Error dashboard red? → ROLLBACK
    │   │
    │   └─→ All clear? → PROMOTION COMPLETE
    │
    └─→ Issues at 50%? → ROLLBACK to 100% v1
```

---

## Istio Features Used

| Feature | Purpose | Benefit |
|---------|---------|---------|
| **VirtualService** | Split traffic by weight | Gradual shifing |
| **DestinationRule** | Define subsets (v1, v2) | Load balancing rules |
| **Retry Policy** | Automatic retry on failure | Resilience to transient errors |
| **Timeout** | Request timeout settings | Prevent hanging requests |
| **LoadBalancer** | ROUND_ROBIN distribution | Even traffic spread |

---

## Canary vs Blue-Green

| Aspect | Canary | Blue-Green |
|--------|--------|-----------|
| **Blast Radius** | 5% initially | 100% instantly |
| **Rollback** | Few seconds | 1-2 seconds |
| **Real User Testing** | YES | NO (pre-tested) |
| **Resource Cost** | Gradual increase | 2x during deploy |
| **Complexity** | Higher (needs Istio) | Simple (service selector) |
| **Risk Level** | Lower | Very low (but all-or-nothing) |
| **Best For** | Complex changes | Quick, verified deploys |

---

## Real-World Canary Timeline

```
Database Schema Migration:
  Backward compatible?
  - Blue-Green: Deploy with new schema, switch, done
  - Canary: Send 5% traffic (real queries), monitor DB, grow

Feature Rollout:
  Algorithm changed?
  - Blue-Green: Test everything, switch, done
  - Canary: 5% users test new algorithm, monitor results grows

Payment Gateway Update:
  Critical system?
  - Blue-Green: Full testing sandbox, switch if perfect
  - Canary: 5% of transactions use new gateway, monitor error rates
```

---

## Manual vs Automated Canary

### Manual (This Lab)
```bash
# You decide when to increase %
# kubectl patch virtualservice ...
# Monitor dashboards
# kubectl patch again
```

### Automated (Flagger)
```yaml
# Flagger watches metrics, auto-promotes
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: app
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  progressDeadlineSeconds: 60
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
```

---

## Next Steps

After this lab, you'll understand:
✅ How to deploy new versions safely
✅ How Istio enables traffic management
✅ Manual vs automated canary workflows
✅ When to use Blue-Green vs Canary

Ready to start?
