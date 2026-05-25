# 📊 Monitoring - Quick Commands Reference

## One-Line Deployment

### Deploy Prometheus + Grafana (60 seconds)

```powershell
# Everything in one file - save both YAMLs then deploy
kubectl apply -f prometheus-config.yaml
kubectl apply -f grafana-deployment.yaml

# Wait for pods to start
Start-Sleep -Seconds 10

# Check status
kubectl get pods
```

---

## Essential Commands

### Prometheus Management

```powershell
# Deploy Prometheus
kubectl apply -f prometheus-config.yaml

# Check Prometheus
kubectl get deployment prometheus
kubectl get pods -l app=prometheus
kubectl logs -l app=prometheus

# Port forward to Prometheus UI
kubectl port-forward svc/prometheus 9090:9090
# Then visit: http://localhost:9090

# Check what Prometheus is scraping
# In browser: http://localhost:9090 → Status → Targets

# Query Prometheus API directly
kubectl exec -it deployment/prometheus -- curl localhost:9090/api/v1/query?query=up
```

### Grafana Management

```powershell
# Deploy Grafana
kubectl apply -f grafana-deployment.yaml

# Check Grafana
kubectl get deployment grafana
kubectl get pods -l app=grafana
kubectl logs -l app=grafana

# Port forward to Grafana
kubectl port-forward svc/grafana 3000:3000
# Then visit: http://localhost:3000

# Get Grafana admin password
kubectl get secret grafana-admin -o jsonpath="{.data.admin-password}" | base64 -d
# If that doesn't work: echo "It's 'admin123'"

# Access Grafana
# Username: admin
# Password: admin123
```

### Monitoring Service Health

```powershell
# Check if all monitoring pods are running
kubectl get pods -o wide

# Check service endpoints
kubectl get svc prometheus grafana

# Check resource usage
kubectl top pods

# Check logs for errors
kubectl logs -l app=prometheus --tail=20
kubectl logs -l app=grafana --tail=20
```

---

## Common Prometheus Queries

Use these in Grafana Query Editor:

```promql
# Is Prometheus alive?
up

# How many pods are up?
count(up)

# CPU usage (cores)
rate(container_cpu_usage_seconds_total[5m])

# Memory usage (bytes)
container_memory_usage_bytes

# Network received (bytes/sec)
rate(container_network_receive_bytes_total[5m])

# Network sent (bytes/sec)
rate(container_network_transmit_bytes_total[5m])

# Pod restarts
increase(kube_pod_container_status_restarts_total[1h])

# Requests per second
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Response latency (95th percentile)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Disk usage
100 * (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes))

# which pods are using most memory
topk(5, container_memory_usage_bytes)

# which pods are using most CPU
topk(5, rate(container_cpu_usage_seconds_total[5m]))
```

---

## Grafana Dashboard Operations

### Create Dashboard

```powershell
# Via UI:
# 1. Grafana home page
# 2. Click "+" → "Dashboard"
# 3. Click "Add panel"
# 4. Select Prometheus data source
# 5. Write query (e.g., 'up')
# 6. Click "Save"

# Via CLI (advanced):
# Use Grafana API to create dashboards programmatically
kubectl exec -it deployment/grafana -- \
  curl -X POST http://admin:admin123@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d '{"dashboard":{"title":"My Dashboard"}}'
```

### Import Dashboard from Grafana.com

```powershell
# Via UI:
# 1. Click "+" → "Import"
# 2. Enter dashboard ID (e.g., 1860 for Node Exporter Full)
# 3. Select Prometheus data source
# 4. Click "Import"

# Popular dashboard IDs:
# 1860 - Node Exporter Full
# 7249 - Kubernetes Cluster Monitoring
# 6902 - Kubernetes Stack Prometheus
# 3662 - Grafana Piechart Panel
```

### Export Dashboard

```powershell
# Via UI:
# Click menu → Export → Save JSON

# Via API:
kubectl exec -it deployment/grafana -- \
  curl http://admin:admin123@localhost:3000/api/dashboards/db/my-dashboard-slug
```

---

## Alert Configuration

### Create an Alert

```yaml
# In Grafana UI:
# 1. Open any panel
# 2. Click "Alert" tab
# 3. Set condition: cpu_usage > 0.8
# 4. Set "For" duration: 5m
# 5. Select notification channel
# 6. Save

# Alert rule example (PromQL):
ALERT HighCPU
  IF (rate(container_cpu_usage_seconds_total[5m]) > 0.8)
  FOR 5m
  LABELS { severity = "warning" }
  ANNOTATIONS { summary = "High CPU usage detected" }
```

### Send Alerts to Slack

```powershell
# In Grafana:
# 1. Administration → Alerting → Notification channels
# 2. Click "New channel"
# 3. Type: "Slack"
# 4. Webhook URL: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
# 5. Channel: #alerts
# 6. Click "Save"

# Then in alert, select this notification channel
```

---

## Monitoring Your App

### Instrument Your Application

If your app produces metrics (at :8080/metrics):

```powershell
# The scrape config automatically picks it up if you have:
# - annotation: prometheus.io/scrape: "true"
# - annotation: prometheus.io/path: "/metrics"
# - annotation: prometheus.io/port: "8080"

# Example pod with metrics:
kubectl annotate pod my-pod \
  prometheus.io/scrape=true \
  prometheus.io/path=/metrics \
  prometheus.io/port=8080

# Check Prometheus targets:
# http://localhost:9090/targets
```

---

## Troubleshooting Commands

```powershell
# Is Prometheus scraping?
kubectl exec -it deployment/prometheus -- \
  curl localhost:9090/api/v1/targets | Select-String "up"

# Check Prometheus storage
kubectl exec -it deployment/prometheus -- \
  du -sh /prometheus
# Prometheus stores about 1GB per day

# Check Prometheus config
kubectl get configmap prometheus-config -o yaml | Select-String -A 50 "prometheus.yml"

# List all metrics Prometheus has collected
kubectl exec -it deployment/prometheus -- \
  curl 'localhost:9090/api/v1/label/__name__/values' | head -20

# Check if Grafana connected to Prometheus
# In Grafana: Configuration → Data sources → Click Prometheus → "Test"

# View Grafana datasources
kubectl exec -it deployment/grafana -- \
  curl http://admin:admin123@localhost:3000/api/datasources

# List all Grafana dashboards
kubectl exec -it deployment/grafana -- \
  curl http://admin:admin123@localhost:3000/api/search
```

---

## Cleanup Commands

```powershell
# Delete Prometheus
kubectl delete deployment,svc,configmap -l app=prometheus
kubectl delete serviceaccount prometheus
kubectl delete clusterrole prometheus
kubectl delete clusterrolebinding prometheus

# Delete Grafana
kubectl delete deployment,svc -l app=grafana
kubectl delete secret grafana-admin

# Delete both
kubectl delete all,cm,secret -l app=prometheus,app=grafana
```

---

## Port Forwarding (Quick Access)

```powershell
# Prometheus on localhost:9090
kubectl port-forward svc/prometheus 9090:9090 &

# Grafana on localhost:3000
kubectl port-forward svc/grafana 3000:3000 &

# Monitor traffic (if using metrics service)
kubectl port-forward svc/app-metrics 8080:8080 &

# Kill all port forwards
Get-Process kubectl | Stop-Process
```

---

## Common Monitoring Tasks

### Monitor Specific Pod

```promql
# Memory of specific pod
container_memory_usage_bytes{pod="k8s-app-xyz"}

# CPU of specific pod
rate(container_cpu_usage_seconds_total{pod="k8s-app-xyz"}[5m])

# Requests to specific pod
rate(http_requests_total{pod="k8s-app-xyz"}[5m])
```

### Monitor Specific Namespace

```promql
# All metrics from namespace
up{namespace="default"}

# CPU per namespace
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)

# Memory per namespace
sum(container_memory_usage_bytes) by (namespace)
```

### Monitor Node Health

```promql
# Which node is running hot?
node_load1

# CPU per node
rate(node_cpu_seconds_total[5m]) by (node)

# Memory per node
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage per node
(node_filesystem_size_bytes{fstype!="tmpfs"} - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100
```

---

## Real-Time Dashboard Update

While monitoring:

```powershell
# Terminal 1: Port forward Grafana
kubectl port-forward svc/grafana 3000:3000

# Terminal 2: Port forward Prometheus
kubectl port-forward svc/prometheus 9090:9090

# Terminal 3: Generate load
kubectl run -it --rm load-generator --image=busybox -- \
  /bin/sh -c "while sleep 0.01; do wget -q -O- http://k8s-app-service; done"

# In browser: http://localhost:3000
# Watch graphs update in real-time! 📈
```

---

## Performance Tips

```powershell
# Prometheus retention (default 15 days)
# Edit deployment:
kubectl set env deployment/prometheus \
  PROMETHEUS_ARGS="--storage.tsdb.retention.time=30d"

# Increase Prometheus memory if collecting lots of metrics
kubectl set resources deployment/prometheus \
  --requests=cpu=500m,memory=1Gi \
  --limits=cpu=1000m,memory=2Gi

# Scrape less frequently to save resources
# Edit prometheus-config.yaml:
# global:
#   scrape_interval: 30s  # instead of 15s
```

---

## Production Checklist

Before using in production:

```
Monitoring
[ ] Prometheus configured for high-availability
[ ] Prometheus data is backed up
[ ] Grafana admin password changed from default
[ ] TLS/HTTPS enabled for Prometheus and Grafana
[ ] Authentication tokens configured

Alerting
[ ] AlertManager configured
[ ] Slack/PagerDuty integration working
[ ] Alert rules tuned (not too noisy)
[ ] On-call rotation set up

Dashboards
[ ] Key dashboards created
[ ] Dashboards shared with team
[ ] Documentation for each dashboard
[ ] Runbooks linked to alerts
```

---

## Quick Start - Copy & Paste

```powershell
# ONE COMMAND - Deploy everything
kubectl apply -f prometheus-config.yaml; kubectl apply -f grafana-deployment.yaml; Start-Sleep -Seconds 10

# TWO WINDOWS - Access
# Window 1:
kubectl port-forward svc/prometheus 9090:9090

# Window 2:
kubectl port-forward svc/grafana 3000:3000

# BROWSER
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin123)

# DONE! 🎉
```

---

**Next topic:** Centralized Logging (ELK Stack) or Helm Package Manager
