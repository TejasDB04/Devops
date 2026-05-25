# 🚀 Kubernetes & Docker Complete Beginner Guide

## 📚 Table of Contents
1. [Concepts](#concepts)
2. [Project Structure](#project-structure)
3. [Step-by-Step Setup](#step-by-step-setup)
4. [Commands Explained](#commands-explained)
5. [Troubleshooting](#troubleshooting)

---

## Concepts

### What is Docker?
Docker is a **containerization platform** that packages your application with all dependencies into a container.

**Simple analogy**: 
- Without Docker: "It works on my machine!" 😅
- With Docker: "It works on any machine!" ✅

### What is Kubernetes (K8s)?
Kubernetes is an **orchestration platform** that manages Docker containers at scale.

**What it does**:
- Runs multiple containers across multiple machines
- Auto-restarts failed containers
- Scales apps up/down based on demand
- Updates apps without downtime
- Manages networking, storage, etc.

### Docker vs Kubernetes
| Docker | Kubernetes |
|--------|-----------|
| Package app into container | Run & manage containers |
| Single machine focus | Multi-machine focus |
| Container runtime | Container orchestration |

---

## Project Structure

```
kubernates/
├── app.js              # Node.js application code
├── package.json        # Node.js dependencies
├── Dockerfile          # Instructions to build Docker image
├── .dockerignore       # Files to ignore in Docker build
├── deployment.yaml     # Kubernetes deployment manifest
├── service.yaml        # Kubernetes service manifest
└── GUIDE.md           # This file
```

### File Explanations

**app.js**: Your Node.js web server
- Listens on port 3000
- Provides API endpoints (/api/health, /api/info, etc.)

**package.json**: Lists dependencies for Node.js
- Tells `npm install` what packages to download

**Dockerfile**: Recipe to build a Docker image
- Starts with Node.js base image
- Copies files
- Installs dependencies
- Exposes port
- Runs the app

**deployment.yaml**: Kubernetes configuration
- Says "Run 2 copies of my app"
- Defines health checks
- Sets resource limits
- Configures auto-restart

**service.yaml**: Kubernetes networking
- Exposes app to outside world
- Load balances traffic to pods
- Maps external port 80 → internal port 3000

---

## Step-by-Step Setup

### Step 1: Verify Docker & Kubernetes are Running

```powershell
# Check Docker
docker version

# Check Kubernetes
kubectl version --client
kubectl cluster-info

# Check current context
kubectl config current-context
# Should show: docker-desktop
```

### Step 2: Navigate to Project Directory

```powershell
cd "C:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"

# Verify files exist
dir

# Expected output:
# app.js, package.json, Dockerfile, deployment.yaml, service.yaml
```

### Step 3: Build Docker Image

```powershell
# Build the image
docker build -t k8s-app:latest .

# Explanation:
# docker build       = Build image from Dockerfile
# -t k8s-app:latest = Tag it as "k8s-app" version "latest"
# .                 = Use Dockerfile in current directory

# Verify image was created
docker images
# You should see k8s-app in the list
```

### Step 4: Test Docker Image Locally (Optional)

```powershell
# Run container from image
docker run -d -p 3000:3000 --name test-app k8s-app:latest

# Explanation:
# -d              = Run in background
# -p 3000:3000    = Map port 3000 (host) to 3000 (container)
# --name          = Give container a name
# k8s-app:latest  = Use this image

# Test it
curl http://localhost:3000
# Or open browser: http://localhost:3000

# View logs
docker logs test-app

# Stop container
docker stop test-app

# Remove container
docker rm test-app
```

### Step 5: Deploy to Kubernetes

```powershell
# Switch to docker-desktop context
kubectl config use-context docker-desktop

# Create deployment (runs your app)
kubectl apply -f deployment.yaml

# Create service (exposes your app)
kubectl apply -f service.yaml

# Explanation:
# kubectl apply -f = Apply configuration from YAML file
# deployment.yaml  = Deploy the app with 2 replicas
# service.yaml     = Expose it to the network
```

### Step 6: Verify Deployment

```powershell
# Check deployments
kubectl get deployments

# Expected output:
# NAME      READY   UP-TO-DATE   AVAILABLE   AGE
# k8s-app   2/2     2            2           10s

# Check pods (instances of your app)
kubectl get pods

# Expected output:
# NAME                      READY   STATUS    RESTARTS   AGE
# k8s-app-xxxxx-xxxxx       1/1     Running   0          15s
# k8s-app-yyyyy-yyyyy       1/1     Running   0          12s

# Check service (how to access your app)
kubectl get svc

# Expected output:
# NAME              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
# k8s-app-service   LoadBalancer   10.96.x.x       localhost     80:xxxxx/TCP
```

### Step 7: Access Your Application

```powershell
# Get service details
kubectl get svc k8s-app-service

# For Docker Desktop, access at:
# http://localhost

# From PowerShell:
curl http://localhost

# Should return JSON:
# {
#   "message": "Welcome to Kubernetes & Docker Demo!",
#   "timestamp": "2024-03-26T...",
#   "hostname": "k8s-app-xxxxx"
# }

# Test other endpoints:
curl http://localhost/api/health
curl http://localhost/api/info
```

### Step 8: View Logs

```powershell
# View logs from a specific pod
kubectl get pods
# Copy pod name from output

kubectl logs <pod-name>

# Example:
# kubectl logs k8s-app-7d8f5c4f6b-xxxxx

# Follow logs live (like tail -f)
kubectl logs -f k8s-app-7d8f5c4f6b-xxxxx

# View logs from all pods
kubectl logs -l app=k8s-app
```

### Step 9: Scale Your Application

```powershell
# Increase replicas to 3
kubectl scale deployment k8s-app --replicas=3

# Verify
kubectl get pods
# Should show 3 pods now

# Decrease to 1
kubectl scale deployment k8s-app --replicas=1

# Verify
kubectl get pods
```

### Step 10: Update Your Application

```powershell
# Edit app.js (change something)
# Save the file

# Rebuild Docker image
docker build -t k8s-app:v2 .

# Update deployment to use new image
kubectl set image deployment/k8s-app app=k8s-app:v2

# Explanation:
# kubectl set image = Change the image in deployment
# deployment/k8s-app = For this deployment
# app=k8s-app:v2 = Update container "app" to use new image

# Watch rollout progress
kubectl rollout status deployment/k8s-app

# If something goes wrong, rollback
kubectl rollout undo deployment/k8s-app

# Verify
kubectl get pods
```

---

## Commands Explained

### Docker Commands

```powershell
# Build
docker build -t image-name:tag .
# Creates Docker image from Dockerfile

# Run
docker run -d -p 8080:3000 image-name:tag
# Starts a container from image

# List images
docker images
# Shows all built images

# List running containers
docker ps
# Shows running containers only

# List all containers
docker ps -a
# Shows all containers (running + stopped)

# View logs
docker logs container-id
# Shows output from container

# Stop container
docker stop container-id
# Gracefully stops container

# Remove container
docker rm container-id
# Deletes stopped container

# Remove image
docker rmi image-name:tag
# Deletes image
```

### Kubernetes Commands

```powershell
# Context management
kubectl config current-context              # Show active context
kubectl config use-context docker-desktop   # Switch context
kubectl config get-contexts                 # List all contexts

# Cluster info
kubectl cluster-info                        # Show cluster info
kubectl get nodes                           # List nodes (machines)

# Deployments
kubectl get deployments                     # List deployments
kubectl create deployment name --image=img  # Create deployment
kubectl apply -f file.yaml                  # Apply YAML config
kubectl delete deployment name              # Delete deployment
kubectl scale deployment name --replicas=3  # Change number of pods
kubectl set image deployment/name app=img   # Update image
kubectl rollout status deployment/name      # Check update progress
kubectl rollout undo deployment/name        # Revert to previous version

# Pods (instances of your app)
kubectl get pods                            # List pods
kubectl get pods -n namespace               # List pods in namespace
kubectl describe pod pod-name               # Detailed pod info
kubectl logs pod-name                       # View pod logs
kubectl logs -f pod-name                    # Stream logs (live)
kubectl logs -l app=k8s-app                 # Logs by label
kubectl exec -it pod-name -- /bin/bash      # SSH into pod
kubectl port-forward pod-name 8080:3000     # Forward local port to pod

# Services (networking)
kubectl get svc                             # List services
kubectl get svc -o wide                     # Detailed service info
kubectl describe svc service-name           # Service details
kubectl expose deployment name --type=LoadBalancer --port=80  # Create service

# Namespaces (logical grouping)
kubectl get namespaces                      # List namespaces
kubectl create namespace myns               # Create namespace
kubectl delete namespace myns               # Delete namespace
kubectl config set-context --current --namespace=myns  # Switch namespace

# Debugging
kubectl describe pod pod-name               # Why is pod failing?
kubectl get events                          # What happened recently?
kubectl get all                             # Everything in cluster
kubectl get all -o yaml                     # Everything in YAML format
```

### Common Workflows

```powershell
# Deploy from scratch
docker build -t myapp:latest .
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Scale up
kubectl scale deployment myapp --replicas=5

# Update app
docker build -t myapp:v2 .
kubectl set image deployment/myapp app=myapp:v2

# Delete everything
kubectl delete deployment myapp
kubectl delete svc myapp-service

# View everything in JSON
kubectl get all -o json

# Export current state
kubectl get all -o yaml > backup.yaml

# Apply from exported state
kubectl apply -f backup.yaml
```

---

## File Reference

### Dockerfile Explained

```dockerfile
FROM node:18-alpine
# Use Node.js 18 on Alpine Linux (lightweight)

WORKDIR /app
# Set working directory inside container to /app

COPY package*.json ./
# Copy package.json and package-lock.json (if exists) to /app

RUN npm install --only=production
# Install only production dependencies (no dev deps)

COPY app.js .
# Copy application code

EXPOSE 3000
# Document that app listens on port 3000
# (Doesn't actually publish the port)

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', ...)"
# Kubernetes will check /api/health every 30 seconds

CMD ["node", "app.js"]
# When container starts, run this command
```

### deployment.yaml Explained

```yaml
apiVersion: apps/v1              # Kubernetes API version
kind: Deployment                 # Type of resource
metadata:
  name: k8s-app                  # Deployment name
spec:
  replicas: 2                    # Run 2 copies
  selector:
    matchLabels:
      app: k8s-app               # Target pods with this label
  template:
    metadata:
      labels:
        app: k8s-app             # Label for pods
    spec:
      containers:
      - name: app                # Container name
        image: k8s-app:latest    # Docker image to use
        ports:
        - containerPort: 3000    # Port container listens on
        
        resources:
          requests:              # Minimum resources to schedule pod
            memory: "64Mi"
            cpu: "100m"
          limits:                # Maximum resources allowed
            memory: "128Mi"
            cpu: "500m"
        
        livenessProbe:           # Restart pod if checks fail
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        
        readinessProbe:          # Mark pod ready/not ready
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### service.yaml Explained

```yaml
apiVersion: v1
kind: Service
metadata:
  name: k8s-app-service
spec:
  type: LoadBalancer             # Expose externally
  selector:
    app: k8s-app                 # Route to pods with this label
  ports:
  - port: 80                     # External port (what clients use)
    targetPort: 3000             # Pod port (internal)
```

---

## Troubleshooting

### "Pods not starting"

```powershell
# Check pod status
kubectl get pods

# Get detailed error info
kubectl describe pod pod-name

# View logs
kubectl logs pod-name

# Check if image exists locally
docker images

# Rebuild image
docker build -t k8s-app:latest .
```

### "Service not accessible"

```powershell
# Check service exists
kubectl get svc

# Get service details
kubectl describe svc k8s-app-service

# Check pods are running
kubectl get pods

# Test from pod directly
kubectl exec -it pod-name -- curl http://localhost:3000
```

### "Port conflict"

```powershell
# Find what's using port 80
netstat -ano | findstr :80

# Use port-forward instead
kubectl port-forward svc/k8s-app-service 8080:80
# Then access http://localhost:8080
```

### "Image pull errors"

```powershell
# Check image exists
docker images

# Rebuild if missing
docker build -t k8s-app:latest .

# Update deployment to use local image
# Change imagePullPolicy in deployment.yaml:
# imagePullPolicy: IfNotPresent   # Use local image
```

### "Deployment won't update"

```powershell
# Check rollout status
kubectl rollout status deployment/k8s-app

# View rollout history
kubectl rollout history deployment/k8s-app

# Rollback if needed
kubectl rollout undo deployment/k8s-app
```

---

## Summary

### First Time Setup (in order):
1. ✅ Navigate to project directory
2. ✅ `docker build -t k8s-app:latest .` (build image)
3. ✅ `kubectl apply -f deployment.yaml` (deploy app)
4. ✅ `kubectl apply -f service.yaml` (expose app)
5. ✅ `curl http://localhost` (test it)

### Daily Workflow:
- Edit app.js
- Rebuild: `docker build -t k8s-app:latest .`
- Update: `kubectl set image deployment/k8s-app app=k8s-app:latest`
- Monitor: `kubectl get pods`

### Cleanup:
```powershell
kubectl delete deployment k8s-app
kubectl delete svc k8s-app-service
```

---

## Resources

- Docker Docs: https://docs.docker.com
- Kubernetes Docs: https://kubernetes.io/docs
- Docker Desktop: https://www.docker.com/products/docker-desktop
- Node.js Docker: https://hub.docker.com/_/node

**Happy learning!** 🚀
