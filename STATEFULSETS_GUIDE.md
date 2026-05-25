# 🗄️ StatefulSets & PostgreSQL - Complete Guide

## What are StatefulSets?

StatefulSets manage stateful applications - applications that need:
- **Stable network identities** (postgres-0, postgres-1, postgres-2)
- **Persistent storage** (each pod has its own volume)
- **Ordered scaling** (pods created in sequence)
- **Direct pod access** (not load-balanced)
- **Direct pod access** (pods created in sequence)
- **Persistent atoreage** (postgres-0, ps\ostgres-1, postgres-2)
- **Stable network identities**(postgres-0, postgres-1, postgres-2)
- **Ordered scaling** (pods created in sequence)



---

## Key Concepts

### 1. **Headless Service**
```yaml
clusterIP: None  # No virtual IP - DNS points directly to pods
```
- DNS name resolves to individual pod IPs
- Allows direct pod-to-pod communication
- Essential for databases and clustering

### 2. **Stable Pod Names**
```
Deployment:  k8s-app-xyz-abc-123k  (random)
StatefulSet: postgresql-0          (ordered)
             postgresql-1
             postgresql-2
```

### 3. **Persistent Storage Template**
```yaml
volumeClaimTemplates:  # Creates PVC for each pod
  - name: postgresql-storage
```
- Automatically creates `postgresql-storage-0`, `postgresql-storage-1`, etc.
- Each pod has its own dedicated volume
- Data persists even after pod deletion

### 4. **Ordered Scaling**
```
Scale 0 → 1: Creates postgresql-0
             Waits for ready
Scale 1 → 2: Creates postgresql-1
             Waits for ready
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│         PostgreSQL StatefulSet              │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  postgresql-0 (Primary)              │  │
│  │  ├─ Container: postgres:15           │  │
│  │  └─ PVC: postgresql-storage-0 (1GB)  │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  postgresql-1 (Replica)              │  │
│  │  ├─ Container: postgres:15           │  │
│  │  └─ PVC: postgresql-storage-1 (1GB)  │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  postgresql-2 (Replica)              │  │
│  │  ├─ Container: postgres:15           │  │
│  │  └─ PVC: postgresql-storage-2 (1GB)  │  │
│  └──────────────────────────────────────┘  │
│                                             │
├─ Headless Service (postgresql-headless)    │
│  └─ DNS: postgresql-0.postgresql-headless  │
│  └─ DNS: postgresql-1.postgresql-headless  │
│  └─ DNS: postgresql-2.postgresql-headless  │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Step-by-Step Deployment

### Step 1: Deploy StatefulSet
```bash
kubectl apply -f postgresql-statefulset.yaml
```

**What this creates:**
- ConfigMap: `postgresql-config` (database settings)
- Secret: `postgresql-secret` (credentials)
- Service: `postgresql-headless` (DNS for pods)
- Service: `postgresql` (cluster access)
- StatefulSet: `postgresql` (3 database pods)

### Step 2: Watch Pods Start (Ordered!)
```bash
kubectl get pods -l app=postgresql --watch
```

**Expected output (sequential):**
```
NAME           READY   STATUS
postgresql-0   0/1     Init
postgresql-0   1/1     Running    ← Done first
postgresql-1   0/1     Init
postgresql-1   1/1     Running    ← Done second
postgresql-2   0/1     Init
postgresql-2   1/1     Running    ← Done last
```

### Step 3: Verify Storage (PersistentVolumeClaims)
```bash
kubectl get pvc
```

**Expected output:**
```
NAME                        STATUS   VOLUME
postgresql-storage-0        Bound    pvc-xxx
postgresql-storage-1        Bound    pvc-yyy
postgresql-storage-2        Bound    pvc-zzz
```

### Step 4: Check StatefulSet Status
```bash
kubectl describe statefulset postgresql
```

### Step 5: Access the Database

#### Option A: Using Port-Forward
```bash
# Connect to primary (postgresql-0)
kubectl port-forward pod/postgresql-0 5432:5432
```

Then in another terminal:
```bash
# Connect with psql (if installed locally)
psql -h localhost -U admin -d myapp_db
# Password: postgres123!
```

#### Option B: Execute Within Cluster
```bash
# Enter the pod
kubectl exec -it postgresql-0 -- /bin/bash

# Inside the pod, connect to database
psql -U admin -d myapp_db
# Password: postgres123!

# Example SQL commands
\dt                          # List tables
CREATE TABLE users (id SERIAL, name VARCHAR(100));
INSERT INTO users (name) VALUES ('Alice');
SELECT * FROM users;
\q                           # Exit
```

---

## 📊 Common Commands

```bash
# Check StatefulSet status
kubectl get statefulset
kubectl describe statefulset postgresql

# Check individual pods
kubectl get pods -l app=postgresql
kubectl describe pod postgresql-0
kubectl logs postgresql-0

# Check storage
kubectl get pvc
kubectl describe pvc postgresql-storage-0

# Connect to a specific pod
kubectl exec -it postgresql-0 -- /bin/bash

# Scale the database
kubectl scale statefulset postgresql --replicas=5

# Delete everything (⚠️ USE WITH CAUTION)
kubectl delete statefulset postgresql
kubectl delete svc postgresql postgresql-headless
kubectl delete configmap postgresql-config
kubectl delete secret postgresql-secret
# PVCs remain (for data safety)

# Delete with PVCs (complete cleanup)
kubectl delete statefulset,svc,cm,secret -l app=postgresql
kubectl delete pvc -l app=postgresql
```

---

## 🔍 Key Differences from Deployments

### Deployment (Stateless Apps)
```yaml
kind: Deployment
spec:
  template:
    spec:
      containers:
      - volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: my-pvc  # Single shared PVC
```

### StatefulSet (Stateful Apps)
```yaml
kind: StatefulSet
spec:
  volumeClaimTemplates:  # Creates one per pod!
  - metadata:
      name: postgresql-storage
    spec:
      resources:
        requests:
          storage: 1Gi
```

---

## 💡 Important Points

1. **Pod Deletion**: If `postgresql-0` dies, it respawns with the same name and attached storage
2. **Scaling Down**: Pods are deleted in reverse order (2, 1, 0)
3. **Headless Service**: Enables DNS-based pod discovery for clustering
4. **Storage**: PVCs persist even if StatefulSet is deleted (prevents data loss)
5. **Probes**: Readiness probe checks if database is actually online

---

## 🚨 Troubleshooting

### Pods Stuck in Pending
```bash
kubectl describe pod postgresql-0
```
Check if PVC is bound. If not, ensure storage class exists.

### PostgreSQL Won't Start
```bash
kubectl logs postgresql-0
```

### Can't Connect
```bash
# Check network
kubectl get svc postgresql-headless
kubectl get svc postgresql

# Test from another pod
kubectl run -it --rm debug --image=postgres:15-alpine -- psql -h postgresql-0.postgresql-headless -U admin -d myapp_db
```

---

## ✅ Verification Checklist

- [ ] All 3 pods running: `kubectl get pods`
- [ ] All 3 PVCs bound: `kubectl get pvc`
- [ ] Pods responding to probes: `kubectl describe pod postgresql-0`
- [ ] Can connect to database: `kubectl exec -it postgresql-0 -- psql...`
- [ ] Created test table: `CREATE TABLE test (id SERIAL);`
- [ ] Data persists after pod restart: `kubectl delete pod postgresql-0`

---

## 🎓 Learning Outcomes

After this exercise, you'll understand:
✅ StatefulSet vs Deployment differences
✅ Headless Services for pod identity
✅ Persistent storage with volumeClaimTemplates
✅ Ordered pod scaling
✅ Database deployment in Kubernetes
✅ Pod-to-pod networking

---

## Next Topics

1. **Backup & Restore** - Backup PostgreSQL data
2. **Replication** - Set up primary-replica replication
3. **Monitoring** - Add Prometheus metrics
4. **Helm Charts** - Templatize StatefulSet deployment
5. **Jobs/CronJobs** - Automated backups with Jobs

---

**Status**: Ready to deploy! 🚀
