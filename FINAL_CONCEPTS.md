# Final DevOps concepts — what is left

## Your progress

| Concept | Status |
|---------|--------|
| Docker + K8s + Ingress | Done |
| StatefulSets + HPA + Helm | Done |
| Security (RBAC + NetPol) | Done |
| Blue-Green + Canary | Deployed |
| Git push + CI workflow file | Done |
| GitOps (ArgoCD) | Installed — sync **Unknown** (finish today) |
| Observe (Prometheus) | Grafana OK — Prometheus **ImagePullBackOff** |
| Backup (Velero) | CLI only — cluster install later |

---

## Run menu (PowerShell only)

```powershell
cd "C:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"
.\FINAL_DEVOPS_LABS.ps1
```

Pick `1`–`6`. Do **not** paste URLs or English text into PowerShell.

---

## Concept 1 — GitOps (ArgoCD) — finish sync

```powershell
kubectl apply -f labs/gitops/k8s-app-argocd-application.yaml
kubectl get application k8s-app -n argocd
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

**Browser:** https://localhost:8443  
Login: `admin` + password from:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

**UI clicks:** Applications → k8s-app → Refresh → Sync

---

## Concept 2 — CI/CD (GitHub Actions)

**Browser:** https://github.com/TejasDB04/Devops/settings/secrets/actions  
Add secrets: `DOCKER_USERNAME`, `DOCKER_PASSWORD`

**PowerShell:**

```powershell
npm test
git add .
git commit -m "CI pipeline update"
git push origin main
```

**Browser:** https://github.com/TejasDB04/Devops/actions

---

## Concept 3 — Observe (fix Prometheus pull)

```powershell
docker pull prom/prometheus:v0.47.0
docker pull grafana/grafana:9.3.0
kubectl delete pod -n monitoring -l app=prometheus
kubectl get pods -n monitoring
```

**Terminal A:**

```powershell
kubectl port-forward svc/prometheus -n monitoring 9090:9090
```

**Terminal B:**

```powershell
kubectl port-forward svc/grafana -n monitoring 3001:3000
```

**Browser:** http://localhost:9090 and http://localhost:3001

---

## Concept 4 — Blue-Green (practice)

```powershell
.\labs\blue-green\switch-to-green.ps1
kubectl port-forward svc/app-production -n blue-green 8888:80
```

**Browser:** http://localhost:8888/api/version

```powershell
.\labs\blue-green\rollback-to-blue.ps1
```

---

## Concept 5 — Canary

**Terminal 1:**

```powershell
kubectl port-forward svc/canary-stable -n canary 8081:80
```

**Terminal 2:**

```powershell
kubectl port-forward svc/canary-new -n canary 8082:80
```

---

## Concept 6 — Backup (Velero) — later

```powershell
velero version --client-only
```

Read: `labs/velero/INSTALL_WINDOWS.md` and `BACKUP_DISASTER_RECOVERY_GUIDE.md`

---

## After these — advanced topics (reading)

| Topic | Purpose |
|-------|---------|
| **cert-manager** | Auto TLS for Ingress |
| **Sealed Secrets** | Secrets safe in Git |
| **Terraform** | Create cluster/IaC |
| **OpenTelemetry** | Distributed tracing |

Certs path: CKAD → CKA → CKS
