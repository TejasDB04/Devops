# 🔧 StatefulSets HANDS-ON LAB

## Objective
Deploy a PostgreSQL StatefulSet with 3 replicas and verify:
- ✅ Stable pod identities (postgresql-0, postgresql-1, postgresql-2)
- ✅ Each pod has its own persistent storage
- ✅ Data persists after pod crashes
- ✅ Ordered deployment and scaling

---

## 📋 Pre-Lab Setup (5 minutes)

### Prerequisites
- Docker Desktop with Kubernetes enabled
- kubectl installed
- psql client (optional, for testing)

### Check Your Setup
```bash
# Verify cluster is running
kubectl cluster-info

# Check kubectl version
kubectl version --short

# List existing namespaces
kubectl get namespaces
```

---

## 📖 Part 1: Understanding StatefulSets (10 minutes)

### Quick Comparison

```
┌─────────────────────────────────────────────────────────┐
│ DEPLOYMENT (Stateless - Web App)                        │
├─────────────────────────────────────────────────────────┤
│ Pod Names: random (webapp-abc123, webapp-def456)        │
│ Storage: Shared (all pods access same data)            │
│ Purpose: Stateless applications                         │
│ Example: Nginx web server, API endpoint                │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ STATEFULSET (Stateful - Database)                       │
├─────────────────────────────────────────────────────────┤
│ Pod Names: Ordered (postgres-0, postgres-1, postgres-2)│
│ Storage: Per-pod (each has own volume)                 │
│ Purpose: Stateful applications                         │
│ Example: PostgreSQL, MySQL, MongoDB, Kafka             │
└─────────────────────────────────────────────────────────┘
```

### Why This Matters
- **Stability:** Pod `postgres-0` always has the same name
- **Insurance:** `postgres-0` always connects to `postgres-storage-0` (same volume)
- **Clustering:** `postgres-1` can find `postgres-0` by hostname for replication

---

## 🏗️ Part 2: Create the Complete StatefulSet

### Step 1: Create Configuration Files

**Create a file: `postgresql-complete.yaml`**

```bash
cat > postgresql-complete.yaml <<'EOF'
---
# 1. SECRET - Credentials
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: default
type: Opaque
stringData:
  password: "secretpassword123"
  username: "postgres"

---
# 2. CONFIGMAP - Database Settings
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: default
data:
  POSTGRES_DB: "myappdb"
  POSTGRES_INITDB_ARGS: "-c max_connections=100"

---
# 3. HEADLESS SERVICE - Required for StatefulSet!
apiVersion: v1
kind: Service
metadata:
  name: postgresql-headless
  namespace: default
  labels:
    app: postgresql
spec:
  clusterIP: None  # ← THIS MAKES IT HEADLESS
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres

---
# 4. REGULAR SERVICE - For external access
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  namespace: default
  labels:
    app: postgresql
spec:
  type: ClusterIP
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres

---
# 5. STATEFULSET - The main component
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
  namespace: default
spec:
  # Link to headless service (REQUIRED)
  serviceName: postgresql-headless
  
  # Number of replicas
  replicas: 3
  
  # How to select pods
  selector:
    matchLabels:
      app: postgresql
  
  # Pod template
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      # Anti-affinity: spread pods across nodes
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - postgresql
              topologyKey: kubernetes.io/hostname
      
      # Container specification
      containers:
      - name: postgresql
        image: postgres:15-alpine
        imagePullPolicy: IfNotPresent
        
        # Exposed ports
        ports:
        - name: postgres
          containerPort: 5432
          protocol: TCP
        
        # Environment variables
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_DB
        
        # Resource requests and limits
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        # Liveness Probe - Is the pod alive?
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U ${POSTGRES_USER}
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness Probe - Is the pod ready to receive traffic?
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U ${POSTGRES_USER}
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 1
          failureThreshold: 2
        
        # Volume mounting
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres

  # Auto-creates PVCs!
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: standard
      resources:
        requests:
          storage: 5Gi
EOF
```

### Step 2: Deploy to Kubernetes

```bash
# Apply the configuration
kubectl apply -f postgresql-complete.yaml

# Verify creation
kubectl get statefulset postgresql
kubectl get svc
kubectl get secret postgres-secret
kubectl get configmap postgres-config
```

---

## 🚀 Part 3: Watch Deployment (10 minutes)

### Monitor Pod Creation (Sequential!)

**Terminal 1 - Watch pods:**
```bash
kubectl get pods -l app=postgresql --watch

# Output should look like:
# NAME           READY   STATUS     RESTARTS
# postgresql-0   0/1     Init       0
# postgresql-0   1/1     Running    0     ← First pod done!
# postgresql-1   0/1     Init       0
# postgresql-1   1/1     Running    0     ← Second pod done!
# postgresql-2   0/1     Init       0
# postgresql-2   1/1     Running    0     ← All done!
```

### Monitor Storage Creation

```bash
# Watch PVCs being created
kubectl get pvc --watch

# Expected output:
# postgres-storage-0  Bound   pvc-xxx  5Gi
# postgres-storage-1  Bound   pvc-yyy  5Gi
# postgres-storage-2  Bound   pvc-zzz  5Gi
```

### Check Pod Details

```bash
# See all pod info
kubectl describe pod postgresql-0

# Check which PVC is attached
kubectl get pvc -o wide

# Check pod IPs and hostnames
kubectl get pods -o wide
# Note the IP addresses!
```

---

## 🧪 Part 4: Test Your Deployment (20 minutes)

### Test A: Connect to Database

**Option A - Port Forward (Easiest)**

```bash
# Forward port 5432 from pod to localhost
kubectl port-forward pod/postgresql-0 5432:5432 &

# From another terminal, connect (install psql if needed)
psql -h localhost -U postgres -d myappdb

# If prompted for password, enter: secretpassword123

# You're in! Try these commands:
\dt                    # List tables (should be empty)
CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO users (name) VALUES ('Alice');
SELECT * FROM users;
\q                     # Exit
```

**Option B - Direct Exec (No psql needed)**

```bash
# Execute SQL directly in the pod
kubectl exec -it postgresql-0 -- \
  psql -U postgres -d myappdb -c "
    CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT);
    INSERT INTO users (name) VALUES ('Alice');
    SELECT * FROM users;
  "
```

### Test B: Verify Stable Pod Identity

```bash
# Get pod names (should be postgresql-0, postgresql-1, postgresql-2)
kubectl get pods -o name

# Expected:
# pod/postgresql-0
# pod/postgresql-1
# pod/postgresql-2

# Get pod DNS names
kubectl get endpoints postgresql-headless
```

### Test C: Verify Persistent Storage

```bash
# Delete postgresql-0 (simulate crash)
kubectl delete pod postgresql-0

# Watch it restart
kubectl get pods --watch

# Reconnect to the new postgresql-0
kubectl exec -it postgresql-0 -- \
  psql -U postgres -d myappdb -c "SELECT * FROM users;"

# Result: Table and data still exist! ✅
```

### Test D: Test Scaling

```bash
# Scale from 3 to 4 replicas
kubectl scale statefulset postgresql --replicas=4

# Watch new pod created in order
kubectl get pods --watch

# You should see: postgresql-3 being created

# Scale back down
kubectl scale statefulset postgresql --replicas=3

# postgresql-2 is deleted in reverse order
```

### Test E: Test Cluster Discovery (Advanced)

```bash
# Launch a test pod
kubectl run -it --rm debug --image=postgres:15-alpine -- sh

# Inside the pod, test DNS resolution
nslookup postgresql-0.postgresql-headless
# Should resolve to specific pod IP

nslookup postgresql-1.postgresql-headless
# Should resolve to different pod IP

# Test connectivity
psql -h postgresql-0.postgresql-headless -U postgres -d myappdb -c "\dt"
# Success if table exists!

exit
```

---

## ✅ Part 5: Verification Checklist

Go through this checklist to confirm everything works:

```
PODS
[ ] All 3 pods running: kubectl get pods
[ ] Pods have stable names (postgresql-0, postgresql-1, postgresql-2)
[ ] Each pod shows Ready 1/1

STORAGE
[ ] 3 PVCs created: kubectl get pvc
[ ] Each PVC is 5Gi
[ ] PVCs are Bound to volumes

NETWORKING
[ ] Headless service created: kubectl get svc postgresql-headless
[ ] ClusterIP service created: kubectl get svc postgresql
[ ] DNS resolves: kubectl exec -it <pod> -- nslookup postgres-0

DATABASE
[ ] Can connect to postgresql-0
[ ] Can create table: CREATE TABLE test (id SERIAL);
[ ] Data persists after pod delete: kubectl delete pod postgresql-0

SCALING
[ ] Can scale up to 4: kubectl scale statefulset postgresql --replicas=4
[ ] postgresql-3 is created in order
[ ] Can scale down to 2: kubectl scale statefulset postgresql --replicas=2
[ ] postgresql-2 deleted in reverse order
```

---

## 🐛 Troubleshooting During Lab

### Pods Stuck in Init

```bash
kubectl describe pod postgresql-0
# Look for events at bottom

# Common cause: Storage not available
# Solution: Use "standard" storage class (comes with Docker Desktop)
```

### Can't Connect to Database

```bash
# Check pod logs
kubectl logs postgresql-0

# Check if pod is actually ready
kubectl get pod postgresql-0 -o jsonpath='{.status.conditions}'

# Try entering the pod and testing locally
kubectl exec -it postgresql-0 -- sh
pg_isready
```

### PVC Stuck in Pending

```bash
kubectl describe pvc postgres-storage-0

# Check available storage
kubectl get storageclass

# Docker Desktop should have "standard" class
```

---

## 📊 What You'll Understand After This Lab

After completing this exercise, you'll have learned:

✅ **StatefulSet vs Deployment** - When and why to use each
✅ **Stable Pod Identity** - Why names matter for databases
✅ **Headless Services** - DNS-based pod discovery
✅ **VolumeClaimTemplates** - Automatic PVC creation
✅ **Ordered Scaling** - Sequential deployment
✅ **Data Persistence** - Storage survival across pod restarts
✅ **Pod Probes** - Health checks in action
✅ **Production Readiness** - Resource limits, anti-affinity

---

## 🎯 Next Steps After Lab

Once you complete this lab:

1. **Scale postgres to 5 replicas** and verify all work
2. **Set up replication** (postgres-0 as master, others as replicas)
3. **Implement backup** (daily PVC snapshots)
4. **Move to next topic:** Auto-Scaling (HPA)

---

## 💾 Cleanup (When Done)

**Keep everything for now** (we'll use it for future labs)

When you're truly done with StatefulSets:

```bash
# Safe cleanup (keeps PVCs with data)
kubectl delete statefulset postgresql
kubectl delete svc postgresql postgresql-headless
kubectl delete cm postgres-config
kubectl delete secret postgres-secret

# PVCs remain: postgres-storage-0, postgres-storage-1, postgres-storage-2

# Delete everything including data (⚠️ Only if sure!)
kubectl delete all,pvc,cm,secret -l app=postgresql
```

---

## 🎓 Lab Complete! 🎉

When you're done, message: **"StatefulSets complete! Ready for Auto-Scaling."**

