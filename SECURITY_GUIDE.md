# 🔒 Kubernetes Security - RBAC & Network Policies Guide

--- 

## The Security Pyramid

```
            🔐 Production Security
        ╱────────────────────────╲
       ╱      Network Policies    ╲     (Control traffic between pods)
      ╱  Pod Security Policies     ╲    (Restrict container capabilities)
     ╱   Secrets Management        ╲   (Encrypt sensitive data)
    ╱     RBAC (Who can do what)    ╲  (Control user permissions)
   ╱_________________________________╲
  Real-World Kubernetes             
```

---

## Problem: Kubernetes Without Security

```yaml
# ❌ DANGEROUS - Anyone can do anything!

# Problem 1: Secret Exposure
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DB_PASSWORD: "admin123"  # ❌ Password in plain text!

---
# Problem 2: Pod Escape
# App running as root → Can access all files!
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp
    securityContext:
      runAsUser: 0  # ❌ Running as root!

---
# Problem 3: Pod Network Access
# Pod A can talk to Pod B (even if shouldn't!)
# → Compromised pod can access database directly

---
# Problem 4: User Permissions
# All developers can:
# - Delete production pods
# - Access secrets
# - Modify deployments
# ❌ No access control!
```

---

## 🎯 Solution 1: RBAC (Role-Based Access Control)

**RBAC** = "Who can do what on which resources"

### How RBAC Works

```
User Alice wants to "list pods"
         ↓
Check: What Role does Alice have?
         ↓
Check: What permissions does that Role have?
         ↓
Permission "list pods" found?
    YES → ✅ Allowed
    NO  → ❌ Denied
```

### RBAC Components

```
┌──────────────────┐
│   (User/Group)   │  Alice (developer)
└────────┬─────────┘
         │ (RoleBinding)
         ↓
┌──────────────────┐
│      Role        │  Can: get, list, watch pods
│   (Permissions)  │      Can NOT: delete, create
└────────┬─────────┘
         │
         (references)
         ↓
┌──────────────────┐
│    Resources     │  Pod, Service, Deployment
└──────────────────┘
```

### Step-by-Step: Create Developer User

**Step 1: Create Service Account (Kubernetes "user")**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer
  namespace: default
```

**Step 2: Create Role with permissions**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader  # Can only READ pods
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]  # Can list, but NOT delete/create
```

**Step 3: Bind Role to ServiceAccount**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: developer
  namespace: default
```

**Result:**
- ✅ `developer` can: list, get, watch pods
- ❌ `developer` cannot: delete, edit, create pods

---

### Real World: Different Roles

```yaml
# Role 1: Developers (limited access)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods", "pods/logs"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
  # ❌ Cannot delete, edit, or create!

---
# Role 2: DevOps (full access)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole  # ClusterRole = all namespaces
metadata:
  name: devops-role
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]  # All permissions!

---
# Role 3: Database Admin (only look at secrets)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  # Can READ secrets, but not create/delete!
```

---

## 🎯 Solution 2: Network Policies

**Network Policy** = Firewall for Kubernetes pods

### Problem Without Network Policies

```
┌─────────────┐
│   Web App   │---┐
└─────────────┘   │
                  │  Can reach ANY pod (no firewall!)
┌─────────────┐   │
│  Database   │←──┘  ❌ Compromised web app can delete DB
└─────────────┘
```

### Solution WITH Network Policies

```
┌─────────────┐
│   Web App   │---┐
└─────────────┘   │
                  │  Network Policy: Only allow Database
┌─────────────┐   │
│  Database   │←──┘  ✅ Even if web app compromised, can't access other pods
└─────────────┘
  ↓
┌─────────────┐
│  Cache Pod  │  ❌ Web app can't reach this
└─────────────┘
```

### How Network Policies Work

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-database
spec:
  # Apply to pods with label: app=database
  podSelector:
    matchLabels:
      app: database
  
  # Allow ingress (incoming traffic)
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web-app  # Only from web-app pods!
    ports:
    - protocol: TCP
      port: 5432       # Only on port 5432!
```

**Translation:**
- 🎯 Targets: Pods with label `app: database`
- ✅ Allow incoming traffic FROM: Pods with label `app: web-app`
- ✅ Allow on port: 5432 (PostgreSQL)
- ❌ Deny: Everything else!

---

### Real World Network Policies

**Policy 1: Web Tier to Database Tier**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 5432
```

**Policy 2: Deny All (then explicitly allow)**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}  # Applies to ALL pods
  policyTypes:
  - Ingress
  - Egress
  # No ingress/egress rules = DENY ALL!
```

**Policy 3: Allow Web Tier to External APIs**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-external
spec:
  podSelector:
    matchLabels:
      tier: web
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: external
    ports:
    - protocol: TCP
      port: 443
```

---

## 🏗️ Enterprise Security Architecture

```
                    ┌─────────────┐
                    │   Internet  │
                    └──────┬──────┘
                           ↓
                    ┌─────────────────┐
                    │  Ingress        │
                    │ (TLS/SSL)       │
                    └────────┬────────┘
                            ↓
    ┌───────────────────────────────────────────────┐
    │        Kubernetes Cluster (Private)            │
    │                                               │
    │  ┌──────────────────────────────────────────┐ │
    │  │  Web App Namespace                        │ │
    │  │  ┌─────────────┐                          │ │
    │  │  │ Web Pod     │  ← RBAC: Can view pods  │ │
    │  │  │ (User role) │  ← Network Policy:      │ │
    │  │  └─────┬───────┘     Only to Database    │ │
    │  │        ↓                                  │ │
    │  │  ┌──────────────┐                        │ │
    │  │  │ Secrets      │  ← RBAC: Can read     │ │
    │  │  │ (encrypted)  │     but NOT delete     │ │
    │  │  └──────────────┘                        │ │
    │  └──────────────────────────────────────────┘ │
    │                                               │
    │  ┌──────────────────────────────────────────┐ │
    │  │  Database Namespace                       │ │
    │  │  ┌──────────────────┐                     │ │
    │  │  │ PostgreSQL Pod   │  ← Network Policy: │ │
    │  │  │                  │    Only access     │ │
    │  │  │                  │    from Web tier   │ │
    │  │  └──────────────────┘                     │ │
    │  │  ┌──────────────────┐                     │ │
    │  │  │ Secret: DB Pass  │  ← Encrypted!     │ │
    │  │  └──────────────────┘                     │ │
    │  └──────────────────────────────────────────┘ │
    │                                               │
    └───────────────────────────────────────────────┘
```

---

## 🔐 Security Best Practices

```yaml
✅ RBAC Best Practices:

# 1. Principle of Least Privilege
# Give minimum permissions needed
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-viewer  # Can ONLY view pods (least privilege)
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

# 2. Use Namespaces + Role (not ClusterRole)
kind: Role  # ← Limited to namespace
# NOT: kind: ClusterRole  # This is too powerful!

# 3. Separate roles by function
# developer-role (limited permissions)
# devops-role (more permissions)
# admin-role (full permissions)

---
✅ Network Policy Best Practices:

# 1. Default deny everything
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  # No rules = Deny All!

# 2. Explicitly allow what you need
# Then add specific policies for each service

# 3. Use labels for clarity
labels:
  tier: web          # Easy to reference in policies
  security: public   # Indicates access level

---
✅ Secret Best Practices:

# 1. Use Secrets, NOT ConfigMaps, for passwords!
apiVersion: v1
kind: Secret
metadata:
  name: db-password
type: Opaque
stringData:
  password: "secretpassword"

# 2. Encrypt secrets at rest (not default!)
# 3. Use external secret management (Vault, Sealed Secrets)
# 4. Rotate passwords regularly
```

---

## Real Example: Secure App Stack

```yaml
---
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production

---
# ServiceAccount for the app
apiVersion: v1
kind: ServiceAccount
metadata:
  name: web-app
  namespace: production

---
# Role: Limited permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: web-app-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["db-credentials"]  # Only this secret!

---
# RoleBinding: Attach role to service account
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: web-app-binding
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: web-app-role
subjects:
- kind: ServiceAccount
  name: web-app
  namespace: production

---
# Secret: Database credentials (encrypted)
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: production
type: Opaque
stringData:
  password: "strongpassword123"
  username: "dbuser"

---
# Pod with security context
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  namespace: production
spec:
  serviceAccountName: web-app
  securityContext:
    runAsNonRoot: true    # ✅ NOT root!
    runAsUser: 1000       # ✅ Regular user
    fsReadOnlyRootFilesystem: true  # ✅ Read-only filesystem
  containers:
  - name: app
    image: myapp:latest
    securityContext:
      allowPrivilegeEscalation: false  # ✅ Can't become root!
      capabilities:
        drop:
        - ALL              # ✅ Remove dangerous capabilities
      readOnlyRootFilesystem: true  # ✅ Read-only
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}

---
# Network Policy: Deny all by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Network Policy: Allow web app from ingress only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-app
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web-app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000

---
# Network Policy: Allow database access only from web app
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-database
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web-app
    ports:
    - protocol: TCP
      port: 5432
```

---

## 🎓 When to Use What

| Scenario | Use This |
|----------|----------|
| "Developer shouldn't delete pods" | RBAC Role (limited verbs) |
| "App shouldn't access database outside pod" | Network Policy |
| "App shouldn't run as root" | SecurityContext |
| "Database password shouldn't be readable" | Secret + RBAC |
| "Only admins can modify production" | ClusterRoleBinding (admin) |
| "Pod shouldn't access filesystem" | readOnlyRootFilesystem |

---

## 💡 Why Security Matters

**Without security:**
- 😱 Dev can delete production database
- 😱 Compromised pod can access all secrets
- 😱 Hacker can run code as root
- 😱 Public exposure of passwords

**With security:**
- ✅ Dev can only view (not delete)
- ✅ Pod can only access its own database
- ✅ Pod runs as unprivileged user
- ✅ Secrets encrypted and access-controlled

---

## 📊 Next Steps

**Time to learn:** 1 hour  
**Difficulty:** ⭐⭐⭐ Medium  
**Impact:** CRITICAL for production!

Move to: **SECURITY_HANDS_ON.md** (coming next!)

You'll:
1. Create ServiceAccounts
2. Create Roles with specific permissions
3. Bind Roles to ServiceAccounts
4. Create Network Policies
5. Test access controls
6. Verify pods can't access unauthorized resources

Ready? Let's secure your cluster! 🔒
