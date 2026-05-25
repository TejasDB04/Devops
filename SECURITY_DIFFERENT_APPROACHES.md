# 🔒 Different Security Approaches - Same Goal

Learn multiple ways to achieve the same security outcomes!

---

## 🎯 APPROACH COMPARISON TABLE

| Goal | Approach 1 | Approach 2 | Approach 3 | Best For |
|------|-----------|-----------|-----------|----------|
| **Restrict User Access** | Role + RoleBinding | ClusterRole + ClusterRoleBinding | ServiceAccount only | Small team |
| **Firewall Pods** | Network Policy (default deny) | Network Policy (explicit allow) | Calico NetworkPolicy | Different use cases |
| **Store Secrets** | Secret resource | ConfigMap (no encryption) | External vault | Security level |
| **Run Safely** | Pod SecurityContext | Pod Security Policy | Pod Security Standards | Kubernetes version |

---

# 📋 APPROACH 1: RBAC - Three Different Ways

## Approach 1A: Namespace-Scoped (What We Did ✓)

```yaml
# Step 1: Create ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer
  namespace: default        # ← Limited to ONE namespace
---
# Step 2: Create Role (namespace-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role                 # ← NOT ClusterRole
metadata:
  name: developer-role
  namespace: default       # ← Limited to ONE namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
# Step 3: Bind Role to ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding          # ← NOT ClusterRoleBinding
metadata:
  name: developer-binding
  namespace: default       # ← Limited to ONE namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role               # ← References Role (not ClusterRole)
  name: developer-role
subjects:
- kind: ServiceAccount
  name: developer
  namespace: default
```

**✅ Use When:**
- Limiting developers to specific namespace
- Small teams with one environment
- Namespace isolation needed

**Permissions Scope:** `default` namespace ONLY

---

## Approach 1B: Cluster-Scoped (More Power)

```yaml
# Step 1: Same ServiceAccount (can be namespace or cluster)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: default
---
# Step 2: Create ClusterRole (all namespaces!)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole              # ← Works across ALL namespaces
metadata:
  name: admin-cluster-role     # ← No namespace field
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]                 # ← All actions everywhere!
---
# Step 3: Bind ClusterRole to ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding       # ← Works cluster-wide
metadata:
  name: admin-cluster-binding  # ← No namespace field
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole            # ← References ClusterRole
  name: admin-cluster-role
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: default           # ← Still must specify namespace here
```

**✅ Use When:**
- DevOps/SRE team needs cluster-wide access
- Platform team managing infrastructure
- Cluster administration

**Permissions Scope:** ALL namespaces

---

## Approach 1C: Resource-Specific (Surgical Precision)

```yaml
# Only allow access to SPECIFIC resources in SPECIFIC namespace

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: db-admin-role
  namespace: production
rules:
# Can ONLY work with one specific resource
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "create", "update"]
  resourceNames: ["db-password"]  # ← Only THIS secret!

# Can view postgres StatefulSet
- apiGroups: ["apps"]
  resources: ["statefulsets"]
  verbs: ["get", "list", "watch"]
  resourceNames: ["postgresql"]  # ← Only THIS StatefulSet!

# ❌ CANNOT access:
# - Other secrets
# - Deployments
# - Other namespaces
```

**✅ Use When:**
- Database admin needs very limited access
- Emergency access for specific resource
- Compliance/audit requirements

**Permissions Scope:** Specific resources only!

---

## Real-World Example: Multi-Team Setup

```yaml
# Team 1: Backend Developers (limited to backend namespace)
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-dev
  namespace: backend
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backend-developer-role
  namespace: backend
rules:
- apiGroups: [""]
  resources: ["pods", "pods/logs", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-dev-binding
  namespace: backend
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: backend-developer-role
subjects:
- kind: ServiceAccount
  name: backend-dev
  namespace: backend

---
# Team 2: Database Admin (access to db namespace + cluster secrets)
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: db-admin
  namespace: database
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: database-admin-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "create", "update", "delete"]
- apiGroups: ["apps"]
  resources: ["statefulsets", "pods"]
  verbs: ["get", "list", "watch", "describe"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: db-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: database-admin-role
subjects:
- kind: ServiceAccount
  name: db-admin
  namespace: database

---
# Team 3: DevOps/SRE (near-admin access)
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: devops-role
rules:
# Can do most things except delete nodes
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
  # Explicitly exclude dangerous operations
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devops-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: devops-role
subjects:
- kind: ServiceAccount
  name: devops-team
  namespace: kube-system
```

---

# 🌐 APPROACH 2: NETWORK POLICIES - Different Patterns

## Pattern 1: Default-Deny Architecture (What We Did ✓)

```yaml
# 1. Block EVERYTHING by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}        # ← Applies to ALL pods
  policyTypes:
  - Ingress
  - Egress
  # No rules = DENY ALL!

---
# 2. Then explicitly allow specific traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-db
spec:
  podSelector:
    matchLabels:
      app: database
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
    ports:
    - port: 5432
```

**Security Model:** 🔒 Zero-Trust (Deny by default, Allow specific)

**Best For:** High-security environments (banks, healthcare)

---

## Pattern 2: Whitelist Specific Pods

```yaml
# Only allow traffic between specific pod pairs

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-cache
spec:
  podSelector:
    matchLabels:
      app: cache       # ← Allows traffic TO cache
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web     # ← From web pods ONLY
    ports:
    - port: 6379      # Redis port

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-database
spec:
  podSelector:
    matchLabels:
      app: database    # ← Allows traffic TO database
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web     # ← From web pods ONLY
    ports:
    - port: 5432

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-external
spec:
  podSelector:
    matchLabels:
      app: web         # ← Web pods can reach OUT
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          name: external
    ports:
    - port: 443        # HTTPS only
```

**Security Model:** 🟡 Segmented (Allow by tier relationship)

**Best For:** Medium-security with clear app tiers

---

## Pattern 3: Allow Same-Namespace Communication

```yaml
# Allow pods to talk within same namespace only

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
spec:
  podSelector: {}        # ← Applies to ALL pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}    # ← From pods in SAME namespace
    # No namespaceSelector = same namespace only!

---
# Additional: Allow external ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-controller
spec:
  podSelector:
    matchLabels:
      app: web
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - port: 80
    - port: 443
```

**Security Model:** 🟢 Moderate (Namespace isolation)

**Best For:** Multi-tenant clusters

---

## Pattern 4: Allow External API Calls

```yaml
# Allow pod to call external APIs (egress)

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-apis
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53

  # Allow HTTPS to external APIs
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32  # Except AWS metadata
    ports:
    - protocol: TCP
      port: 443

  # Allow database internally
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

**Use Case:** Web app calling external payment APIs, weather APIs, etc.

---

# 🐳 APPROACH 3: POD SECURITY - Different Levels

## Level 1: Permissive (Default)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-permissive
spec:
  containers:
  - name: app
    image: myapp:latest
  # No securityContext = uses defaults (can run as root!)
```

**Security Level:** 🔴 LOW - App can become root, access everything

**Risk:** High - container escape = full node compromise

---

## Level 2: Restricted (What We Did ✓)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-restricted
spec:
  securityContext:
    runAsNonRoot: true      # Must NOT be root
    runAsUser: 1000         # Specific user ID

  containers:
  - name: app
    image: myapp:latest
    
    securityContext:
      allowPrivilegeEscalation: false  # Cannot become root
      capabilities:
        drop:
        - ALL              # Remove all Linux capabilities
      readOnlyRootFilesystem: true
    
    volumeMounts:
    - name: tmp
      mountPath: /tmp

  volumes:
  - name: tmp
    emptyDir: {}
```

**Security Level:** 🟢 HIGH - Strong restrictions

**Risk:** Low - Limited what attacker can do

---

## Level 3: Ultra-Secure (Compliance)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-ultra-secure
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: runtime/default
spec:
  serviceAccountName: limited-sa

  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000           # Also set group
    fsGroup: 2000              # Volume group
    seccompProfile:
      type: RuntimeDefault      # Restrict syscalls
    seLinuxOptions:
      level: "s0:c123,c456"    # SELinux label

  containers:
  - name: app
    image: myapp:latest
    
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
      seccompProfile:
        type: RuntimeDefault
    
    resources:
      limits:
        cpu: 100m              # CPU limit
        memory: 128Mi          # Memory limit
      requests:
        cpu: 50m
        memory: 64Mi

    livenessProbe:
      httpGet:
        path: /health
        port: 3000
      initialDelaySeconds: 30
      periodSeconds: 10

    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: secrets
      mountPath: /var/secrets
      readOnly: true

  volumes:
  - name: tmp
    emptyDir: {}
  - name: secrets
    secret:
      secretName: app-credentials
      defaultMode: 0400        # Read-only

  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - myapp
        topologyKey: kubernetes.io/hostname
```

**Security Level:** 🔴 MAXIMUM - Enterprise compliance

**Protection:**
- ✅ Cannot run as root
- ✅ Cannot escalate privileges
- ✅ Read-only filesystem
- ✅ Limited system calls (seccomp)
- ✅ Resource limits = DoS protection
- ✅ Anti-affinity = availability
- ✅ SELinux labels

---

# 📊 SECRETS - Three Storage Approaches

## Approach 1: Kubernetes Secret (What We Did ✓)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  username: postgres
  password: SecurePassword123!
```

**✅ Pros:**
- Built-in to Kubernetes
- Easy to use
- No extra infrastructure

**❌ Cons:**
- Stored in etcd (needs encryption)
- Visible in describe/get
- No rotation built-in

**Use For:** Dev/test, small secrets

---

## Approach 2: ConfigMap (For Non-Sensitive)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: "postgres.default.svc.cluster.local"
  DATABASE_PORT: "5432"
  APP_ENV: "production"
  # ❌ NEVER put passwords here!
```

**✅ Pros:**
- Easy to read
- Good for configuration
- Can be updated

**❌ Cons:**
- NOT encrypted
- Can be read by anyone with permission
- Visible in plain text

**Use For:** Non-sensitive config only!

---

## Approach 3: External Vault (Enterprise)

```yaml
# Use HashiCorp Vault or AWS Secrets Manager

apiVersion: v1
kind: Pod
metadata:
  name: app-with-vault
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/agent-inject-secret-database: "secret/data/database/config"
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: vault-token
      mountPath: /vault/secrets
      readOnly: true

  # Vault agent injects secrets at runtime
  # No secrets stored in etcd!
```

**✅ Pros:**
- Maximum security
- Secrets never stored in etcd
- Automatic rotation
- Centralized management
- Audit trail

**❌ Cons:**
- Extra infrastructure
- More complex
- Requires learning Vault

**Use For:** Production/compliance environments

---

# 🔄 VERIFICATION - Three Different Methods

## Method 1: Check Permissions (What We Did ✓)

```bash
# Ask: "Can this user do this action?"
kubectl auth can-i list pods --as=system:serviceaccount:default:developer
# Output: yes/no
```

---

## Method 2: View Role Details

```bash
# Show exactly what permissions exist
kubectl get role developer-role -o yaml

# Shows:
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
  # Can see exactly what's allowed
```

---

## Method 3: Test Actual Access

```bash
# Try to actually use the permissions

# Get a token
token=$(kubectl create token developer)

# Try an action
kubectl get pods --token=$token
# Will work (allowed)

kubectl delete pods --token=$token  
# Will fail (not allowed)
```

---

# 📈 COMPARISON: When to Use Each Approach

```
┌──────────────────────────────────────────────────────────────┐
│                 CHOOSING YOUR APPROACH                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  RBAC Scope:                                                │
│  • Namespace-Role → Small team, 1 environment              │
│  • ClusterRole → DevOps, multi-environment                 │
│  • Resource-specific → Database admin, audit               │
│                                                              │
│  Network Policy:                                            │
│  • Default-deny → Banks, healthcare (high security)        │
│  • Pod-specific → Production microservices                 │
│  • Same-namespace → Multi-tenant clusters                  │
│  • External API → Public-facing apps                       │
│                                                              │
│  Pod Security:                                              │
│  • Permissive → Dev/test only                              │
│  • Restricted → Production                                 │
│  • Ultra-secure → Compliance/regulated                     │
│                                                              │
│  Secrets Storage:                                           │
│  • Kubernetes Secret → Dev/test                            │
│  • ConfigMap → Non-sensitive config                        │
│  • External Vault → Production/compliance                  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

# 🎯 Quick Decision Tree

```
Q: Is it a dev/test cluster?
  YES → Use Namespace-Role + permissive Pod Security
  NO  → Go to next Q

Q: Is it regulated (healthcare, finance)?
  YES → Use ClusterRole + default-deny NetworkPolicy + Vault
  NO  → Go to next Q

Q: Small team (< 5 people)?
  YES → Use Namespace-Role + Pod Security + Kubernetes Secrets
  NO  → Use Resource-specific + fine-grained NetworkPolicy + Vault
```

---

**Next: Which approach fits your needs?**
- Simple & quick → Namespace-scoped Role
- Multi-team → ClusterRole per team
- Highly secure → Default-deny + Vault + Ultra-secure pods
- Compliance → All three (ClusterRole + NetworkPolicy + Vault)
