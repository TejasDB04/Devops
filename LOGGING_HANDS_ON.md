# 📝 Centralized Logging - Hands-On Lab

Complete this lab to master logging in Kubernetes!

---

## ✅ Prerequisites

Before starting, ensure you have:
- ✅ Kubernetes cluster running (Docker Desktop K8s or minikube)
- ✅ Helm installed
- ✅ kubectl configured
- ✅ Your k8s-app deployed
- ✅ Prometheus/Grafana already running (from previous labs)

Check status:
```bash
kubectl get pods -n default
kubectl get svc grafana -n default  # Should show running
```

---

## 🚀 Lab Part 1: Deploy Loki (Log Storage)

Loki is a lightweight log aggregation system designed for Kubernetes.

### Step 1: Add Grafana Helm Repository

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

**Expected output:**
```
"grafana" has been added to your repositories
Update Complete. ⎈ Happy Helming!
```

### Step 2: Install Loki Stack

This installs Loki + Promtail (log shipper) together:

```bash
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=5Gi \
  --set promtail.enabled=true
```

**What this does:**
- `loki-stack`: Includes Loki (storage) + Promtail (shipper)
- `--namespace monitoring`: Places in monitoring namespace
- `persistence.enabled=true`: Logs persist even if pod restarts
- `size=5Gi`: Allocate 5GB for logs

**Wait for deployment:**
```bash
kubectl wait --for=condition=ready pod -l app=loki -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=promtail -n monitoring --timeout=300s
```

### Step 3: Verify Installation

```bash
# Check Loki is running
kubectl get pods -n monitoring | grep loki

# Check Promtail is running (one per node)
kubectl get pods -n monitoring | grep promtail
```

**Expected output:**
```
NAME                    READY   STATUS    RESTARTS   AGE
loki-0                  1/1     Running   0          2m
promtail-xxxxx          1/1     Running   0          2m
promtail-yyyyy          1/1     Running   0          2m
```

If pods aren't running, check logs:
```bash
kubectl logs -n monitoring loki-0
kubectl logs -n monitoring promtail-xxxxx
```

---

## 🎯 Lab Part 2: Add Loki Data Source to Grafana

Now connect Loki to Grafana so you can search logs in dashboards.

### Step 1: Port Forward to Grafana

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80 &
```

Visit: http://localhost:3000

Login: 
- Username: `admin`
- Password: `prom-operator` (or whatever you set)

### Step 2: Add Loki as Data Source

1. Click **Configuration** (gear icon) → **Data Sources**
2. Click **Add Data Source**
3. Search for "Loki"
4. Enter URL: `http://loki:3100`
5. Click **Save & Test**

**Expected:** "Data source is working"

---

## 📊 Lab Part 3: View Logs from Your Pods

### Step 1: Generate Logs

First, create some logs to view. Run your app and trigger activity:

```bash
# Generate traffic to your app
for i in {1..100}; do
  curl http://localhost:8080
  sleep 1
done
```

### Step 2: View Logs in Grafana

1. Click **Explore** (left sidebar)
2. Select **Loki** from datasource dropdown
3. Click **Log Labels** → Select your pod label

**Example queries:**

**Find logs from k8s-app:**
```
{app="k8s-app"}
```

**Find ERROR logs:**
```
{app="k8s-app"} | "ERROR"
```

**Find logs from last 5 minutes:**
```
{app="k8s-app"} | json | level="ERROR"
```

**Count errors per minute:**
```
sum(rate({app="k8s-app"} | "ERROR" [1m]))
```

---

## 🔍 Lab Part 4: Create Log-Based Dashboard

Create a dashboard that shows your app's health through logs.

### Step 1: Create New Dashboard

1. Click **+** icon → **Dashboard**
2. Click **Add Panel**
3. Select **Loki** datasource
4. Enter query: `{app="k8s-app"}`
5. Set title: "App Logs"
6. Click **Apply**

### Step 2: Add Error Count Panel

1. Click **Add Panel**
2. Use query:
```
rate({app="k8s-app"} | json | level="ERROR" [1m])
```
3. Set title: "Error Rate (per minute)"
4. Choose visualization: **Graph** or **Stat**
5. Click **Apply**

### Step 3: Save Dashboard

1. Click **Save** (top right)
2. Name: `App Health Dashboard`
3. Click **Save**

You now have a dashboard showing:
- ✅ All app logs
- ✅ Error rate trend
- ✅ Real-time errors

---

## 🚨 Lab Part 5: Set Up Log Alerts

Alert when error rate gets too high.

### Step 1: Trigger Some Errors

In your app, add an endpoint that fails:

**app.js** (add this):
```javascript
app.get('/crash', (req, res) => {
  console.error('ERROR: Intentional crash simulation!');
  res.status(500).send('Crash!');
});
```

Trigger it:
```bash
curl http://localhost:8080/crash
curl http://localhost:8080/crash
curl http://localhost:8080/crash
```

### Step 2: Create Alert Rule

Create file: `loki-alert-rules.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: loki-alerts
  namespace: monitoring
spec:
  groups:
  - name: loki.rules
    interval: 30s
    rules:
    - alert: HighErrorRate
      expr: |
        rate({app="k8s-app"} | json | level="ERROR" [5m]) > 0.1
      for: 1m
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value }} per second"
```

Deploy it:
```bash
kubectl apply -f loki-alert-rules.yaml
```

### Step 3: Verify Alert

1. In Grafana, go to **Alerting** → **Alert Rules**
2. Should see `HighErrorRate` rule
3. When error rate exceeds threshold, it fires!

---

## 💡 Lab Part 6: Search Patterns

Master common log searches:

### Find all errors
```
{app="k8s-app"} | "error"
```

### Find database errors
```
{app="k8s-app"} | "database" | "error"
```

### Find by severity
```
{app="k8s-app"} | json | level="ERROR"
```

### Find by trace ID (if app logs trace_id)
```
{app="k8s-app"} | trace_id="abc123"
```

### Count logs per pod
```
sum(count_over_time({app="k8s-app"} [5m])) by (pod)
```

### Error percentage
```
100 * (
  sum(rate({app="k8s-app"} | "ERROR" [1m])) 
  / 
  sum(rate({app="k8s-app"} [1m]))
)
```

---

## ✅ Verification Checklist

By now, you should have:

- [ ] Loki running (`kubectl get pods -n monitoring | grep loki`)
- [ ] Promtail collecting logs from pods
- [ ] Loki data source added to Grafana
- [ ] Can query logs: `{app="k8s-app"}` returns results
- [ ] Dashboard created showing app logs
- [ ] Error rate panel working
- [ ] Alert rule configured for high errors
- [ ] Successfully searched for errors across cluster

---

## 🎯 Real-World Scenarios

### Scenario 1: App is slow - Find why!

```bash
# Search for timeout errors
{app="k8s-app"} | "timeout"

# Check database errors
{app="k8s-app"} and {service="database"} | "error"

# See response times
{app="k8s-app"} | json | response_time > 5000
```

### Scenario 2: User reported issue - Debug it!

```bash
# Get all logs for specific user (if your app logs this)
{app="k8s-app"} | user_id="john@email.com"

# See complete request journey
{app="k8s-app"} | request_id="req-12345"
```

### Scenario 3: Memory leak suspected - Monitor it!

```bash
# Check for memory errors
{app="k8s-app"} | "out of memory"

# Monitor pod restarts
{pod=~"k8s-app.*"} | "restarting"
```

---

## 🏆 Next Steps

You've now learned:
- ✅ Centralized logging with Loki
- ✅ Log aggregation and search
- ✅ Log-based alerts
- ✅ Real-world debugging with logs

### What comes next?

**Option 1: Learn Helm** - Package management
- Simplify your manifests
- Deploy with one command

**Option 2: Learn Security** - RBAC + Network Policies
- Control access to resources
- Restrict pod-to-pod communication

**Option 3: Advanced Deployments** - Blue-Green & Canary
- Zero-downtime rollouts
- Gradual traffic shifting

---

## 🆘 Troubleshooting

### Promtail not collecting logs

```bash
# Check Promtail status
kubectl logs -n monitoring -l app=promtail

# Verify Loki is running
kubectl get svc -n monitoring loki

# Check Promtail config
kubectl get cm -n monitoring promtail
```

### No logs showing in Grafana

1. Verify queries return data
2. Check time range (click clock icon)
3. Verify label selectors are correct
4. Check pod has app label: `kubectl get pods --show-labels`

### Loki disk space error

```bash
# Increase PVC size
kubectl patch pvc -n monitoring loki-data \
  -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'
```

---

## 📚 Summary

You now have a **complete centralized logging solution**:

| Feature | Status |
|---------|--------|
| Log aggregation | ✅ Loki |
| Log collection | ✅ Promtail |
| Dashboard & search | ✅ Grafana |
| Alerts | ✅ Configured |
| Multi-pod search | ✅ Works |
| Real-time monitoring | ✅ Enabled |

**Time spent:** 45 minutes
**Value gained:** 10x faster debugging! 🚀

---

## 🎓 What You Learned

1. **Logging Architecture** - How logs flow from pods to dashboard
2. **Loki Basics** - Lightweight log aggregation
3. **Promtail** - Collects logs from container stdout/stderr
4. **Log Queries** - Search logs efficiently
5. **Alerts** - Notify when errors spike
6. **Dashboards** - Visualize logs in Grafana

Your cluster is now **production-ready with observability**! 🎉
