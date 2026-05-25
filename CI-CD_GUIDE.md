# 🚀 CI/CD PIPELINE GUIDE - GITHUB ACTIONS

## What is CI/CD?

**CI (Continuous Integration):**
- Automatically test code on every push
- Catch bugs early
- Maintain code quality

**CD (Continuous Deployment):**
- Automatically build Docker image
- Push to registry
- Deploy to Kubernetes

**Results:** Code changes → Automatically deployed in minutes ⚡

---

## 📋 SETUP STEPS

### **Step 1: Create GitHub Repository**

```bash
# If not already on GitHub, push your code:
git init
git remote add origin https://github.com/YOUR_USERNAME/kubernates.git
git add .
git commit -m "Initial commit"
git branch -M main
git push -u origin main
```

---

### **Step 2: Create Docker Hub Account**

1. Go to https://hub.docker.com
2. Sign up (free account)
3. Create a Personal Access Token:
   - Account Settings → Security → New Access Token
   - Name: `github-actions`
   - Copy the token

---

### **Step 3: Add GitHub Secrets**

GitHub Actions needs credentials to push Docker images:

1. Go to **GitHub repository**
2. Settings → Secrets and variables → Actions
3. Click **New repository secret**
4. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Your Docker Hub access token (NOT password) |
| `KUBE_CONFIG` | (Optional) Base64-encoded kubeconfig |

**How to encode kubeconfig:**
```bash
# Linux/Mac
cat ~/.kube/config | base64 -w0

# Windows PowerShell
[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content $PROFILE\..\..\.kube\config -Raw))) | Set-Clipboard
```

---

### **Step 4: Update CI/CD Workflow**

Edit `.github/workflows/ci-cd.yml` and update:

```yaml
env:
  REGISTRY: docker.io
  IMAGE_NAME: YOUR_USERNAME/kubernates-app  # Change to your username
  DOCKER_BUILDKIT: 1
```

---

### **Step 5: Push to GitHub**

```bash
git add .github/workflows/ci-cd.yml
git commit -m "Add GitHub Actions CI/CD pipeline"
git push origin main
```

---

## 🔄 WORKFLOW EXPLAINED

The pipeline has **5 jobs** that run automatically:

### **Job 1: TEST** ✅
```yaml
- Checkout code
- Install Node.js
- Run npm install
- Run linter (npm run lint)
- Run tests (npm test)
```

**Why:** Catch bugs before building image

### **Job 2: BUILD & PUSH IMAGE** 🐳
```yaml
- Set up Docker Buildx (multi-platform builds)
- Log in to Docker Hub
- Extract image tags (version, branch, SHA)
- Build Docker image
- Push to Docker Hub with caching
```

**Result:** Image available at:
```
docker.io/YOUR_USERNAME/kubernates-app:latest
docker.io/YOUR_USERNAME/kubernates-app:main
docker.io/YOUR_USERNAME/kubernates-app:sha-abc123
```

### **Job 3: SECURITY SCAN** 🔒
```yaml
- Run Trivy vulnerability scanner
- Check for security issues
- Upload results to GitHub Security tab
```

**Why:** Catch security vulnerabilities early

### **Job 4: DEPLOY** (Optional) 🚀
```yaml
- Configure kubectl
- Update Kubernetes deployment
- Verify rollout
- Check pod status
```

**Only runs when:**
- Branch is `main`
- It's a push (not pull request)
- Previous jobs succeeded

### **Job 5: NOTIFY** 📢
```yaml
- Report final status
- Show image name and tag
```

---

## 🧪 TESTING THE PIPELINE

### **Method 1: Push Code to GitHub**

```bash
# Make a change to app.js
# e.g., update version to 2.0.0

git add app.js
git commit -m "Update version to 2.0.0"
git push origin main
```

### **Method 2: Watch Pipeline in Action**

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select the latest workflow run
4. Watch each job complete:
   - ✅ Test
   - ✅ Build & Push Image
   - ✅ Security Scan
   - ✅ Deploy (if configured)
   - ✅ Notify

---

## 📊 PIPELINE TRIGGERS

The pipeline runs when:

```yaml
on:
  push:
    branches:
      - main        # Push to main branch
      - develop     # Push to develop branch
  pull_request:
    branches:
      - main        # Pull request to main
```

**Add more triggers:**
```yaml
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  
  workflow_dispatch:      # Manual trigger from UI
```

---

## 🐳 IMAGE TAGGING STRATEGY

Your images will be tagged as:

```
YOUR_USERNAME/kubernates-app:latest           # Always latest (main branch)
YOUR_USERNAME/kubernates-app:main             # Current main branch
YOUR_USERNAME/kubernates-app:develop          # Develop branch
YOUR_USERNAME/kubernates-app:sha-abc123       # Specific commit hash
YOUR_USERNAME/kubernates-app:v1.0.0           # Semantic version (if tagged)
```

**To use semantic versioning:**
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 🛑 OPTIONAL: DEPLOY TO KUBERNETES

To enable auto-deployment to your cluster:

### **Create kubeconfig secret:**

```bash
# Get your kubeconfig
cat ~/.kube/config | base64 > kube-config.b64

# Add to GitHub secrets as KUBE_CONFIG
# (paste the contents of kube-config.b64)
```

### **Update deployment:**

Edit `.github/workflows/ci-cd.yml`:

```yaml
deploy:
  needs: build
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'  # Only deploy main
  
  steps:
  - name: Configure kubectl
    run: |
      mkdir -p $HOME/.kube
      echo "${{ secrets.KUBE_CONFIG }}" | base64 --decode > $HOME/.kube/config
  
  - name: Update deployment
    run: |
      kubectl set image deployment/k8s-app-deployment \
        app=docker.io/YOUR_USERNAME/kubernates-app:latest
```

---

## 🔐 SECURITY BEST PRACTICES

1. **Never commit secrets:**
   ```bash
   # Add to .gitignore
   .env
   secrets/
   kubeconfig
   *.key
   *.crt
   ```

2. **Use Personal Access Tokens (not passwords):**
   - More secure
   - Can be revoked easily
   - Limited permissions

3. **Enable branch protection:**
   - Require all checks to pass before merge
   - Require code review

4. **Use artifact scanning:**
   - Trivy already included
   - Catches vulnerabilities

---

## 📝 WORKFLOW YAML REFERENCE

```yaml
name: Build & Deploy             # Workflow name
on:                              # Triggers
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:                             # Environment variables
  REGISTRY: docker.io
  IMAGE_NAME: user/app

jobs:                            # Collection of jobs
  test:                          # Job name
    runs-on: ubuntu-latest       # Runner environment
    steps:                       # List of steps
    - uses: actions/checkout@v4  # Use action from marketplace
    - run: npm install           # Run shell command
    - run: npm test

  build:
    needs: test                  # Depends on test job
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
    - uses: docker/login-action@v3  # Login to registry
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - uses: docker/build-push-action@v5  # Build & push
      with:
        context: .               # Build context
        push: true              # Push to registry
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
```

---

## 🚀 NEXT STEPS

1. ✅ Create GitHub repository
2. ✅ Create Docker Hub account
3. ✅ Add GitHub secrets (DOCKER_USERNAME, DOCKER_PASSWORD)
4. ✅ Update Image name in workflow
5. ✅ Commit & push to main branch
6. ✅ Watch Actions tab for pipeline run
7. ✅ Verify image in Docker Hub
8. ✅ (Optional) Configure Kubernetes deployment

---

## 🐛 TROUBLESHOOTING

**Pipeline fails at "Log in to Docker Hub":**
```
❌ Solution: Check DOCKER_USERNAME and DOCKER_PASSWORD secrets are correct
```

**Build fails with "node:18-alpine not found":**
```
❌ Solution: Check internet connection or Docker Hub is accessible
```

**Deployment fails:**
```
❌ Solution: Verify KUBE_CONFIG secret is valid and correctly encoded
```

**Check logs:**
1. Go to Actions → Click failed workflow
2. Click job that failed
3. Expand steps to see error details

---

## ✅ SUCCESS CHECKLIST

- [ ] GitHub repository created
- [ ] Docker Hub account created
- [ ] DOCKER_USERNAME secret added
- [ ] DOCKER_PASSWORD secret added
- [ ] IMAGE_NAME updated in workflow
- [ ] Code committed & pushed to main
- [ ] GitHub Actions workflow runs successfully
- [ ] Image visible in Docker Hub
- [ ] Test job passes
- [ ] Build job completes
- [ ] Security scan completes
- [ ] (Optional) Deployment works

**Once all checked ✅ - celebrate! You have full CI/CD!** 🎉

---

## 💡 ADVANCED: MANUAL WORKFLOW TRIGGER

To test without pushing code:

1. Go to **Actions** tab
2. Select workflow (Build & Deploy)
3. Click **Run workflow**
4. Select branch
5. Click **Run**

This triggers the pipeline immediately!

---

## 📚 NEXT SESSIONS

- Session 3: Helm Charts (package everything)
- Session 4: Monitoring Stack (Prometheus + Grafana)
- Session 5: GitOps (ArgoCD - automatic deployments)
