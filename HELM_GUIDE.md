# 📦 Helm Package Manager - Complete Guide

## What is Helm?

**Helm** = Package manager for Kubernetes (like `npm install` for Kubernetes)

```
Without Helm:
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
# 6 commands, 6 files, easy to forget one 😞

With Helm:
helm install my-app ./chart
# 1 command, everything deployed! ✅
```

---

## 🤔 Why Helm?

### Problem 1: YAML Duplication
```
# Without Helm
# deployment.yaml
replicas: 2
image: nginx:1.19
# staging.yaml (different env)
replicas: 2
image: nginx:1.19  # Same line!
# production.yaml (different env)
replicas: 5  # Only this changes
image: nginx:1.19  # Same line!

# Copy-paste nightmare! 😭
```

### Problem 2: Complex Deployments
```
# Real enterprise apps have:
- Deployment (app)
- Service (expose app)
- ConfigMap (config)
- Secret (passwords)
- Ingress (routing)
- HPA (auto-scaling)
- NetworkPolicy (security)
- RBAC stuff (permissions)
- Monitoring stuff
- Logging stuff
- Backup stuff
- ...

That's 10+ files to manage! 😱
```

### Problem 3: Sharing Configs
```
Team A: "How do you deploy PostgreSQL?"
Team B: "Here are 5 YAML files"
Team A: "Thanks! *copies them*"
3 months later...
Team B: "We improved the PostgreSQL setup"
Team A: "We have old version" 🙁

With Helm:
Team B: "Use helm install postgresql postgresql-chart"
Team A: helm install postgresql postgresql-chart
Team B: "Updated chart to v2.0!"
Team A: helm upgrade postgresql postgresql-chart
Everyone: Always up to date! ✅
```

---

## 📊 Helm Architecture

```
┌────────────────────────────────────────────────────┐
│              Helm Chart (Package)                  │
├────────────────────────────────────────────────────┤
│                                                    │
│  my-app/                                           │
│  ├─ Chart.yaml         (chart metadata)           │
│  ├─ values.yaml        (default config)           │
│  ├─ values-prod.yaml   (production overrides)     │
│  ├─ values-dev.yaml    (dev overrides)            │
│  │                                                 │
│  └─ templates/         (YAML templates)            │
│     ├─ deployment.yaml (uses {{ .Values }}        │
│     ├─ service.yaml                               │
│     ├─ configmap.yaml                             │
│     ├─ secret.yaml                                │
│     ├─ ingress.yaml                               │
│     └─ hpa.yaml                                   │
│                                                    │
└────────────────────────────────────────────────────┘
              ↓ helm install -f values-prod.yaml
┌────────────────────────────────────────────────────┐
│    Rendered YAML (ready for Kubernetes)            │
├────────────────────────────────────────────────────┤
│ (All {{ .Values }} replaced with actual values)   │
└────────────────────────────────────────────────────┘
```

---

## 🔑 Key Concepts

### 1. **Chart**
A package containing all files to deploy an app.

```
my-app.tar.gz  ← This is a Helm chart
  ├─ Chart.yaml (metadata)
  ├─ values.yaml (configuration)
  └─ templates/ (YAML files)
```

### 2. **Release**
A specific deployment of a chart.

```
Chart: "WordPress (template)"
Release: "blog.example.com" ← Running instance
Release: "internal-wiki"    ← Different instance, same chart
Release: "docs"             ← Another instance

One chart → Many releases!
```

### 3. **Values**
Configuration variables used in templates.

```yaml
# values.yaml (defaults)
replicas: 2
image:
  repository: nginx
  tag: latest
resources:
  requests:
    cpu: 100m
    memory: 128Mi

# Overrides at install time:
# helm install my-app ./chart --set replicas=5
# Result: Use 5 replicas instead of 2!
```

---

## 🎯 Template Example

### Before (Static YAML)
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2          # Hardcoded! ❌
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.19  # Hardcoded! ❌
        resources:
          requests:
            cpu: 100m      # Hardcoded! ❌
            memory: 128Mi  # Hardcoded! ❌
```

### After (Helm Template)
```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
spec:
  replicas: {{ .Values.replicas }}
  template:
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        resources:
          requests:
            cpu: {{ .Values.resources.requests.cpu }}
            memory: {{ .Values.resources.requests.memory }}
```

```yaml
# values.yaml
replicas: 2
image:
  repository: nginx
  tag: 1.19
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

**Usage:**
```bash
# Default values
helm install my-app ./chart

# Override for production
helm install prod-app ./chart -f values-production.yaml

# Override specific value
helm install test-app ./chart --set replicas=1
```

---

## 🏪 Public Helm Charts

Instead of creating your own, use existing charts!

**ArtifactHub.io** - Repository of 10,000+ charts

```bash
# Find and add repos
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus https://prometheus-community.github.io/helm-charts
helm repo update

# List available charts
helm search repo postgresql
helm search repo prometheus
helm search repo mysql

# Install from public repository
helm install my-db bitnami/postgresql

# Install specific version
helm install my-db bitnami/postgresql --version 12.1.0
```

**Popular public charts:**
- `bitnami/postgresql` - PostgreSQL database
- `bitnami/mysql` - MySQL database
- `prometheus-community/kube-prometheus-stack` - Prometheus + Grafana
- `nginx-stable/nginx-ingress` - Nginx Ingress
- `jetstack/cert-manager` - SSL certificates
- `argo/argo-cd` - ArgoCD (GitOps)

---

## 💻 Common Helm Commands

```bash
# Create a new chart
helm create my-chart

# Install a release
helm install my-release ./my-chart
helm install my-release bitnami/postgresql

# Install with custom values
helm install my-app ./chart -f values-prod.yaml
helm install my-app ./chart --set replicas=5

# List releases
helm list

# Upgrade release to new version
helm upgrade my-release ./chart

# Upgrade release with new values
helm upgrade my-app ./chart --set image.tag=v2.0

# Rollback to previous version
helm rollback my-release

# Delete release
helm uninstall my-release

# Check what will be deployed
helm install my-app ./chart --dry-run --debug

# Get release status
helm status my-release

# Show values used in release
helm show values ./chart
```

---

## 📊 Helm in Practice

### Your Current Setup (Without Helm)

```bash
# You'd need to manually manage:
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f configmap.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
kubectl apply -f postgresql-complete.yaml
# ... many more files

# To upgrade app:
# Edit deployment.yaml → change image tag
# kubectl apply -f deployment.yaml

# To scale for production:
# Copy all files → modify replicas, resource limits
# kubectl apply -f everything.yaml
```

### With Helm (Clean & Simple)

```bash
# Install everything
helm install k8s-app ./k8s-app-chart

# Upgrade app
helm upgrade k8s-app ./k8s-app-chart --set image.tag=v2.0

# Production deployment (different replicas)
helm install prod-app ./k8s-app-chart -f values-production.yaml

# Staging deployment
helm install staging-app ./k8s-app-chart -f values-staging.yaml

# Easy! ✅
```

---

## 🎯 Your Helm Journey

### What we'll do:
1. Create a Helm chart for your k8s-app
2. Put all 5 YAML files into chart
3. Use values.yaml to configure replicas
4. Deploy with `helm install`
5. Upgrade with `helm upgrade`

### Time: 45 minutes
### Difficulty: ⭐⭐ Easy (but game-changing!)

---

## 🚀 Real-World Helm Usage

### Scenario 1: Deploy Multiple Environments

```bash
# Development (1 replica, low resources)
helm install dev-api ./api-chart -f environments/dev.yaml

# Staging (2 replicas, medium resources)
helm install staging-api ./api-chart -f environments/staging.yaml

# Production (5 replicas, high resources, HA)
helm install prod-api ./api-chart -f environments/production.yaml

# All from same chart! ✅
```

### Scenario 2: Share Charts with Team

```bash
# Team member: "How do you deploy the app?"
# You: "helm install -f my-values.yaml"
# They: helm install ...
# Done! Everyone has same setup ✅

# 3 months later, you improve the setup
# They: helm upgrade
# Automatic update! ✅
```

### Scenario 3: Manage Complex App

```yaml
# One chart deploys:
- Frontend (React app)
- Backend API (goes in Pod)
- PostgreSQL (database)
- Redis (cache)
- Elasticsearch (search)
- Monitoring (Prometheus + Grafana)

helm install myapp ./myapp-chart
# EVERYTHING deployed with 1 command! 🎉
```

---

## 🔍 Helm Best Practices

```yaml
✅ DO:
- Use public charts when possible
- Store values files in Git
- Version your charts
- Document your values
- Use multiple values files for environments
- Handle secrets securely

❌ DON'T:
- Hardcode values in templates
- Create charts if public one exists
- Store secrets in values.yaml (use Sealed Secrets)
- Mix multiple apps in one chart
- Ignore chart health
```

---

## 📚 Chart Directory Structure

```
my-app-chart/
├─ Chart.yaml              (metadata: name, version)
├─ values.yaml             (default configuration)
├─ values-development.yaml (dev overrides)
├─ values-production.yaml  (prod overrides)
├─ README.md               (how to use)
│
├─ templates/
│  ├─ deployment.yaml      (uses {{ .Values }})
│  ├─ service.yaml
│  ├─ configmap.yaml
│  ├─ ingress.yaml
│  ├─ hpa.yaml
│  ├─ NOTES.txt            (post-install messages)
│  └─ _helpers.tpl         (template helpers)
│
└─ charts/                 (dependency charts)
   └─ postgresql/          (if using PostgreSQL)
```

---

## 💡 Why Helm is Essential

- ✅ **Used by 90% of Kubernetes teams**
- ✅ **10,000+ public charts** (don't reinvent wheel)
- ✅ **Easy configuration management**
- ✅ **Simple upgrades & rollbacks**
- ✅ **Team collaboration**
- ✅ **Infrastructure as Code friendly**

---

## 🎯 Next: Hands-On Lab

Ready to package your app with Helm?

Move to: **HELM_HANDS_ON.md** (coming next!)

You'll:
1. Create a Helm chart from scratch
2. Package your k8s-app
3. Deploy with `helm install`
4. Upgrade with `helm upgrade`
5. Use values to configure environments

**Time:** 45 minutes
**Impact:** Never manually manage YAML files again!

Let's go! 🚀
