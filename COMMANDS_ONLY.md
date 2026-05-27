# Commands only — do NOT paste guide text into PowerShell

**Rule:** If a line is not in a `powershell` code block below, it is an **instruction** (browser/UI), not a command.

---

## What went wrong

| You typed in PowerShell | Why it failed |
|-------------------------|---------------|
| `https://localhost:8080` | URLs open in **browser**, not terminal |
| `User: admin` | Login info for **browser**, not a command |
| `Open app k8s-app → Refresh` | **UI steps**, not commands |
| `Check the Actions tab` | Read in **browser** |
| `DOCKER_USERNAME` | Secret **name** on GitHub website |
| `Blue-Green switch + rollback` | Description, not a command |
| `port-forward ... 8080:443` twice | Port **8080 already in use** |

**Git push worked** — that part is correct.

---

## ArgoCD UI (fix port 8080 busy)

### Option A — use port 8443

```powershell
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

Leave terminal open. Open **Edge/Chrome** and go to:

`https://localhost:8443`

Login:
- User: `admin`
- Password: (from command below)

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

In the UI (mouse clicks, not terminal):
1. Click **Applications**
2. Click **k8s-app**
3. Click **Refresh**
4. Click **Sync**

### Option B — free port 8080 first

```powershell
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object OwningProcess
# Stop the process using 8080 (often an old port-forward), or use 8443 above
```

### Option C — one script

```powershell
.\RUN_THESE_COMMANDS.ps1
```

---

## Blue-Green (real commands only)

```powershell
cd "C:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"
kubectl get pods -n blue-green
.\labs\blue-green\switch-to-green.ps1
kubectl port-forward svc/app-production -n blue-green 8888:80
```

Browser: `http://localhost:8888/api/version`

```powershell
.\labs\blue-green\rollback-to-blue.ps1
```

---

## Canary (real commands only)

```powershell
kubectl get pods -n canary
kubectl port-forward svc/canary-stable -n canary 8081:80
```

New terminal:

```powershell
kubectl port-forward svc/canary-new -n canary 8082:80
```

Browser: `http://localhost:8081` and `http://localhost:8082`

---

## GitHub Actions secrets (website, NOT terminal)

1. Open browser: https://github.com/TejasDB04/Devops/settings/secrets/actions
2. Click **New repository secret**
3. Name: `DOCKER_USERNAME` → Value: your Docker Hub username
4. Name: `DOCKER_PASSWORD` → Value: Docker Hub **access token** (not password)

Then in PowerShell only:

```powershell
git push origin main
```

Check pipeline in browser: https://github.com/TejasDB04/Devops/actions

---

## ArgoCD sync from terminal (no UI)

```powershell
kubectl apply -f labs/gitops/k8s-app-argocd-application.yaml
kubectl get application k8s-app -n argocd
```

---

## Quick reference

| Goal | PowerShell | Browser |
|------|------------|---------|
| ArgoCD | `kubectl port-forward ... 8443:443` | https://localhost:8443 |
| App test | `kubectl port-forward ... 8888:80` | http://localhost:8888 |
| GitHub CI | `git push` | github.com/.../actions |
| Secrets | — | github.com/.../settings/secrets |
