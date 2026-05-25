# 🚀 Complete Kubernetes & Docker Learning Journey

## Date: March 26, 2026
## Duration: Full Day Learning Session
## Status: ✅ COMPLETED - Beginner to Intermediate Level

---

## 📋 Table of Contents
1. [What You Learned](#what-you-learned)
2. [Architecture Built](#architecture-built)
3. [Files Created](#files-created)
4. [All Commands Used](#all-commands-used)
5. [Key Concepts](#key-concepts)
6. [Troubleshooting Guide](#troubleshooting-guide)
7. [Next Steps](#next-steps)

---

## ✅ What You Learned

### Day 1 Accomplishments:

| Topic | Status | Time |
|-------|--------|------|
| Docker Installation & Setup | ✅ Complete | 30 min |
| Understanding Docker Images | ✅ Complete | 20 min |
| Kubernetes Cluster Setup | ✅ Complete | 45 min |
| Deployments (Single Pod) | ✅ Complete | 30 min |
| Services & Networking | ✅ Complete | 25 min |
| Health Checks (Liveness/Readiness) | ✅ Complete | 20 min |
| Resource Limits & Requests | ✅ Complete | 15 min |
| Persistent Storage (PV/PVC) | ✅ Complete | 40 min |
| ConfigMaps (Configuration) | ✅ Complete | 15 min |
| Secrets (Sensitive Data) | ✅ Complete | 15 min |
| Zero-Downtime Deployments | ✅ Complete | 30 min |
| Rolling Updates & Rollbacks | ✅ Complete | 20 min |
| Multi-Namespace Management | ✅ Complete | 35 min |
| Pod Debugging & Troubleshooting | ✅ Complete | 25 min |
| **Total Learning Time** | **✅ 6+ hours** | |

---

## 🏗️ Architecture Built

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│             (Docker Desktop on Windows 11)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │  Default NS      │  │  Staging NS      │ Prod NS        │
│  ├──────────────────┤  ├──────────────────┤               │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │               │
│  │ │ Deployment   │ │  │ │ Deployment   │ │               │
│  │ │ k8s-app (2)  │ │  │ │ k8s-app (2)  │ │               │
│  │ └──────────────┘ │  │ └──────────────┘ │               │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │               │
│  │ │ Service      │ │  │ │ Service      │ │               │
│  │ │ LoadBalancer │ │  │ │ LoadBalancer │ │               │
│  │ └──────────────┘ │  │ └──────────────┘ │               │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │               │
│  │ │ PVC: my-pvc  │ │  │ │ PVC: my-pvc  │ │               │
│  │ └──────────────┘ │  │ └──────────────┘ │               │
│  │ ConfigMap        │  │ ConfigMap        │               │
│  │ Secret           │  │ Secret           │               │
│  └──────────────────┘  └──────────────────┘               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
         │
         ├─ Persistent Volume (my-pv)
         └─ External Access (Port 80)
```

---

## 📁 Files Created

```
kubernates/
├── app.js                    # Node.js Express application
├── package.json              # NPM dependencies
├── Dockerfile                # Docker image definition
├── .dockerignore              # Exclude files from build
├── deployment.yaml           # Kubernetes deployment config
├── service.yaml              # Kubernetes service config
├── pv.yaml                   # PersistentVolume
├── pvc.yaml                  # PersistentVolumeClaim
├── ingress.yaml              # Ingress rules (created)
├── GUIDE.md                  # Beginner's guide
└── SUMMARY.md               # This file
```

---

## 🔧 All Commands Used

### Docker Commands

```bash
# Build Docker image
docker build -t k8s-app:latest .
docker build -t k8s-app:v2.0 .

# List images
docker images

# Run container locally (test)
docker run -d -p 3000:3000 --name test-app k8s-app:latest

# Stop/remove container
docker stop test-app
docker rm test-app

# Remove image
docker rmi k8s-app:latest
```

### Kubernetes Cluster Commands

```bash
# Check cluster
kubectl cluster-info
kubectl get nodes

# Switch context
kubectl config use-context docker-desktop
kubectl config current-context
```

### Deployment Commands

```bash
# Apply YAML files
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml

# Apply to namespaces
kubectl apply -f deployment.yaml -n staging
kubectl apply -f deployment.yaml -n production

# Delete resources
kubectl delete deployment k8s-app
kubectl delete svc k8s-app-service
```

### Pod Management

```bash
# List pods
kubectl get pods
kubectl get pods -n staging
kubectl get pods -A                  # All namespaces

# Pod details
kubectl describe pod <pod-name>
kubectl logs -f <pod-name>          # Stream logs

# Execute in pod
kubectl exec -it <pod-name> -- /bin/sh

# Port forwarding
kubectl port-forward pod/<name> 8080:3000
kubectl port-forward svc/k8s-app-service 8080:80
```

### Deployment Updates (Zero-Downtime)

```bash
# Rolling update
kubectl set image deployment/k8s-app app=k8s-app:v2.0

# Check status
kubectl rollout status deployment/k8s-app

# View history
kubectl rollout history deployment/k8s-app

# Rollback
kubectl rollout undo deployment/k8s-app
```

### Scaling

```bash
# Scale deployment
kubectl scale deployment k8s-app --replicas=5

# Watch pods scale
kubectl get pods --watch
```

### Namespace Commands

```bash
# Create namespace
kubectl create namespace staging
kubectl create namespace production

# List namespaces
kubectl get namespaces

# Switch namespace context
kubectl config set-context --current --namespace=staging

# Delete namespace
kubectl delete namespace staging
```

### Configuration Management

```bash
# ConfigMap
kubectl create configmap app-config \
  --from-literal=LOG_LEVEL=debug \
  --from-literal=ENV=prod

kubectl get configmap
kubectl describe configmap app-config

# Secret
kubectl create secret generic app-secret \
  --from-literal=PASSWORD=secret123

kubectl get secret
kubectl describe secret app-secret
```

### Persistent Storage

```bash
# Check volumes
kubectl get pv                  # PersistentVolumes
kubectl get pvc                 # PersistentVolumeClaims

# Describe
kubectl describe pv my-pv
kubectl describe pvc my-pvc
```

### Debugging & Monitoring

```bash
# Get all resources
kubectl get all
kubectl get all -A

# Events
kubectl get events

# Details
kubectl describe node
kubectl describe pod <pod-name>
```

---

## 🎓 Key Concepts Explained

### Docker
- **Image**: Blueprint (like a class)
- **Container**: Running instance (like an object)
- **Dockerfile**: Instructions to build image
- **Registry**: Storage for images (Docker Hub, etc.)

### Kubernetes
- **Pod**: Smallest unit, runs container(s)
- **Deployment**: Manages multiple pod replicas
- **Service**: Networking/load balancing for pods
- **Namespace**: Logical cluster isolation
- **PVC**: Persistent storage request
- **ConfigMap**: Non-secret configuration data
- **Secret**: Sensitive data (passwords, keys, etc.)

### Zero-Downtime Deployment
- Rolling update: Gradually replace old pods
- Health checks: Only ready pods get traffic
- Liveness probe: Restart unhealthy pods
- Readiness probe: Mark pod ready/not ready

---

## 🐛 Troubleshooting Guide

### Docker Daemon Not Running
```bash
# Solution: Start Docker Desktop
# Search "Docker Desktop" in Windows and launch
```

### Kubernetes Not Responding
```bash
# Solution: Enable Kubernetes in Docker Desktop
# Settings → Kubernetes → Enable Kubernetes → Apply & Restart
```

### Pods Not Starting (ImagePullBackOff)
```bash
# Solution: Check image name matches deployment
kubectl describe pod <pod-name>
# Rebuild with correct name: docker build -t k8s-app:latest .
```

### Pods in Pending State
```bash
# Check PVC binding
kubectl get pvc
# Ensure PV exists: kubectl get pv
```

### Port-Forward Not Working
```bash
# Wait for pod to be Running
kubectl get pods

# Use correct syntax
kubectl port-forward svc/k8s-app-service 8080:80
```

### Namespace Mismatch Error
```bash
# Remove hardcoded: namespace: default
# Use -n flag instead: kubectl apply -f file.yaml -n staging
```

---

## 📊 Commands Summary Table

| Task | Command |
|------|---------|
| Build image | `docker build -t k8s-app:latest .` |
| Deploy | `kubectl apply -f deployment.yaml` |
| Scale to 5 pods | `kubectl scale deployment k8s-app --replicas=5` |
| Update image | `kubectl set image deployment/k8s-app app=k8s-app:v2.0` |
| View logs | `kubectl logs -f <pod-name>` |
| Enter pod | `kubectl exec -it <pod-name> -- /bin/sh` |
| Port forward | `kubectl port-forward svc/k8s-app-service 8080:80` |
| Rollback | `kubectl rollout undo deployment/k8s-app` |
| Create namespace | `kubectl create namespace staging` |
| Delete all in ns | `kubectl delete all --all -n default` |

---

## 🎯 Next Steps to Learn

### Beginner (You are here ✅)
- ✅ Docker basics
- ✅ Kubernetes clusters
- ✅ Deployments & Services
- ✅ Persistent storage
- ✅ ConfigMaps & Secrets

### Intermediate (Next)
1. **Ingress** - HTTP routing
2. **StatefulSets** - Databases with state
3. **Jobs/CronJobs** - Batch processing
4. **Helm Charts** - Package management

### Advanced (Future)
1. **RBAC** - User access control
2. **Network Policies** - Security firewalls
3. **Service Mesh** (Istio) - Advanced networking
4. **Monitoring** (Prometheus) - Metrics & alerts
5. **CI/CD** - GitOps, ArgoCD

---

## 🚀 Quick Reference Card

```bash
# Essential one-liners
kubectl apply -f file.yaml              # Deploy
kubectl get pods                         # List pods
kubectl delete pod <name>                # Delete pod
kubectl logs -f <pod>                    # View logs
kubectl exec -it <pod> -- /bin/sh       # Enter pod
kubectl port-forward svc/<svc> 8080:80  # Access locally
kubectl scale deployment/<name> --replicas=3  # Scale
kubectl set image deployment/<name> <container>=<image>  # Update
kubectl rollout undo deployment/<name>  # Rollback
kubectl get all -A                       # Everything
```

---

## 📚 Learning Resources

- Beginner's Guide: [GUIDE.md](GUIDE.md) in this folder
- Kubernetes Official Docs: https://kubernetes.io/docs
- Docker Official Docs: https://docs.docker.com
- Kubernetes in 100 Seconds: https://www.youtube.com/watch?v=cC46cg5FFAM

---

## 💡 Tips for Success

1. **Start Simple**: Deploy one thing, then add complexity
2. **Read Errors**: Kubernetes error messages are usually helpful
3. **Use -A Flag**: `kubectl get pods -A` to see everything
4. **Check Describe**: `kubectl describe pod <name>` for details
5. **Stream Logs**: `kubectl logs -f <pod>` to debug in real-time
6. **Small Namespaces**: Test in small namespace before production
7. **Always Backup**: Export configs: `kubectl get all -o yaml > backup.yaml`

---

## 🏆 Achievements Unlocked

```
Day 1 Milestones:
✅ Docker Expert (Built & ran containers)
✅ Kubernetes Cluster Master (Set up cluster)
✅ Deployment Architect (Multi-namespace setup)
✅ Storage Manager (PV/PVC setup)
✅ Configuration Master (ConfigMap/Secret)
✅ Zero-Downtime Warrior (Rolling updates)
✅ Debugger (Pod execution & logs)
```

---

## 📝 Notes for Future Sessions

- Ingress-nginx requires separate installation
- Docker Desktop has Kubernetes built-in (easier than minikube)
- Namespaces are great for environment separation
- Always test in staging before production
- ConfigMaps for non-sensitive, Secrets for sensitive data

---

## 🎉 Conclusion

**Congratulations!** You've completed a comprehensive Kubernetes learning journey in a single day:

- Built and containerized a real Node.js application
- Deployed to Kubernetes with multiple replicas
- Managed persistent storage
- Implemented zero-downtime deployments
- Set up multiple namespaces for production-like environments
- Learned debugging and troubleshooting
- Applied industry best practices

**You're now at Beginner-to-Intermediate level in Kubernetes!**

---

**Remember**: This is just the beginning. Keep practicing, experiment with new features, and gradually build more complex systems.

**Happy Kubernetes-ing! 🚀**

---

Document Created: March 26, 2026
Status: Complete & Verified
Next Session: Continue with Ingress, StatefulSets, or Helm
Next Session: Continue with Ingress, Statefulness, or Helm