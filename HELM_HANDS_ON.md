# 📦 Helm Hands-On Lab - Complete Practice

Learn by doing! Let's package your k8s-app with Helm.

---

## Part 1: Install Helm

### Step 1.1: Check if Helm is installed
```powershell
helm version
```

**Expected output:**
```
version.BuildInfo{Version:"v3.12.0", ...}
```

**If not found:** Download from https://github.com/helm/helm/releases

### Step 1.2: Add Bitnami Helm repository (for PostgreSQL chart)
```powershell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

**Verify:**
```powershell
helm repo list
```

**Expected output:**
```
NAME    URL
bitnami https://charts.bitnami.com/bitnami
```

---

## Part 2: Create Your First Helm Chart

### Step 2.1: Generate chart scaffold
```powershell
helm create k8s-app-chart
```

**This creates:**
```
k8s-app-chart/
├─ Chart.yaml          (metadata)
├─ values.yaml         (default config)
├─ templates/          (YAML templates)
│  ├─ deployment.yaml
│  ├─ service.yaml
│  ├─ _helpers.tpl
│  └─ NOTES.txt
└─ README.md
```

### Step 2.2: Verify file structure
```powershell
Get-ChildItem -Recurse k8s-app-chart
```

---

## Part 3: Customize Chart Metadata

### Step 3.1: Edit Chart.yaml
```bash
# Look at current:
cat k8s-app-chart/Chart.yaml
```

**Add these details:**
```yaml
apiVersion: v2
name: k8s-app
description: A Helm chart for k8s-app (Node.js app)
type: application
version: 1.0.0           # Chart version
appVersion: "1.0.0"      # App version
maintainers:
  - name: You
    email: you@example.com
```

---

## Part 4: Configure Values

### Step 4.1: Edit values.yaml
Replace default content with:

```yaml
# Default values for k8s-app
replicaCount: 2

image:
  repository: your-registry/k8s-app
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: "app.local"
      paths:
        - path: /
          pathType: Prefix
  tls: []

nodeSelector: {}
tolerations: []
affinity: {}
```

### Step 4.2: Create environment-specific values

**values-development.yaml:**
```yaml
replicaCount: 1
image:
  tag: "latest"
resources:
  requests:
    cpu: 50m
    memory: 64Mi
autoscaling:
  minReplicas: 1
  maxReplicas: 2
```

**values-production.yaml:**
```yaml
replicaCount: 3
image:
  tag: "v1.0.0"
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi
autoscaling:
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
```

---

## Part 5: Create Templates

### Step 5.1: Edit templates/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "k8s-app.fullname" . }}
  labels:
    {{- include "k8s-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "k8s-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "k8s-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Step 5.2: Edit templates/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "k8s-app.fullname" . }}
  labels:
    {{- include "k8s-app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "k8s-app.selectorLabels" . | nindent 4 }}
```

### Step 5.3: Edit templates/hpa.yaml

```yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "k8s-app.fullname" . }}
  labels:
    {{- include "k8s-app.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "k8s-app.fullname" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
{{- end }}
```

### Step 5.4: Edit templates/ingress.yaml

```yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "k8s-app.fullname" . }}
  labels:
    {{- include "k8s-app.labels" . | nindent 4 }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "k8s-app.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

---

## Part 6: Test Chart Rendering

### Step 6.1: Dry-run to see what will be deployed
```powershell
helm install my-app k8s-app-chart --dry-run --debug
```

**You'll see:**
- Deployment YAML (with all values substituted)
- Service YAML
- HPA YAML
- Ingress YAML

### Step 6.2: Verify no errors
```powershell
# Lint chart for errors
helm lint k8s-app-chart
```

**Expected:**
```
1 chart(s) linted, 0 chart(s) failed
```

---

## Part 7: Deploy with Helm

### Step 7.1: Install release (development)
```powershell
helm install dev-app k8s-app-chart -f k8s-app-chart/values-development.yaml
```

**Verify:**
```powershell
helm list
```

**You should see:**
```
NAME     NAMESPACE STATUS   CHART            VERSION
dev-app  default   deployed k8s-app-1.0.0    1
```

### Step 7.2: Check deployed resources
```powershell
kubectl get deployments
kubectl get services
kubectl get hpa
```

### Step 7.3: Get deployment info
```powershell
helm status dev-app
```

---

## Part 8: Update and Upgrade

### Step 8.1: Change chart values
```powershell
# Upgrade with different values
helm upgrade dev-app k8s-app-chart --set replicaCount=3
```

### Step 8.2: Verify upgrade
```powershell
kubectl get pods
# Should show 3 pods now!
```

### Step 8.3: Check deployment values
```powershell
helm get values dev-app
```

---

## Part 9: Production Deployment

### Step 9.1: Deploy production version
```powershell
helm install prod-app k8s-app-chart -f k8s-app-chart/values-production.yaml
```

### Step 9.2: Verify both environments running
```powershell
helm list
```

**You should see:**
```
NAME     NAMESPACE STATUS   CHART            VERSION
dev-app  default   deployed k8s-app-1.0.0    1
prod-app default   deployed k8s-app-1.0.0    1
```

### Step 9.3: Compare resources
```powershell
kubectl get deployments -o wide
# dev-app: 1 replica
# prod-app: 3 replicas
```

---

## Part 10: Rollback & History

### Step 10.1: View release history
```powershell
helm history dev-app
```

**Shows all upgrades:**
```
REVISION STATUS    APP VERSION DESCRIPTION
1        deployed  1.0.0       Install complete
2        deployed  1.0.0       Upgrade complete
```

### Step 10.2: Rollback to previous version
```powershell
helm rollback dev-app 1
```

**Verify:**
```powershell
kubectl get pods
# Back to original state!
```

---

## Part 11: Clean Up

### Step 11.1: Delete releases
```powershell
helm uninstall dev-app
helm uninstall prod-app
```

### Step 11.2: Verify deletion
```powershell
helm list
# Should be empty
```

---

## 🎯 Hands-On Summary

✅ **What you learned:**
- Create a Helm chart from scratch
- Configure values for different environments
- Use templates with variables
- Deploy with `helm install`
- Upgrade with `helm upgrade`
- Rollback with `helm rollback`
- Manage multiple environments with one chart

✅ **You can now:**
- Package any Kubernetes app with Helm
- Manage development, staging, production separately
- Share charts with your team
- Version and upgrade deployments easily

---

## 💡 Advanced Topics (Optional)

### Use PostgreSQL Helm Chart (Don't create from scratch!)
```powershell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-postgresql bitnami/postgresql --set auth.password=mypassword
```

### Create Subchart (Deploy app + database together)
```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.1.0"
    repository: "https://charts.bitnami.com/bitnami"
```

### Push Chart to Registry
```powershell
# Share your chart with team
helm package k8s-app-chart
# Creates: k8s-app-1.0.0.tgz
```

---

## 🎓 Key Takeaways

| Concept | What it does | Time |
|---------|-------------|------|
| **Chart** | Package/template for your app | Created ✅ |
| **Values** | Configuration variables | Configured ✅ |
| **Release** | Running instance of chart | Deployed ✅ |
| **Templates** | YAML with {{ .Values }} placeholders | Created ✅ |
| **Environments** | Different values per environment | Set up ✅ |
| **Upgrade** | Change version/config | Tested ✅ |
| **Rollback** | Go back to previous version | Tested ✅ |

---

## 📊 Next Steps

**You've now completed:**
✅ StatefulSets (databases)
✅ HPA (auto-scaling)
✅ Monitoring (Prometheus + Grafana)
✅ Logging (centralized logs)
✅ Helm (package management)

**Remaining 4 topics:**
1. Security (RBAC, Network Policies)
2. Advanced Deployment (Blue-Green, Canary)
3. GitOps (ArgoCD automation)
4. Backup & Disaster Recovery (Velero)

Ready to choose next? Let me know! 🚀
