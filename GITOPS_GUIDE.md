# 🔄 GitOps with ArgoCD - Complete Guide

## What is GitOps?

**GitOps** = Your Git repo is the source of truth for your cluster!

```
Traditional:
User → kubectl apply deployment.yaml → Kubernetes
User remembers commands, manual process, error-prone

GitOps:
Git repo (YAML files) → ArgoCD watches → Kubernetes
Declarative, version controlled, automatic, audit trail ✅
```

---

## The Problem: Imperative Commands

```bash
# You: Deploy app
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

# Colleague: "What's deployed?"
kubectl get all  # Have to ask someone, hard to track

# Week later: Cluster state forgotten
# What version is running? Who changed it? When?
# 🤯 Nightmare!
```

---

## The Solution: GitOps

```bash
# Your Git repo has:
# myapp/
# ├─ deployment.yaml
# ├─ service.yaml
# └─ ingress.yaml

# ArgoCD watches this repo
# Every change automatically syncs to cluster!

# Deploy: git push
# Rollback: git revert
# Track changes: git log
# Audit trail: git blame
```

---

## How ArgoCD Works

```
┌─────────────────┐
│   Git Repo      │  ← Source of truth
│ deployment.yaml │  ← All YAML files versioned
│ service.yaml    │
└────────┬────────┘
         │
         │ ArgoCD polls every 3 seconds
         ↓
    ┌─────────────┐
    │   ArgoCD    │  ← Watches repo & cluster
    │  Controller │  ← Syncs if different
    └────────┬────┘
             │
             ↓
    ┌──────────────────┐
    │  Kubernetes      │  ← Actual state
    │  Cluster         │  ← Auto-updated to match Git
    └──────────────────┘

Git: deployment.yaml (replicas: 3)
Cluster: deployment.yaml (replicas: 5)
ArgoCD: "They don't match! Setting to 3..."
Result: Cluster auto-synced! ✅
```

---

## Why GitOps Matters

### ✅ Benefits

| Benefit | Why |
|---------|-----|
| **Version Control** | Every deployment tracked in Git |
| **Rollback** | `git revert` rolls back instantly |
| **Audit Trail** | `git log` shows who changed what when |
| **Collaboration** | PR review before deployment |
| **Consistency** | Same process every time |
| **Disaster Recovery** | Lost cluster? Re-apply from Git |
| **Multiple Envs** | Dev/staging/prod from same repo |
| **Automation** | No manual kubectl commands |

---

## ArgoCD Architecture

```
┌──────────────────────────────────────────────┐
│         Kubernetes Cluster (Docker Desktop)  │
├──────────────────────────────────────────────┤
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │    ArgoCD Namespace (default)           │ │
│  │                                         │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │ API Server                        │  │ │
│  │  │ (Web UI: localhost:8080)          │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │                                         │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │ Repository Server                │  │ │
│  │  │ (Watches GitHub every 3 sec)     │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │                                         │ │
│  │  ┌──────────────────────────────────┐  │ │
│  │  │ Application Controller            │  │ │
│  │  │ (Syncs cluster to Git)            │  │ │
│  │  └──────────────────────────────────┘  │ │
│  │                                         │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │    Your App Namespace                   │ │
│  │  ├─ Deployments (synced from Git)      │ │
│  │  ├─ Services                           │ │
│  │  └─ Ingress                            │ │
│  └────────────────────────────────────────┘ │
│                                              │
└──────────────────────────────────────────────┘
         ↑
         │ Watches (polls every 3 sec)
         │
    ┌────────────────┐
    │ GitHub Repo    │
    │ deployment.yaml│
    │ service.yaml   │
    └────────────────┘
```

---

## ArgoCD Workflow

```
┌─────────────┐
│   Developer │
└────────┬────┘
         │ git push deployment.yaml
         ↓
┌──────────────────────┐
│  GitHub Repo         │
│  deployment.yaml v2  │
└────────┬─────────────┘
         │
         │ ArgoCD polls (auto every 3 sec)
         ↓
┌──────────────────────┐
│  ArgoCD Detects      │
│  Change Detected     │
└────────┬─────────────┘
         │
         │ Reads new deployment.yaml
         ↓
┌──────────────────────┐
│  Applies YAML        │
│  kubectl apply       │
└────────┬─────────────┘
         │
         ↓
┌──────────────────────┐
│  Kubernetes Updates  │
│  Pods rolling update │
└────────┬─────────────┘
         │
         ↓
┌──────────────────────┐
│  ArgoCD UI Shows     │
│  "Synced ✅"         │
└──────────────────────┘
```

---

## Setup: Install ArgoCD

```powershell
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for deployment
kubectl wait -n argocd deployment/argocd-server --for=condition=available --timeout=300s

# Verify
kubectl get pods -n argocd
```

---

## Access ArgoCD UI

```powershell
# Get initial password
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | % {[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))}
Write-Host "Password: $password"

# Port-forward to local
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Access browser: https://localhost:8080
# Username: admin
# Password: (from above)
```

---

## Create Application in ArgoCD

### Method 1: Using UI

1. Click "New App"
2. **Application Name:** `myapp`
3. **Project:** `default`
4. **Sync Policy:** `Automatic`
5. **Repository URL:** `https://github.com/yourusername/app-config`
6. **Target Revision:** `main`
7. **Path:** `k8s/` (where YAML files are)
8. **Destination Cluster:** `https://kubernetes.default.svc`
9. **Destination Namespace:** `default`
10. Click "Create"

### Method 2: Using YAML

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/yourusername/app-config
    targetRevision: main
    path: k8s/  # Where YAML files are
  
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  
  syncPolicy:
    automated:
      prune: true    # Delete resources removed from Git
      selfHeal: true # Re-sync if cluster changes
    syncOptions:
    - CreateNamespace=true
```

---

## Workflow: Deploy with GitOps

### Step 1: Prepare Git Repo

```bash
# In your GitHub repo:
app-config/
├─ k8s/
│  ├─ deployment.yaml
│  ├─ service.yaml
│  └─ ingress.yaml
├─ README.md
└─ .gitignore
```

### Step 2: Create ArgoCD Application

```bash
# Point ArgoCD to your repo
# ArgoCD automatically syncs!
```

### Step 3: Deploy App

```bash
# Instead of: kubectl apply -f deployment.yaml
# Just: git push

git add k8s/deployment.yaml
git commit -m "Update image tag to v2.0"
git push origin main

# ArgoCD automatically deploys! ✅
# Check UI to see sync status
```

### Step 4: Rollback

```bash
# Instead of: kubectl rollout undo
# Just: git revert

git revert <commit-hash>
git push

# ArgoCD automatically rolls back! ✅
```

---

## Multi-Environment Setup (Dev/Staging/Prod)

```yaml
# Git repo structure:
app-config/
├─ environments/
│  ├─ dev/
│  │  ├─ kustomization.yaml
│  │  └─ patches.yaml (replicas: 1, resources: low)
│  ├─ staging/
│  │  ├─ kustomization.yaml
│  │  └─ patches.yaml (replicas: 2, resources: medium)
│  └─ prod/
│     ├─ kustomization.yaml
│     └─ patches.yaml (replicas: 5, resources: high)
└─ base/
   ├─ deployment.yaml
   ├─ service.yaml
   └─ ingress.yaml
```

**Deploy all 3:**
```powershell
# Create 3 ArgoCD Applications

# App 1: Development
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-dev
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/user/app-config
    path: environments/dev
  destination:
    namespace: dev
EOF

# App 2: Staging
# ... path: environments/staging

# App 3: Production
# ... path: environments/prod
```

---

## Best Practices

```yaml
✅ DO:
- Version all YAML files in Git
- Create repo per application
- Use separate branches for dev/staging/prod
- Review PR before merging to prod
- Track secrets separately (Sealed Secrets, External Secrets)
- Monitor ArgoCD sync status
- Keep ArgoCD updated

❌ DON'T:
- Make manual kubectl apply changes (breaks sync!)
- Store secrets in Git (unencrypted)
- Deploy directly to prod (always PR review)
- Ignore sync errors
- Point multiple apps to same path
```

---

## Troubleshooting

```powershell
# Check sync status
kubectl get applications -n argocd

# Check application details
kubectl describe application myapp -n argocd

# View detailed sync status
argocd app get myapp

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller

# Force refresh from Git
argocd app sync myapp

# View diff
argocd app diff myapp
```

---

## Integration with OTHER Tools

**ArgoCD + Helm:**
```yaml
source:
  repoURL: https://github.com/user/app-config
  path: helm/charts
  helm:
    values: values-prod.yaml
```

**ArgoCD + Kustomize:**
```yaml
source:
  repoURL: https://github.com/user/app-config
  path: kustomize/overlays/prod
```

**ArgoCD + Notifications:**
```yaml
# Slack notifications on sync
notifications:
  - name: slack
    service: slack
    channel: #deployments
    triggers:
    - on-sync-succeeded
    - on-sync-failed
```

---

## 💡 Real-World GitOps Flow

```
1. Developer: Edit deployment.yaml
2. Push: git push origin feature-branch
3. Create: GitHub PR (code review)
4. Review: Team reviews changes
5. Approve: ✅ LGTM
6. Merge: PR merged to main
7. ArgoCD: Detects change automatically
8. Deploy: Applies new YAML to cluster
9. Monitor: Watch pod updates in ArgoCD UI
10. Rollback: git revert if issues

All tracked in Git! All auditable! ✅
```

---

## 🎯 Key Benefits Over Manual kubectl

| Manual | GitOps |
|--------|--------|
| `kubectl apply` | `git push` |
| No audit trail | Full git log |
| Can manually break cluster | Self-healing (reverts manual changes) |
| Hard to reproduce | Exact repo state always deployable |
| Team confusion | Everyone sees same source of truth |
| Time to deploy: 5 min | Time to deploy: 30 seconds (automatic!) |

---

## 📊 Next Steps

**You've now covered:**
✅ StatefulSets
✅ HPA
✅ Monitoring
✅ Logging
✅ Helm
✅ Security
✅ Advanced Deployment
✅ GitOps

**Last topic:**
1. 🎯 **Backup & Disaster Recovery (Velero)**

Ready for the final topic? 🚀
