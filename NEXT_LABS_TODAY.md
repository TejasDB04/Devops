# Next labs after Security

Security done. Continue in this order.

---

## Lab A — Blue-Green (already deployed — practice switch)

```powershell
cd "C:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"
kubectl get pods -n blue-green
kubectl get svc app-production -n blue-green -o yaml | Select-String "version"
```

**Traffic on BLUE (default):**

```powershell
kubectl port-forward svc/app-production -n blue-green 8080:80
```

Open: http://localhost:8080/api/version

**Switch to GREEN:**

```powershell
.\labs\blue-green\switch-to-green.ps1
kubectl port-forward svc/app-production -n blue-green 8080:80
```

**Rollback to BLUE:**

```powershell
.\labs\blue-green\rollback-to-blue.ps1
```

---

## Lab B — Canary (already deployed — compare traffic)

```powershell
kubectl get pods -n canary
kubectl port-forward svc/canary-stable -n canary 8081:80
kubectl port-forward svc/canary-new -n canary 8082:80
```

Stable: http://localhost:8081/api/health  
Canary: http://localhost:8082/api/health  

Scale canary up:

```powershell
kubectl scale deployment app-canary -n canary --replicas=2
```

---

## Lab C — GitOps (ArgoCD) — do this today

### 1. Fix app repo URL (if still wrong)

```powershell
kubectl apply -f labs/gitops/k8s-app-argocd-application.yaml
```

### 2. Refresh sync

```powershell
kubectl get applications -n argocd
argocd app sync k8s-app
```

If `argocd` CLI not installed, use UI or:

```powershell
kubectl patch application k8s-app -n argocd --type merge -p "{\"metadata\":{\"annotations\":{\"argocd.argoproj.io/refresh\":\"hard\"}}}"
```

### 3. ArgoCD UI

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

https://localhost:8080 — user `admin`

**Done when:** Application shows **Synced** + **Healthy**.

---

## Lab D — CI/CD (GitHub Actions)

1. https://github.com/TejasDB04/Devops → **Settings** → **Secrets** → **Actions**
2. Add `DOCKER_USERNAME` and `DOCKER_PASSWORD`
3. Push to trigger pipeline:

```powershell
git add .
git commit -m "Trigger CI pipeline"
git push origin main
```

4. Check **Actions** tab on GitHub.

---

## Lab E — Backup (optional, later)

```powershell
velero version --client-only
```

See `BACKUP_DISASTER_RECOVERY_GUIDE.md` for cluster install.
