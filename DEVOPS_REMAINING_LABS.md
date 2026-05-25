# DevOps — Remaining Concepts (Hands-On Roadmap)

Complete these **6 labs** in order. Each links to theory guides already in this repo.

| # | Concept | Time | Theory guide | Lab section below |
|---|---------|------|--------------|-------------------|
| 1 | Observe (finish) | 45m | [MONITORING_GUIDE.md](MONITORING_GUIDE.md) | [Lab 1](#lab-1-observe-metrics--logs) |
| 2 | Security | 45m | [SECURITY_GUIDE.md](SECURITY_GUIDE.md) | [Lab 2](#lab-2-security-rbac--network-policies) |
| 3 | Advanced deploy | 1h | [ADVANCED_DEPLOYMENTS_GUIDE.md](ADVANCED_DEPLOYMENTS_GUIDE.md) | [Lab 3](#lab-3-blue-green--canary) |
| 4 | GitOps | 1h | [GITOPS_GUIDE.md](GITOPS_GUIDE.md) | [Lab 4](#lab-4-gitops-argocd) |
| 5 | CI/CD maturity | 30m | [CI-CD_GUIDE.md](CI-CD_GUIDE.md) | [Lab 5](#lab-5-cicd-tests--pipeline) |
| 6 | Backup & DR | 45m | [BACKUP_DISASTER_RECOVERY_GUIDE.md](BACKUP_DISASTER_RECOVERY_GUIDE.md) | [Lab 6](#lab-6-backup-velero) |

**Quick runner:** `.\run-remaining-devops.ps1`

---

## Lab 1: Observe (metrics + logs)

**Concepts:** Prometheus scrape model, PromQL, Grafana dashboards, Loki log aggregation, RED metrics.

### Fix ImagePullBackOff (do this first)

```powershell
cd "C:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"
docker pull prom/prometheus:v0.47.0
docker pull grafana/grafana:9.3.0
docker pull grafana/loki:2.9.0
docker pull grafana/promtail:2.9.0

kubectl delete pod -n monitoring -l app=prometheus
kubectl delete pod -n monitoring -l app=grafana
kubectl get pods -n monitoring -w
```

### Deploy stack

```powershell
npm install
docker build -t k8s-app:latest .
kubectl apply -f deployment.yaml -f service.yaml
kubectl set image deployment/k8s-app app=k8s-app:latest
kubectl apply -f prometheus-grafana-simple.yaml
```

### Access

```powershell
# Terminal A
kubectl port-forward svc/prometheus -n monitoring 9090:9090
# Terminal B
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

- Prometheus: http://localhost:9090 → Status → Targets  
- Grafana: http://localhost:3000 (`admin` / `admin123`)  
- PromQL: `rate(k8s_app_http_requests_total[1m])`  

### Loki (optional)

```powershell
helm upgrade --install loki grafana/loki-stack -n monitoring -f loki-stack-values.yaml --wait
```

**Done when:** Targets UP, Grafana shows request rate, Loki returns pod logs.

---

## Lab 2: Security (RBAC + Network Policies)

**Concepts:** least privilege, ServiceAccount, Role/RoleBinding, NetworkPolicy default-deny, pod security context.

```powershell
.\labs\security-apply.ps1
```

### Manual steps

```powershell
kubectl apply -f developer-role.yaml -f admin-role.yaml -f readonly-role.yaml
kubectl apply -f developer-rolebinding.yaml -f admin-rolebinding.yaml
kubectl apply -f default-deny-policy.yaml -f allow-ingress-to-web.yaml
kubectl apply -f secure-pod.yaml
kubectl apply -f db-secret.yaml -f secret-reader-role.yaml -f secret-reader-binding.yaml
```

### Verify RBAC

```powershell
# As developer — should FAIL to delete deployments
kubectl auth can-i delete deployments --as=system:serviceaccount:default:developer

# As admin — should succeed
kubectl auth can-i delete deployments --as=system:serviceaccount:default:admin-user
```

### Verify NetworkPolicy

```powershell
kubectl get networkpolicies
kubectl describe networkpolicy default-deny-all
```

**Done when:** `can-i` shows developer cannot delete; policies listed in cluster.

Full steps: [SECURITY_HANDS_ON.md](SECURITY_HANDS_ON.md)

---

## Lab 3: Blue-Green & Canary

**Concepts:** zero-downtime switch, traffic splitting, instant rollback, risk reduction.

### Blue-Green

```powershell
kubectl apply -f labs/blue-green/
kubectl get all -n blue-green
kubectl get svc -n blue-green
```

Switch production Service selector from `version: blue` to `version: green` (see [BLUEGREEN_LAB.md](BLUEGREEN_LAB.md)).

```powershell
# After switch — test green
kubectl port-forward svc/app-service -n blue-green 8080:80
curl http://localhost:8080/api/version
```

### Canary (traffic split)

```powershell
kubectl apply -f labs/canary/
```

Uses two Deployments + weighted paths via separate services or Ingress annotations.

**Done when:** You switch blue→green without downtime; canary sends partial traffic to v2.

Guides: [BLUEGREEN_LAB.md](BLUEGREEN_LAB.md) | [CANARY_LAB.md](CANARY_LAB.md)

---

## Lab 4: GitOps (ArgoCD)

**Concepts:** declarative Git source of truth, sync/reconcile, self-heal, audit trail.

### Install ArgoCD

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

### UI password & port-forward

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open https://localhost:8080 (accept cert warning). User: `admin`.

### Register your app (local path chart)

```powershell
kubectl apply -f labs/gitops/k8s-app-argocd-application.yaml
```

Change `repoURL` in that file to **your GitHub repo** when you push the project.

**Done when:** ArgoCD shows Application `Synced` and `Healthy`.

Guide: [GITOPS_GUIDE.md](GITOPS_GUIDE.md)

---

## Lab 5: CI/CD (tests + pipeline)

**Concepts:** shift-left testing, build → scan → publish, pipeline gates, deploy automation.

### Local test

```powershell
npm test
```

### GitHub Actions secrets (repo Settings → Secrets)

| Secret | Purpose |
|--------|---------|
| `DOCKER_USERNAME` | Docker Hub login |
| `DOCKER_PASSWORD` | Docker Hub token |
| `KUBE_CONFIG` | Base64 kubeconfig (optional deploy job) |

### Trigger pipeline

**If you see `fatal: not a git repository`**, run setup first: [GIT_SETUP.md](GIT_SETUP.md)

```powershell
git init
git branch -M main
git add .
git commit -m "Add health tests and DevOps labs"
git remote add origin https://github.com/YOUR_USERNAME/kubernates.git
git push -u origin main
```

Watch **Actions** tab: test → build → Trivy scan.

**Done when:** `npm test` passes locally; workflow green on push.

Guide: [CI-CD_GUIDE.md](CI-CD_GUIDE.md)

---

## Lab 6: Backup (Velero)

**Concepts:** RPO/RTO, scheduled backups, namespace restore, disaster drill.

Velero needs a storage backend (MinIO for local lab, S3 in cloud).

**If `velero` is not recognized:** install CLI first → [labs/velero/INSTALL_WINDOWS.md](labs/velero/INSTALL_WINDOWS.md)

```powershell
.\labs\velero\install-velero-cli.ps1
# New terminal:
velero version --client-only
```

### Install in cluster (overview)

```powershell
velero version

# Example: install with MinIO plugin (see BACKUP guide for full MinIO YAML)
velero install --provider aws --plugins velero/velero-plugin-for-aws:v1.8.0 `
  --bucket velero --secret-file ./labs/velero/credentials-velero `
  --use-volume-snapshots=false --backup-location-config region=minio,s3ForcePathStyle=true,s3Url=http://minio:9000
```

### Backup & restore drill

```powershell
velero backup create default-backup --include-namespaces default
velero backup describe default-backup
velero backup get

# Simulate disaster (careful!)
# kubectl delete deployment k8s-app

velero restore create --from-backup default-backup
kubectl get pods
```

**Done when:** Backup completes; restore recreates workloads.

Guide: [BACKUP_DISASTER_RECOVERY_GUIDE.md](BACKUP_DISASTER_RECOVERY_GUIDE.md)

---

## Concept map (what each part teaches)

```
┌─────────────┐
│   Develop   │  app.js, Dockerfile, npm test
└──────┬──────┘
       ▼
┌─────────────┐     Lab 5
│   CI/CD     │  GitHub Actions, Trivy scan
└──────┬──────┘
       ▼
┌─────────────┐     Lab 4
│   GitOps    │  ArgoCD sync from Git
└──────┬──────┘
       ▼
┌─────────────┐     Labs 2–3
│  Kubernetes │  Security, Blue/Green, Canary, Helm
└──────┬──────┘
       ▼
┌─────────────┐     Lab 1
│  Observe    │  Prometheus, Grafana, Loki
└──────┬──────┘
       ▼
┌─────────────┐     Lab 6
│  Recover    │  Velero backup/restore
└─────────────┘
```

---

## Certification alignment

| Lab | CKAD | CKA | CKS |
|-----|------|-----|-----|
| Observe | | ✓ | ✓ |
| Security | | ✓ | ✓✓ |
| Blue/Green | ✓ | | |
| GitOps | ✓ | ✓ | |
| CI/CD | | | |
| Backup | | ✓ | ✓ |

---

## Your checklist

- [ ] Lab 1 — Prometheus targets UP, Grafana dashboard
- [ ] Lab 2 — RBAC + NetworkPolicy applied
- [ ] Lab 3 — Blue-green switch tested
- [ ] Lab 4 — ArgoCD Application healthy
- [ ] Lab 5 — `npm test` + GitHub Actions green
- [ ] Lab 6 — Velero backup + restore drill

Start: `.\run-remaining-devops.ps1` → pick lab number.
