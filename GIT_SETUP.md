# Git setup for CI/CD (fix: not a git repository)

## One-time setup

```powershell
cd "C:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"

git init
git branch -M main
git add .
git status
git commit -m "DevOps labs and health tests"
```

## Connect to GitHub

1. Create a new repo on https://github.com/new (name: `kubernates`, **no** README/license — empty repo).
2. Run (example for repo **Devops** under **TejasDB04**):

```powershell
git remote remove origin
git remote add origin https://github.com/TejasDB04/Devops.git
git push -u origin main
```

If `origin` already exists, use `set-url` instead of `add`:

```powershell
git remote set-url origin https://github.com/TejasDB04/Devops.git
```

## GitHub Actions secrets (for CI/CD pipeline)

Repo → **Settings** → **Secrets and variables** → **Actions** → New repository secret:

| Name | Value |
|------|--------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token |

Optional (only if deploy job should run):

| Name | Value |
|------|--------|
| `KUBE_CONFIG` | Base64 kubeconfig: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.kube\config"))` |

## Update ArgoCD app repo URL

Edit `labs/gitops/k8s-app-argocd-application.yaml`:

```yaml
repoURL: https://github.com/YOUR_USERNAME/kubernates.git
```

Then apply after ArgoCD is installed.
