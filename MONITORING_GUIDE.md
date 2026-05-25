# 📊 Monitoring & Observability - Prometheus + Grafana

## What is Monitoring?

**Monitoring** = Watching what's happening in your cluster in real-time.

```
Your Cluster     ← What's happening here?
├─ CPU: 45%
├─ Memory: 60%
├─ Disk: 30%
├─ API Requests: 1500/sec
├─ Errors: 5/sec
├─ Response Time: 250ms
└─ Pod Restarts: 0

Prometheus (Metrics collection)
     ↓
Grafana (Pretty dashboards)
     ↓
YOU SEE EVERYTHING! 📊
```

---

## 🔍 Three Pillars of Observability

```
┌─────────────────────────────────────────────────────────┐
│           OBSERVABILITY (See Inside)                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. METRICS           2. LOGS            3. TRACES     │
│  ─────────────────    ──────────────     ─────────────│
│  CPU: 75%             ERROR: timeout     Request #123 │
│  Memory: 512MB        Pod k8s-app-xyz    └─ 250ms     │
│  Requests: 1000/s     2026-05-13 10:45   └─ 50ms      │
│  Errors: 2/s          stack trace        └─ 100ms     │
│  Latency: 200ms       server logs        └─ done!     │
│                                                         │
│  (We'll learn Metrics & Logs)                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Prometheus + Grafana Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Your Kubernetes Cluster                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  k8s-app Pod 1  │  │  k8s-app Pod 2  │                   │
│  │  Metrics HTTP   │  │  Metrics HTTP   │                   │
│  │  :9090/metrics  │  │  :9090/metrics  │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
│           │                    │                             │
│           └────────┬───────────┘                             │
│                    ↓                                         │
│  ┌─────────────────────────────────┐                       │
│  │      Prometheus Server          │                       │
│  │ (Scrapes metrics every 15s)    │                       │
│  │ Stores in time-series database  │                       │
│  └────────────────┬────────────────┘                       │
│                   ↓                                         │
│  ┌─────────────────────────────────┐                       │
│  │    Grafana Dashboard            │                       │
│  │ (Beautiful visualizations)      │                       │
│  │ Shows graphs, alerts, stats     │                       │
│  └────────────────┬────────────────┘                       │
│                   ↓                                         │
│              (You)                                          │
│        See everything! 📊                                  │
│                                                               │
└──────────────────────────────────────────────────────────────┘

Timeline:
- 10:00 AM: Prometheus scrapes metrics from all pods
- 10:00:15: Stores in database
- 10:00:30: Grafana displays on dashboard (live graphs)
- You: "CPU is spiking! HPA should be scaling..."
- HPA: "Already scaling! 2→4 pods"
```

---

## 📊 Key Concepts

### 1. **Prometheus** (Metric Collector)
- Scrapes metrics from pods every 15 seconds
- Stores time-series data (historical trends)
- Queryable database (PromQL language)
- Small footprint, fast

**What metrics does Prometheus collect?**
```
node_cpu_seconds_total          # CPU time per core
node_memory_MemAvailable_bytes  # Available memory
container_cpu_usage_seconds     # Container CPU usage
container_memory_usage_bytes    # Container memory usage
http_requests_total             # Total HTTP requests
http_request_duration_seconds   # Request latency
```

### 2. **Grafana** (Visualization)
- Creates beautiful dashboards
- Queries Prometheus data
- Shows graphs, gauges, tables
- Real-time updates
- Built-in alerts

**What can you visualize?**
```
Graphs (Line charts)        Gauges (Speed meters)    Tables (Raw data)
┌─────────────────┐        ┌──────────┐            ┌──────────┐
│ CPU over time   │        │ CPU: 75% │            │ Pod Name │
│ /               │        │  ▓▓▓     │            │ CPU      │
│  /     /        │        │ TARGET:80│            │ Memory   │
│ /     /         │        └──────────┘            └──────────┘
└─────────────────┘

Heatmaps                   Stat cards              Alerts
┌──────────────┐          ┌─────────┐            ⚠️ CPU > 80%
│ ■■■■■■■■■   │          │ UP: 99% │            🔴 Pod crash detected
│ ■■■█████    │          └─────────┘            🟡 Disk 85% full
│ ■■■████████ │
└──────────────┘
```

### 3. **Metrics vs Logs vs Traces**

| Type | Example | Use Case |
|------|---------|----------|
| **Metrics** | CPU: 75%, Mem: 512MB, Errors: 5/s | "Is system healthy?" |
| **Logs** | ERROR: Connection timeout at 10:45:23 | "What went wrong?" |
| **Traces** | Request #123: 50ms DB + 100ms API + 50ms render | "Where's the bottleneck?" |

**In this guide:** We focus on **Metrics** (Prometheus) + **Logs** (basic logging)

---

## 🚀 How It Works Step-by-Step

### Pod Startup Sequence

```
1. Pod starts running your app
   ↓
2. App exposes metrics at :8080/metrics
   └─ cpu_usage: 50m
   └─ memory_usage: 128MB
   └─ http_requests: 1000
   ↓
3. Prometheus scrapes every 15 seconds
   curl http://pod-ip:8080/metrics → Collects all metrics
   ↓
4. Prometheus stores in time-series database
   timestamp: "2026-05-13T10:45:30Z", cpu_usage: 50m
   timestamp: "2026-05-13T10:45:45Z", cpu_usage: 65m
   timestamp: "2026-05-13T10:46:00Z", cpu_usage: 75m
   ↓
5. Grafana queries Prometheus
   SELECT cpu_usage WHERE timestamp > now()-1h
   ↓
6. Grafana draws the graph
   You see CPU rising over time! 📈
```

---

## 📋 Installation Methods

### Method 1: Helm (Easiest - Recommended)
```bash
# One command install
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

### Method 2: Using kubectl (What We'll Do)
```bash
# Deploy via YAML files
kubectl apply -f prometheus-config.yaml
kubectl apply -f grafana-deployment.yaml
```

### Method 3: Operator (Most Enterprise)
```bash
# Uses Kubernetes operators
kubectl apply -f prometheus-operator.yaml
```

---

## 🎯 What You'll Monitor

### Application Metrics (from your app)
```
http_requests_total{method="GET", status="200"}
http_request_duration_seconds{path="/api/users", quantile="0.95"}
app_errors_total
```

### Container Metrics (from Kubernetes)
```
container_cpu_usage_seconds_total
container_memory_usage_bytes
container_network_receive_bytes_total
```

### Pod Metrics (Kubernetes built-in)
```
pod_running_count
pod_restart_count
pod_ready_count
```

### Node Metrics
```
node_cpu_seconds_total
node_memory_MemAvailable_bytes
node_disk_available_bytes
```

---

## 📊 Building Your First Dashboard

You'll create a dashboard showing:

```
┌─────────────────────────────────────────────────────┐
│            Cluster Overview Dashboard               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │ CPU: 45%     │  │ Memory: 65%  │               │
│  │ Target: 80%  │  │ Limit: 1GB   │               │
│  └──────────────┘  └──────────────┘               │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │ Pods Running │  │ Pod Errors   │               │
│  │ 8/10         │  │ 0 in 5 min   │               │
│  └──────────────┘  └──────────────┘               │
│                                                     │
│  ┌──────────────────────────────────────────┐     │
│  │         CPU Usage Over Time               │     │
│  │            /                              │     │
│  │           / \                             │     │
│  │          /   \___                         │     │
│  │         /         \__                     │     │
│  │        /             \_____               │     │
│  │ └──────────────────────────────────┐     │     │
│  │ 10:00  10:15  10:30  10:45  11:00 │     │     │
│  └──────────────────────────────────────────┘     │
│                                                     │
│  ┌──────────────────────────────────────────┐     │
│  │     Request Latency (95th percentile)     │     │
│  │          GET /api/users: 245ms            │     │
│  │          POST /api/orders: 892ms          │     │
│  │          GET /health: 12ms                │     │
│  └──────────────────────────────────────────┘     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🔔 Alerting Setup

After collecting metrics, you can create alerts:

```yaml
alerts:
- name: HighCPU
  condition: cpu_usage > 80%
  duration: 5 minutes
  action: Send Slack notification
  
- name: PodCrash
  condition: pod_restart_count > 0
  duration: immediately
  action: Page on-call engineer
  
- name: HighErrorRate
  condition: error_rate > 5%
  duration: 2 minutes
  action: Create incident ticket
```

---

## 📈 Common Dashboards

### 1. **Cluster Health**
- CPU, Memory, Network across all nodes
- Pod count, crashes, restarts
- Disk usage

### 2. **Application Performance**
- Request rate (req/sec)
- Request latency (p50, p95, p99)
- Error rate

### 3. **Database Health**
- Connection pool usage
- Query latency
- Replication lag (for PostgreSQL)

### 4. **Infrastructure**
- Node CPU, Memory, Disk
- Network I/O
- Container restarts

### 5. **Cost**
- CPU/Memory utilization
- Pod density per node
- Wasted resources

---

## 🐛 Troubleshooting with Observability

**Problem: App is slow!**
```
Before monitoring:
- "Uh, it seems slow?"
- Manual guessing, slow debugging
- Hours wasted

With monitoring:
- Grafana shows: "Latency jumped at 10:45"
- Look at metrics: "DB query time spiked"
- Check logs: "Database connection timeout"
- Fix: Restart database pod
- Done in 10 minutes! ✅
```

---

## 🎓 Key Takeaways

✅ **Prometheus** = Collects metrics
✅ **Grafana** = Visualizes metrics
✅ **Metrics** = Numbers (CPU, Memory, Requests, Errors)
✅ **Time-Series** = Track changes over time
✅ **Alerts** = Notify when problems happen
✅ **Dashboard** = See everything at a glance

---

## 📊 Production Monitoring Stack

Real companies use:
```
Prometheus (Metrics Collection)
    ↓
AlertManager (Alert routing)
    ↓
Slack/PagerDuty/Email (Notifications)
    ↓
Grafana (Dashboards)
    ↓
Loki (Log aggregation) ← Optional
    ↓
Jaeger (Distributed tracing) ← Optional
```

We'll focus on **Prometheus + Grafana** (core essentials)

---

## 🚀 Next Steps

Ready to deploy Prometheus + Grafana?

**Move to:** [PROMETHEUS_GRAFANA_HANDS_ON.md](PROMETHEUS_GRAFANA_HANDS_ON.md)

In the hands-on lab, you'll:
1. Deploy Prometheus to your cluster
2. Deploy Grafana to your cluster
3. Connect Grafana to Prometheus
4. Create your first dashboard
5. Watch metrics in real-time
6. Set up your first alert

Let's go! 🚀
