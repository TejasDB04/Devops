# 🔐 INGRESS SETUP GUIDE - COMPLETE TUTORIAL

## What is Ingress?

**Ingress** provides HTTP/HTTPS routing to your Kubernetes services:
- Route traffic by domain name (myapp.local, api.myapp.local)
- TLS/SSL encryption
- Path-based routing (/api, /health)
- Load balancing
- Better than LoadBalancer service (cost-effective)

---

## 📋 SETUP STEPS

### **Step 1: Install Nginx Ingress Controller**

```bash
# Using Helm (EASIEST)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# OR using kubectl (Manual)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/cloud/deploy.yaml
```

**Verify installation:**
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

Expected output:
```
NAME                                       READY   STATUS    RESTARTS
nginx-ingress-ingress-nginx-controller     1/1     Running   0
```

---

### **Step 2: Create Self-Signed TLS Certificate (For Testing)**

```bash
# Generate self-signed certificate (valid for 365 days)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout app.key -out app.crt \
  -subj "/CN=myapp.local" \
  -addext "subjectAltName=DNS:myapp.local,DNS:api.myapp.local"

# Create Kubernetes TLS Secret
kubectl create secret tls app-tls-cert \
  --cert=app.crt \
  --key=app.key \
  -n default

# Verify secret created
kubectl get secret app-tls-cert -n default -o yaml
```

---

### **Step 3: Apply Nginx ConfigMap (Optional)**

```bash
kubectl apply -f nginx-configmap.yaml
```

This adds:
- CORS support
- Security headers
- Rate limiting
- Better proxy settings

---

### **Step 4: Apply Ingress Configuration**

```bash
kubectl apply -f ingress.yaml

# Verify Ingress created
kubectl get ingress -n default
kubectl describe ingress app-ingress -n default
```

Expected output:
```
NAME          CLASS   HOSTS                            ADDRESS         PORTS
app-ingress   nginx   myapp.local,api.myapp.local      10.0.0.1        80, 443
```

---

### **Step 5: Configure /etc/hosts (Local Testing)**

**On Windows (PowerShell as Administrator):**
```powershell
# Edit C:\Windows\System32\drivers\etc\hosts file
# Add these lines:
# 127.0.0.1 myapp.local
# 127.0.0.1 api.myapp.local

# Using command line:
Add-Content -Path C:\Windows\System32\drivers\etc\hosts `
  -Value "`n127.0.0.1 myapp.local`n127.0.0.1 api.myapp.local"
```

**On Mac/Linux:**
```bash
sudo nano /etc/hosts
# Add:
# 127.0.0.1 myapp.local
# 127.0.0.1 api.myapp.local
```

---

### **Step 6: Port Forward for Local Testing**

```bash
# Forward Ingress Controller to localhost
kubectl port-forward -n ingress-nginx svc/nginx-ingress-ingress-nginx-controller 80:80 443:443 &

# Test the endpoints
curl http://localhost/
curl http://localhost/api/health
curl http://localhost/api/info
```

---

## 🧪 TESTING INGRESS

### **Test HTTP Routes**

```bash
# Test main domain
curl -H "Host: myapp.local" http://localhost/

# Test API subdomain
curl -H "Host: api.myapp.local" http://localhost/api

# Test specific paths
curl -H "Host: myapp.local" http://localhost/api/health
curl -H "Host: api.myapp.local" http://localhost/health
```

### **Test HTTPS (TLS)**

```bash
# Ignore self-signed cert warning for testing
curl -k --cacert app.crt https://myapp.local/
curl -k --cacert app.crt https://api.myapp.local/
```

### **Using Browser**

```
http://localhost/ (might fail - need proper hostname)
https://localhost/ (allows self-signed cert)
```

---

## 📊 INGRESS FIELDS EXPLAINED

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress              # Ingress resource name
  namespace: default             # Kubernetes namespace
  annotations:                   # Controller-specific settings
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/enable-cors: "true"

spec:
  ingressClassName: nginx        # Use nginx-ingress controller
  
  tls:                          # TLS/SSL configuration
  - hosts:
    - myapp.local               # Domain names
    - api.myapp.local
    secretName: app-tls-cert    # Kubernetes secret with cert & key
  
  rules:                        # HTTP routing rules
  - host: myapp.local           # Primary domain
    http:
      paths:
      - path: /                 # Path prefix
        pathType: Prefix        # Match /path, /path/*, etc
        backend:
          service:
            name: k8s-app-service  # Target service
            port:
              number: 80        # Target port
```

---

## 🔑 PATHTYPE OPTIONS

| PathType | Behavior | Example |
|----------|----------|---------|
| Prefix | Match prefix | `/api` matches `/api`, `/api/v1`, `/api/users` |
| Exact | Exact match only | `/api` matches only `/api`, not `/api/v1` |
| ImplementationSpecific | Controller-dependent | Nginx uses Prefix behavior |

---

## 🛡️ SECURITY BEST PRACTICES

1. **Always use TLS/HTTPS in production**
   ```yaml
   tls:
   - hosts:
     - myapp.local
     secretName: app-tls-cert
   ```

2. **Use Let's Encrypt for free certificates**
   ```bash
   # Install cert-manager
   helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace
   ```

3. **Add security headers**
   ```yaml
   nginx.ingress.kubernetes.io/configuration-snippet: |
     more_set_headers "X-Frame-Options: SAMEORIGIN";
     more_set_headers "X-Content-Type-Options: nosniff";
   ```

4. **Enable rate limiting**
   ```yaml
   nginx.ingress.kubernetes.io/limit-rps: "10"
   nginx.ingress.kubernetes.io/limit-connections: "5"
   ```

---

## 🚀 NEXT STEPS

1. ✅ Install Nginx Ingress Controller
2. ✅ Create TLS certificates
3. ✅ Apply ingress.yaml
4. ✅ Configure /etc/hosts
5. ✅ Test all endpoints
6. 📍 Move to StatefulSets/HELM for production

---

## 🐛 TROUBLESHOOTING

**Ingress not getting IP address:**
```bash
kubectl describe ingress app-ingress -n default
# Check if controller is running
kubectl get pods -n ingress-nginx
```

**Services not reachable:**
```bash
# Check service endpoints
kubectl get endpoints k8s-app-service -n default
# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

**TLS certificate not working:**
```bash
# Verify secret exists
kubectl get secret app-tls-cert -n default
# Check certificate details
openssl x509 -in app.crt -text -noout
```

---

## 📝 NEXT COMMANDS

Run these in order:

```bash
# 1. Install Ingress Controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# 2. Create TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout app.key -out app.crt \
  -subj "/CN=myapp.local" \
  -addext "subjectAltName=DNS:myapp.local,DNS:api.myapp.local"

# 3. Create TLS secret
kubectl create secret tls app-tls-cert --cert=app.crt --key=app.key -n default

# 4. Apply Ingress
kubectl apply -f ingress.yaml

# 5. Verify
kubectl get ingress -n default
kubectl get secret -n default

# 6. Test (port forward in another terminal)
kubectl port-forward -n ingress-nginx svc/nginx-ingress-ingress-nginx-controller 80:80 443:443

# 7. In another terminal, test
curl http://localhost/
curl -k https://localhost/
```

---

## ✅ SUCCESS CHECKLIST

- [ ] Nginx Ingress Controller running
- [ ] TLS certificate created & secret in Kubernetes
- [ ] ingress.yaml applied without errors
- [ ] `kubectl get ingress` shows your ingress resource
- [ ] HTTP requests work
- [ ] HTTPS requests work
- [ ] Multiple domains routing correctly
- [ ] Path-based routing working

**Once all checked ✅ - move to CI/CD or Helm Charts!**
