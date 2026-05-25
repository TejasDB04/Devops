# 🚀 ADVANCED DEPLOYMENT STRATEGIES GUIDE

## The Problem with Traditional Deployments

```
Rolling Update (Default Kubernetes):
Time  0s:  [Pod-v1] [Pod-v1] [Pod-v1]  ← 3 pods running v1
Time  5s:  [Pod-v2] [Pod-v1] [Pod-v1]  ← New v2 pod starting, old still running
Time 10s:  [Pod-v2] [Pod-v2] [Pod-v1]  ← But if v2 is broken...
Time 15s:  [Pod-v2] [Pod-v2] [Pod-v2]  ← All broken! No quick rollback path!
```

**Risk Factors:**
- ❌ Partial outage (some requests go to broken v2)
- ❌ No instant rollback (pods already updated)
- ❌ Mixed versions simultaneously (edge cases!)
- ❌ Gradual & uncontrollable (can't halt deployment)

---

## Solution 1: BLUE-GREEN DEPLOYMENT

### Concept

```
BEFORE DEPLOYMENT:
┌─────────────────────────────────────────────────────────────┐
│ Load Balancer / Service                                     │
│             ↓                                               │
│      ┌──────────────────┐                                   │
│      │  BLUE (v1.0)     │ ← Users traffic here              │
│      └──────────────────┘                                   │
│        - 3 pods running                                     │
│        - Stable, tested                                     │
│        - In production                                      │
└─────────────────────────────────────────────────────────────┘

DURING DEPLOYMENT:
┌─────────────────────────────────────────────────────────────┐
│ Load Balancer / Service                                     │
│             ↓                                               │
│      ┌──────────────────┐                                   │
│      │  BLUE (v1.0)     │ ← Still here, production active   │
│      └──────────────────┘                                   │
│                                                             │
│      ┌──────────────────┐                                   │
│      │  GREEN (v2.0)    │ ← Deployed, tested, NO TRAFFIC    │
│      └──────────────────┘  (parallel environment)           │
│        - 3 pods warming up                                  │
│        - Running smoke tests                                │
│        - Ready to accept traffic                            │
└─────────────────────────────────────────────────────────────┘

AFTER VALIDATION:
┌─────────────────────────────────────────────────────────────┐
│ Load Balancer / Service                                     │
│             ↓                                               │
│      ┌──────────────────┐                  ┌──────────────┐ │
│      │  BLUE (v1.0)     │ ← Old, can       │ Terminating  │ │
│      └──────────────────┘   remove later   └──────────────┘ │
│                                                             │
│      ┌──────────────────┐                                   │
│      │  GREEN (v2.0)    │ ← ALL traffic HERE NOW!           │
│      └──────────────────┘   Instant, 100% switch            │
│        - Live, serving users                                │
│        - Version 2.0 fully active                           │
└─────────────────────────────────────────────────────────────┘

ROLLBACK (if needed):
Just switch load balancer from Green → Blue. Instant!
```

### Characteristics

| Aspect | Value |
|--------|-------|
| **Risk Level** | 🟢 Very Low (instant rollback) |
| **Downtime** | 0 (zero) |
| **Resource Cost** | 🔴 High (2x pods during deployment) |
| **Complexity** | 🟢 Simple (just switch) |
| **Testing** | Full environment testing possible |
| **Rollback Speed** | Instant (1-2 seconds) |
| **Best For** | Critical apps, fast rollback needed |

### Implementation Steps

1. **Deploy GREEN alongside BLUE**
   - Blue: v1.0 (current production) - 3 pods
   - Green: v2.0 (new version) - 3 pods running
   - Traffic still to Blue only

2. **Test GREEN completely**
   - Run smoke tests
   - Load tests
   - Integration tests
   - All against Green, ZERO production traffic

3. **Switch traffic from BLUE to GREEN**
   - Update Service selector: `app: my-app, version: green`
   - Traffic instantly switches
   - ALL users on v2.0 now

4. **Monitor GREEN**
   - Watch metrics, errors, latency
   - If OK → keep Green, delete Blue
   - If broken → **switch back instantly** (Blue still running!)

5. **Cleanup**
   - After 24-48 hours: delete Blue (old version)
   - Keep as safety net while new version stabilizes

---

## Solution 2: CANARY DEPLOYMENT

### Concept

```
PHASE 1: 10% CANARY (Early Bird Testing)
┌────────────────────────────────────────┐
│ Service Load Balancer                  │
│     90% ↓              10% ↓            │
│  ┌──────────────┐  ┌──────────────┐    │
│  │  STABLE      │  │  CANARY      │    │
│  │  (v1.0)      │  │  (v2.0)      │    │
│  │  9 pods      │  │  1 pod       │    │
│  └──────────────┘  └──────────────┘    │
│  - Proven, reliable  - New version     │
│  - 90% traffic       - 10% traffic     │
│                     - Real users!      │
│  "Is v2 breaking anything?"            │
└────────────────────────────────────────┘

PHASE 2: 50% CANARY (Confidence Growing)
┌────────────────────────────────────────┐
│ Service Load Balancer                  │
│     50% ↓              50% ↓            │
│  ┌──────────────┐  ┌──────────────┐    │
│  │  v1.0        │  │  v2.0        │    │
│  │  5 pods      │  │  5 pods      │    │
│  └──────────────┘  └──────────────┘    │
│  50% traffic       50% traffic         │
│  "Metrics look good, let's do 50/50"   │
└────────────────────────────────────────┘

PHASE 3: 100% STABLE (Full Deployment)
┌────────────────────────────────────────┐
│ Service Load Balancer                  │
│            100% ↓                       │
│         ┌──────────────┐                │
│         │  v2.0        │                │
│         │  10 pods     │                │
│         └──────────────┘                │
│         ALL traffic                     │
│         v1.0 decommissioned             │
└────────────────────────────────────────┘
```

### Characteristics

| Aspect | Value |
|--------|-------|
| **Risk Level** | 🟡 Medium-Low (limited blast radius) |
| **Downtime** | 0 (zero) |
| **Resource Cost** | 🟡 Medium (gradual increase) |
| **Complexity** | 🟠 Moderate (needs traffic splitting) |
| **Testing** | Real-user feedback during deployment |
| **Rollback Speed** | Fast (but not instant) |
| **Best For** | Data-critical apps, gradual validation |

### Implementation Steps

1. **Deploy v2.0 with small replica count**
   - v1.0: 9 replicas (90% traffic)
   - v2.0: 1 replica (10% traffic)
   - Real users hit both versions

2. **Monitor v2.0 in production**
   - Error rates
   - Latency increase
   - Database issues
   - Memory/CPU usage
   - Business metrics (conversions, etc.)

3. **Gradual traffic increase**
   - Phase 1: 10% → monitoring
   - Phase 2: 50% → if metrics good
   - Phase 3: 100% → if all checks pass
   - Can halt at any phase!

4. **Progressive rollout timeline**
   ```
   10:00 AM  - Deploy v2.0 (1 pod), 10% traffic
   10:10 AM  - Check metrics, all good
   10:15 AM  - Increase to 50% (5 pods)
   10:20 AM  - Final checks, all systems green
   10:25 AM  - 100% traffic (delete v1.0)
   ```

5. **Instant rollback if issue detected**
   - Issue spotted in Phase 1? → Revert to 100% v1.0 (instant)
   - Issue in Phase 2? → Revert to 100% v1.0 (instant)
   - Traffic routing takes 2-5 seconds to update

---

## Comparison: Blue-Green vs Canary

| Feature | Blue-Green | Canary |
|---------|-----------|--------|
| **Downtime** | 0 | 0 |
| **Rollback Speed** | Instant (1-2 sec) | Fast (2-5 sec) |
| **Resource Overhead** | 2x (both versions) | 1.x (gradual) |
| **Risk Exposure** | All-at-once switch | Gradual, limited |
| **Validation Method** | Pre-deployment testing | Real-user monitoring |
| **Complexity** | Simple | Requires traffic mesh |
| **Best For** | Quick deployments, easy rollback | Complex apps, data-sensitive |
| **Blast Radius** | 100% on switch | 10-50% during test |
| **Traffic Mesh Needed** | Maybe (can use Service) | YES (Istio, Linkerd, etc.) |

---

## Implementation Technologies

### Blue-Green Deployment
Tools:
- **Native Kubernetes**: Service selector switching + multiple Deployments
- **Load Balancers**: AWS ALB, GCP LB (switch target groups)
- **Helm**: Deploy via different releases

Simplest approach: Manual service selector update

### Canary Deployment
Tools:
- **Istio** (Most advanced)
  - Fine-grained traffic splitting (5%, 10%, 50%)
  - Automatic rollback on metrics
  - Excellent observability

- **Flagger** (Automated canary)
  - GitOps-friendly
  - Automatic promotion/rollback
  - Works with Istio, Linkerd

- **Linkerd** (Simpler, lighter)
  - Built-in traffic splitting
  - Lower resource footprint

---

## Real-World Scenarios

### When to Use Blue-Green
✅ **E-commerce checkout**
- Database schema changed
- Need instant back-to-v1
- Rare deployments, worth 2x resources

✅ **Payment processing**
- Zero tolerance for issues
- Want instant rollback
- Complex infrastructure

### When to Use Canary
✅ **Mobile app backend**
- Backward compatible changes
- Want real-user validation
- Monitor client SDK behavior

✅ **Data pipeline**
- Processing algorithm changed
- Want to validate on real data
- Could have bad outputs

---

## Today's Lab Plan

### Part 1: Blue-Green Deployment (30 min)
1. Create Blue deployment (v1.0) - current
2. Create Green deployment (v2.0) - new
3. Service points to Blue
4. Validate Green offline
5. Switch service to Green
6. Monitor & rollback if needed

### Part 2: Canary with Istio (30 min)
1. Install Istio service mesh
2. Deploy v1.0 with 100% traffic
3. Deploy v2.0 canary (5% traffic)
4. Gradually increase traffic
5. Monitor metrics
6. Full promotion or rollback

---

## Key Concepts to Master

| Concept | Definition | Example |
|---------|-----------|---------|
| **Selector** | Label matching for traffic | `version: blue` vs `version: green` |
| **Traffic Splitting** | Route % of requests | 90% to v1, 10% to v2 |
| **Smoke Test** | Quick validation before full deploy | Health check API |
| **Blast Radius** | How many users affected | 10% = canary, 100% = blue-green switch |
| **Rollback Window** | Time to revert safely | Minutes for canary, seconds for blue-green |

Ready to start? Let's build a Blue-Green deployment! 🚀
