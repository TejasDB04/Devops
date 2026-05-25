# 🔒 Kubernetes Security - Hands-On Lab

Learn by doing! Set up RBAC and Network Policies.

---

## Part 1: Create Service Account

### Step 1.1: Create developer service account
```powershell
kubectl create serviceaccount developer
```

**Verify:**
```powershell
kubectl get serviceaccounts
```

**Expected output:**
```
NAME         SECRETS   AGE
default      1         5d
developer    1         10s
```

### Step 1.2: Create admin service account
```powershell
kubectl create serviceaccount admin-user
```

---

## Part 2: Create Roles with Permissions

### Step 2.1: Create developer role (limited permissions)
```yaml
# Save as developer-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: default
rules:
# Developers can view pods
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

# Developers can view pod logs
- apiGroups: [""]
  resources: ["pods/logs"]
  verbs: ["get", "list"]

# Developers can view deployments
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]

# Developers can view services
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
```

**Apply:**
```powershell
kubectl apply -f developer-role.yaml
```

**Verify:**
```powershell
kubectl get roles
```

---

### Step 2.2: Create admin role (full permissions)
```yaml
# Save as admin-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: admin-role
rules:
# Admin can do anything
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

**Apply:**
```powershell
kubectl apply -f admin-role.yaml
```

---

### Step 2.3: Create read-only role
```yaml
# Save as readonly-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: readonly-role
  namespace: default
rules:
# Can only read pods, no delete/edit
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

# Can't access secrets
- apiGroups: [""]
  resources: ["secrets"]
  verbs: []  # No permissions!
```

**Apply:**
```powershell
kubectl apply -f readonly-role.yaml
```

---

## Part 3: Bind Roles to Service Accounts

### Step 3.1: Bind developer role to developer service account
```yaml
# Save as developer-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer-role
subjects:
- kind: ServiceAccount
  name: developer
  namespace: default
```

**Apply:**
```powershell
kubectl apply -f developer-rolebinding.yaml
```

**Verify:**
```powershell
kubectl get rolebindings
```

---

### Step 3.2: Bind admin role to admin service account
```yaml
# Save as admin-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin-role
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: default
```

**Apply:**
```powershell
kubectl apply -f admin-rolebinding.yaml
```

---

## Part 4: Create Network Policies

### Step 4.1: Label your pods for network policies
```powershell
# Label your existing web-app pods
kubectl label pods -l app=web-app tier=web --overwrite

# Label database pods
kubectl label pods -l app=database tier=database --overwrite

# Verify:
kubectl get pods --show-labels
```

---

### Step 4.2: Create "deny all" policy (start restrictive)
```yaml
# Save as default-deny-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  podSelector: {}  # Applies to ALL pods
  policyTypes:
  - Ingress
  - Egress
  # No rules = DENY ALL!
```

**Apply:**
```powershell
kubectl apply -f default-deny-policy.yaml
```

**Note:** This will block all traffic! We'll add specific allow rules next.

---

### Step 4.3: Create policy to allow web app to database
```yaml
# Save as allow-web-to-db.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-database
  namespace: default
spec:
  # Target: Database pods
  podSelector:
    matchLabels:
      tier: database
  
  policyTypes:
  - Ingress
  
  # Allow ingress FROM web tier pods
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
```

**Apply:**
```powershell
kubectl apply -f allow-web-to-db.yaml
```

**Result:** Database now accessible ONLY from web tier!

---

### Step 4.4: Create policy to allow external ingress to web app
```yaml
# Save as allow-ingress-to-web.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-web
  namespace: default
spec:
  # Target: Web tier pods
  podSelector:
    matchLabels:
      tier: web
  
  policyTypes:
  - Ingress
  - Egress
  
  # Allow ingress from Ingress controller
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000  # Web app port
  
  # Allow egress (outbound) to database
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
```

**Apply:**
```powershell
kubectl apply -f allow-ingress-to-web.yaml
```

---

## Part 5: Verify Network Policies Work

### Step 5.1: Check network policies
```powershell
kubectl get networkpolicies
```

**Expected:**
```
NAME                    POD-SELECTOR       AGE
default-deny            <none>             2m
allow-web-to-database   tier=database      1m
allow-ingress-to-web    tier=web           30s
```

### Step 5.2: List policy details
```powershell
kubectl describe networkpolicy allow-web-to-database
```

### Step 5.3: Test connectivity (optional - requires test pods)
```powershell
# Run test pod in cluster
kubectl run test-pod --image=busybox --rm -it -- sh

# Inside pod, try to connect:
# wget http://web-pod:3000  # Should work (if web tier allows)
# wget http://db-pod:5432   # Should FAIL (not allowed from test pod)
```

---

## Part 6: Create Secrets (Secure Passwords)

### Step 6.1: Create database password secret
```yaml
# Save as db-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: default
type: Opaque
stringData:
  username: postgres
  password: your-strong-password-here
```

**Apply:**
```powershell
kubectl apply -f db-secret.yaml
```

**Verify:**
```powershell
kubectl get secrets
```

---

### Step 6.2: Create RBAC role to restrict secret access
```yaml
# Save as secret-reader-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: default
rules:
# Can only READ secrets
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  # resourceNames: ["db-credentials"]  # Optionally limit to specific secret
```

**Apply:**
```powershell
kubectl apply -f secret-reader-role.yaml
```

---

### Step 6.3: Bind secret-reader role
```yaml
# Save as secret-reader-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: secret-reader
subjects:
- kind: ServiceAccount
  name: developer
  namespace: default
```

**Apply:**
```powershell
kubectl apply -f secret-reader-binding.yaml
```

**Result:** `developer` service account can READ secrets, but not DELETE or MODIFY!

---

## Part 7: Pod Security Context

### Step 7.1: Create pod with security restrictions
```yaml
# Save as secure-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  serviceAccountName: developer  # Use limited service account!
  
  securityContext:
    runAsNonRoot: true           # ✅ NOT root!
    runAsUser: 1000              # ✅ Regular user
    fsReadOnlyRootFilesystem: true  # ✅ Read-only filesystem
  
  containers:
  - name: app
    image: nginx:latest
    
    securityContext:
      allowPrivilegeEscalation: false  # ✅ Can't become root!
      capabilities:
        drop:
        - ALL  # ✅ Remove all dangerous powers
      readOnlyRootFilesystem: true  # ✅ Read-only
    
    ports:
    - containerPort: 80
    
    # Need writable volume for tmp files
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  
  # Create temporary writable volume
  volumes:
  - name: tmp
    emptyDir: {}
```

**Apply:**
```powershell
kubectl apply -f secure-pod.yaml
```

**Verify:**
```powershell
kubectl get pods
kubectl describe pod secure-app
```

---

## Part 8: Review RBAC Assignments

### Step 8.1: View all roles
```powershell
kubectl get roles
```

### Step 8.2: View all role bindings
```powershell
kubectl get rolebindings
```

### Step 8.3: Check what "developer" can do
```powershell
kubectl auth can-i list pods --as=system:serviceaccount:default:developer
# Expected: yes

kubectl auth can-i delete pods --as=system:serviceaccount:default:developer
# Expected: no

kubectl auth can-i get secrets --as=system:serviceaccount:default:developer
# Expected: yes

kubectl auth can-i delete secrets --as=system:serviceaccount:default:developer
# Expected: no
```

---

## Part 9: Clean Up (Optional)

### Remove RBAC
```powershell
kubectl delete rolebinding developer-binding
kubectl delete role developer-role
kubectl delete serviceaccount developer
```

### Remove Network Policies
```powershell
kubectl delete networkpolicy default-deny
kubectl delete networkpolicy allow-web-to-database
kubectl delete networkpolicy allow-ingress-to-web
```

### Remove Secrets
```powershell
kubectl delete secret db-credentials
```

---

## 🎯 Security Lab Summary

✅ **What you learned:**
- Create ServiceAccounts (Kubernetes "users")
- Create Roles with specific permissions
- Bind Roles to ServiceAccounts
- Create Network Policies to restrict traffic
- Use Security Contexts for pod hardening
- Encrypt secrets

✅ **You can now:**
- Limit developer permissions (can't delete production!)
- Prevent compromised pods from accessing database
- Restrict pod capabilities (can't run as root)
- Enforce least privilege access

✅ **Real-world benefit:**
- If developer makes mistake → Can't delete production pods
- If web app is compromised → Can't access database directly
- If pod is hacked → Can't execute code as root

---

## 🎓 Key Security Principles

| Principle | How we did it |
|-----------|--------------|
| **Least Privilege** | Gave developer only view permissions, not delete |
| **Defense in Depth** | RBAC (permissions) + Network Policy (network) + SecurityContext (container) |
| **Encryption** | Used Secrets for passwords (encrypted at rest) |
| **Isolation** | Network Policy prevents pod-to-pod communication |
| **Hardening** | SecurityContext disables root, read-only filesystem |

---

## 🚀 What's Next?

You've now completed:
✅ StatefulSets
✅ HPA
✅ Monitoring
✅ Logging
✅ Helm
✅ Security

**Remaining 3 topics:**
1. Advanced Deployment (Blue-Green, Canary)
2. GitOps (ArgoCD automation)
3. Backup & Disaster Recovery (Velero)

Ready for more? Let me know! 🎯
