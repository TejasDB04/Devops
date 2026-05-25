# Observe — DevOps Observability Lab

**Goal:** Metrics (Prometheus) + dashboards (Grafana) + centralized logs (Loki) for your `k8s-app`.

**Time:** ~45–60 minutes

---

## Prerequisites

1. **Docker Desktop** → Settings → Kubernetes → **Enabled**
2. Wait until `kubectl get nodes` shows `Ready`
3. **k8s-app** deployed (`kubectl apply -f deployment.yaml -f service.yaml` or Helm)
4. Optional: `helm` for Loki

---

## What you will build

```
┌─────────────┐     scrape /metrics      ┌──────────────┐
│  k8s-app    │ ────────────────────────►│  Prometheus  │
│  (pods)     │                          │  :9090       │
└─────────────┘                          └──────┬───────┘
       │ logs (stdout JSON)                      │
       ▼                                         ▼
┌─────────────┐                          ┌──────────────┐
│  Promtail   │ ──────► Loki :3100       │   Grafana    │
└─────────────┘                          │   :3000      │
                                         └──────────────┘
```

---

## Part 1 — App instrumentation (done in repo)

Your app now exposes:

| Endpoint | Purpose |
|----------|---------|
| `/metrics` | Prometheus scrape (request count, latency, Node metrics) |
| `/api/health` | Probes + uptime |
| JSON logs on stdout | Parsed by Loki/Promtail |

**Rebuild image after pulling latest code:**

```powershell
cd "c:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"
npm install
docker build -t k8s-app:latest .
kubectl set image deployment/k8s-app app=k8s-app:latest
# or: kubectl rollout restart deployment/k8s-app
```

**Verify locally:**

```powershell
docker run --rm -p 3000:3000 k8s-app:latest
curl http://localhost:3000/metrics
```

---

## Part 2 — Deploy monitoring stack

### Quick deploy (script)

```powershell
.\observe-deploy.ps1
```

### Manual deploy

```powershell
kubectl apply -f prometheus-grafana-simple.yaml
kubectl get pods -n monitoring -w
```

Wait until `prometheus` and `grafana` are `Running`.

### Open UIs

**Terminal 1 — Prometheus**

```powershell
kubectl port-forward svc/prometheus -n monitoring 9090:9090
```

Open http://localhost:9090 → **Status → Targets**. You should see:

- `prometheus` — UP
- `kubernetes-pods` — pods with annotation `prometheus.io/scrape=true`
- `k8s-app-service` — if `k8s-app-service` exists in `default`

**Terminal 2 — Grafana**

```powershell
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

Open http://localhost:3000 — **admin** / **admin123**

Datasources **Prometheus** and **Loki** are pre-provisioned from the ConfigMap.

---

## Part 3 — Confirm k8s-app is scraped

Pods need these annotations (already in `deployment.yaml`):

```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "3000"
prometheus.io/path: "/metrics"
```

**PromQL examples** (Prometheus UI → Graph):

```promql
# Request rate
rate(k8s_app_http_requests_total[1m])

# p95 latency
histogram_quantile(0.95, sum(rate(k8s_app_http_request_duration_seconds_bucket[5m])) by (le))

# Pod memory (from default metrics)
k8s_app_process_resident_memory_bytes
```

**Load test** (optional — watch HPA + metrics):

```powershell
# PowerShell loop hitting the app
1..500 | ForEach-Object { Invoke-WebRequest http://app.local/ -UseBasicParsing }
```

---

## Part 4 — Grafana dashboard

1. **Connections → Data sources** → Prometheus should be default.
2. **Dashboards → New → Import**
3. Import ID **315** (Kubernetes cluster monitoring) or build a simple panel:
   - **Query:** `rate(k8s_app_http_requests_total[1m])`
   - **Visualization:** Time series
4. Add a second panel: **HPA replicas**

```promql
kube_horizontalpodautoscaler_status_current_replicas{horizontalpodautoscaler="k8s-app"}
```

> Note: HPA metric needs kube-state-metrics; if missing, use `kubectl get hpa -w` alongside Grafana.

---

## Part 5 — Centralized logging (Loki)

```powershell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install loki grafana/loki-stack `
  -n monitoring `
  -f loki-stack-values.yaml `
  --wait --timeout 5m
```

**Grafana → Explore → Loki**

```logql
{namespace="default"} |= "Server started"
```

```logql
{namespace="default"} | json | level="error"
```

**Correlate metric spike → logs:** Note timestamp in Grafana graph → same time range in Loki Explore.

---

## Part 6 — Alerting (concept)

In Prometheus, alerting rules live in a ConfigMap or Operator. Minimal example to study:

```yaml
groups:
  - name: k8s-app
    rules:
      - alert: HighErrorRate
        expr: rate(k8s_app_http_requests_total{status_code=~"5.."}[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Elevated 5xx rate on k8s-app"
```

Production teams add **Alertmanager** → Slack/PagerDuty. Your lab stops at Prometheus UI + Grafana alert rules for now.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Unable to connect to the server` | Enable Kubernetes in Docker Desktop |
| Prometheus targets DOWN for k8s-app | Rebuild image; check annotations; `kubectl exec` pod → `wget -qO- localhost:3000/metrics` |
| Grafana Loki datasource error | Install Loki helm chart; wait for `loki-0` Running |
| Image pull errors | Use `imagePullPolicy: Never` + local `k8s-app:latest` on Docker Desktop |
| No data in Grafana | Check time range (Last 15 min); verify Prometheus target UP |

---

## DevOps concepts checklist

- [ ] **Metrics** — RED: rate, errors, duration (`k8s_app_http_*`)
- [ ] **Logs** — structured JSON, centralized in Loki
- [ ] **Dashboards** — Grafana single pane of glass
- [ ] **Scrape config** — pull model, annotations on pods
- [ ] **Correlation** — same incident: graph + logs
- [ ] **HPA link** — CPU metrics → scale (from earlier lab)

---

## Next after Observe

1. **Security** — `SECURITY_HANDS_ON.md`
2. **GitOps** — deploy monitoring manifests via ArgoCD
3. **CI** — fail build if `/metrics` health check fails in integration test

---

## Quick reference

| Service | Namespace | Port-forward |
|---------|-----------|--------------|
| Prometheus | monitoring | `9090:9090` |
| Grafana | monitoring | `3000:3000` |
| Loki | monitoring | `3100:3100` (debug only) |

See also: [MONITORING_QUICK_COMMANDS.md](MONITORING_QUICK_COMMANDS.md) | [LOGGING_HANDS_ON.md](LOGGING_HANDS_ON.md)
