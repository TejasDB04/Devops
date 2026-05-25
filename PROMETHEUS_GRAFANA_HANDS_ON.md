# 🔧 Prometheus + Grafana HANDS-ON LAB

## Objective

Deploy a complete monitoring stack and watch your cluster in real-time:
- ✅ Install Prometheus (metric collection)
- ✅ Install Grafana (dashboards)
- ✅ Create your first dashboard
- ✅ Watch metrics update in real-time
- ✅ Set up basic alerting

---

## 📋 What You'll Map to Your Cluster

```
Your Cluster
├─ k8s-app (2 pods) ← We'll monitor this
├─ Prometheus ← Collects metrics
└─ Grafana ← Shows pretty graphs
```

---

## 🚀 Part 1: Deploy Prometheus (10 minutes)

### Create Prometheus ConfigMap

```yaml
# Save as: prometheus-config.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: default
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    scrape_configs:
    # Prometheus itself
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']
    
    # Kubernetes API server
    - job_name: 'kubernetes-apiservers'
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name]
        action: keep
        regex: default;kubernetes
    
    # Kubernetes nodes
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    
    # Kubernetes pods
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: "true"
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
        ports:
        - containerPort: 9090
          name: web
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: storage
          mountPath: /prometheus
        resources:
          requests:
            cpu: 250m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: storage
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: default
spec:
  selector:
    app: prometheus
  type: ClusterIP
  ports:
  - port: 9090
    targetPort: 9090
    name: web

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: default

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - nodes/metrics
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: default
```

Deploy Prometheus:

```powershell
# Create the configuration file (copy yaml above into a file)
# Or download: kubectl apply -f prometheus-config.yaml

# Deploy it
kubectl apply -f prometheus-config.yaml

# Wait for deployment
Start-Sleep -Seconds 5

# Check status
kubectl get deployment prometheus
kubectl get pods -l app=prometheus
```

Verify Prometheus is running:

```powershell
# Port forward to Prometheus UI
kubectl port-forward svc/prometheus 9090:9090

# In browser: http://localhost:9090
# You should see Prometheus web interface!

# Check targets (metrics being scraped):
# Click "Status" → "Targets"
# Should show: kubernetes-nodes, kubernetes-pods, prometheus, etc.
```

---

## 💾 Part 2: Deploy Grafana (10 minutes)

```yaml
# Save as: grafana-deployment.yaml

apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin
  namespace: default
type: Opaque
stringData:
  admin-user: admin
  admin-password: admin123

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
          name: web
        env:
        - name: GF_SECURITY_ADMIN_USER
          valueFrom:
            secretKeyRef:
              name: grafana-admin
              key: admin-user
        - name: GF_SECURITY_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-admin
              key: admin-password
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        volumeMounts:
        - name: storage
          mountPath: /var/lib/grafana
      volumes:
      - name: storage
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: default
spec:
  selector:
    app: grafana
  type: ClusterIP
  ports:
  - port: 3000
    targetPort: 3000
    name: web
```

Deploy Grafana:

```powershell
# Deploy Grafana
kubectl apply -f grafana-deployment.yaml

# Wait for deployment
Start-Sleep -Seconds 5

# Check status
kubectl get deployment grafana
kubectl get pods -l app=grafana

# Check services
kubectl get svc grafana prometheus
```

Access Grafana:

```powershell
# Port forward to Grafana
kubectl port-forward svc/grafana 3000:3000

# In browser: http://localhost:3000
# Username: admin
# Password: admin123
# Click "Login"
```

---

## 🔗 Part 3: Connect Grafana to Prometheus (5 minutes)

Once logged into Grafana:

### Step 1: Add Data Source

1. Click the **menu icon** (≡) in top-left
2. Select **Connections** → **Data sources**
3. Click **Add data source**
4. Select **Prometheus**
5. In **Prometheus server URL**, enter: `http://prometheus:9090`
6. Click **Save & test**
7. You should see: "✅ Data source is working"

### Step 2: Create Your First Dashboard

1. Click **+** → **Dashboard**
2. Click **Add a new panel**
3. In the query editor:
   - Select data source: **Prometheus**
   - In **Metrics** field, type: `up`
   - You should see: `up{job="prometheus"}` and other metrics
   - Click **Run query**
4. You should see a graph!

### Step 3: Add More Panels

Add a new panel for CPU:

1. Click **Add** → **Panel**
2. In metrics: type `node_cpu_seconds_total`
3. Set title: "CPU Seconds"
4. Click **Run query**

Add a panel for Memory:

1. Click **Add** → **Panel**
2. In metrics: type `node_memory_MemAvailable_bytes`
3. Set title: "Available Memory"
4. Click **Run query**

---

## 📊 Part 4: Build Your Custom Dashboard (10 minutes)

Create a dashboard showing:
- Pod status
- CPU usage
- Memory usage
- Network traffic

### Step 1: Clone an Existing Dashboard (Easier)

1. In Grafana, go to **Dashboards**
2. Click **Browse** 
3. Click **+** to create new dashboard
4. Click **Import**
5. Enter a Grafana dashboard ID:
   - **Node Exporter Full**: 1860
   - **Kubernetes Cluster Monitoring**: 7249
6. Click **Load**
7. Select data source: **Prometheus**
8. Click **Import**
9. You'll see a pre-built dashboard!

### Step 2: Customize the Dashboard

1. Click **Edit** (pencil icon)
2. Click on any panel to edit it
3. Change title, query, visualization
4. Click **Save** to save changes

### Step 3: Create Alerts (Optional)

1. Click on a panel
2. Click **Alert**
3. Set condition: `cpu_usage > 0.8`
4. Set notification channel: **Email** (or Slack)
5. Click **Save**

---

## ✅ Part 5: Verify Everything Works (5 minutes)

```powershell
# Check all components are running
kubectl get deployment prometheus grafana
kubectl get pods

# Check services
kubectl get svc prometheus grafana

# Check Prometheus is scraping
kubectl logs deployment/prometheus | Select-String "scraping" -A 2

# Get Grafana admin password
kubectl get secret grafana-admin -o jsonpath="{.data.admin-password}" | base64 -d

# Get Prometheus pod logs
kubectl logs -l app=prometheus --tail=20
```

Verify in Grafana:

1. Go to http://localhost:3000
2. Click **Dashboards** → **Node Exporter Full** (if you imported)
3. You should see:
   - CPU graphs
   - Memory graphs
   - Network graphs
   - System info

---

## 🧪 Part 6: Watch Metrics Update (5 minutes)

### Generate Load and Watch Metrics

Terminal 1: Start load test
```powershell
kubectl run -it --rm load-generator `
  --image=busybox `
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://k8s-app-service; done"
```

Terminal 2: Watch Grafana
```powershell
# Keep Grafana open in browser: http://localhost:3000
# Watch the graphs update in real-time!
# 
# You should see:
# - CPU graph going UP (red line climbing)
# - Memory graph going UP (different graph)
# - Request rate increasing
```

Terminal 3: Watch HPA scale
```powershell
kubectl get pods -l app=k8s-app --watch

# As traffic increases, HPA should scale pods!
# Grafana shows: More CPU → More pods → More memory
```

Stop load test:
```
Ctrl+C in Terminal 1
Wait 5 minutes
Watch everything scale back down
```

---

## 🔍 Part 7: Explore Metrics (10 minutes)

### Common Prometheus Queries

Try these in Grafana:

```promql
# Pod count
count(up{job="kubernetes-pods"})

# Average CPU per pod
avg(rate(container_cpu_usage_seconds_total[5m]))

# Pod memory usage
container_memory_usage_bytes

# HTTP requests per second
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Latency (95th percentile)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### Create a New Panel

1. Go to your dashboard
2. Click **+** → **Panel**
3. In Prometheus query: `up`
4. Select visualization: **Stat** or **Gauge**
5. Set title: "Cluster Status"
6. Click **Save**

---

## 📈 Real Dashboard You Build

```
┌────────────────────────────────────────────────────┐
│         Kubernetes Cluster Monitoring               │
├────────────────────────────────────────────────────┤
│                                                    │
│  ┌───────────────┐  ┌───────────────┐            │
│  │ Nodes UP: 1   │  │ Pods Total: 8 │            │
│  └───────────────┘  └───────────────┘            │
│                                                    │
│  ┌───────────────────────────────────────────┐    │
│  │     Node CPU Usage (last 1 hour)          │    │
│  │           ╱╲                               │    │
│  │          ╱  ╲___                           │    │
│  │         ╱        ╲__                       │    │
│  │────────────────────────────────────────    │    │
│  └───────────────────────────────────────────┘    │
│                                                    │
│  ┌───────────────────────────────────────────┐    │
│  │   Container Memory (bytes)                │    │
│  │  ██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │    │
│  │  256MB / 2GB used                        │    │
│  └───────────────────────────────────────────┘    │
│                                                    │
│  ┌───────────────────────────────────────────┐    │
│  │    Pod Restarts (last 24h)                │    │
│  │  k8s-app-xyz: 1                           │    │
│  │  k8s-app-abc: 0                           │    │
│  │  Other pods: 0                            │    │
│  └───────────────────────────────────────────┘    │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## ✅ Verification Checklist

```
PROMETHEUS
[ ] Prometheus deployed: kubectl get pods -l app=prometheus
[ ] Prometheus running: kubectl port-forward svc/prometheus 9090:9090
[ ] Prometheus UI loads: http://localhost:9090
[ ] Status → Targets shows "UP" targets

GRAFANA
[ ] Grafana deployed: kubectl get pods -l app=grafana
[ ] Grafana running: kubectl port-forward svc/grafana 3000:3000
[ ] Grafana login works: http://localhost:3000 (admin/admin123)
[ ] Data source added: Connections → Data sources shows Prometheus
[ ] Can run a query: Prometheus data source "working" ✓

DASHBOARDS
[ ] Created first panel with 'up' metric
[ ] Can see graphs updating
[ ] Can add/edit panels
[ ] Dashboard auto-refreshes

LOAD TESTING
[ ] Started load generator
[ ] Watched CPU/Memory graphs rise
[ ] Watched HPA scale pods
[ ] Stopped load test
[ ] Watched metrics decrease
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| **Grafana won't load** | Port-forward: `kubectl port-forward svc/grafana 3000:3000` |
| **Can't login** | Username: `admin`, Password: `admin123` |
| **No data in Prometheus** | Wait 30 seconds, Prometheus takes time to scrape |
| **"Data source is not working"** | Check: URL should be `http://prometheus:9090` (not localhost) |
| **Graphs are empty** | Click **Run query** button in Prometheus query editor |
| **Prometheus not scraping** | Check: `kubectl logs deployment/prometheus` |

---

## 🎯 What You Learned

After this lab:

✅ How Prometheus collects metrics
✅ How Grafana visualizes data
✅ How to create custom dashboards
✅ How to query metrics with PromQL
✅ How to monitor your Kubernetes cluster
✅ How to set up basic alerts
✅ How to troubleshoot using metrics

---

## 📚 Next Steps

1. **Explore** - Click around Grafana, try different queries
2. **Import** - Add more dashboards from Grafana.com
3. **Alert** - Set up an alert for high CPU
4. **Share** - Share dashboards with your team
5. **Customize** - Build dashboards specific to your apps

---

## 🎓 Production-Ready Monitoring

What companies add:

1. **AlertManager** - Routes alerts to Slack/PagerDuty
2. **Loki** - Centralized logging
3. **Jaeger** - Distributed tracing
4. **Thanos** - Long-term storage
5. **Custom exporters** - App-specific metrics

But **Prometheus + Grafana** is 80% of what you need!

---

## 🚀 Lab Complete!

When you finish:

1. ✅ Prometheus collecting metrics
2. ✅ Grafana showing dashboards
3. ✅ Created custom dashboard
4. ✅ Watched metrics change in real-time
5. ✅ Understand how monitoring works

**Message when done:**
```
"Monitoring & Observability complete! Ready for next topic."
```

Congratulations! You now have full visibility into your cluster! 📊🔍
