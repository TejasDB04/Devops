# Security Lab — Today (RBAC + Network Policies)

**Time:** ~45 minutes  
**Prerequisite:** Docker Desktop Kubernetes **enabled** and `kubectl get nodes` shows `Ready`.

---

## What you will learn

| Concept | What it does |
|---------|----------------|
| **RBAC** | Controls who can run which `kubectl` commands |
| **ServiceAccount** | Identity used by pods or users |
| **Role / RoleBinding** | Permissions in one namespace |
| **ClusterRole / ClusterRoleBinding** | Permissions cluster-wide |
| **NetworkPolicy** | Firewall between pods |
| **Pod securityContext** | Run as non-root, drop capabilities |

---

## Step 0 — Start cluster

```powershell
# Docker Desktop → Settings → Kubernetes → Enable
cd "C:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"
kubectl get nodes
```

---

## Step 1 — Apply all security manifests

```powershell
.\labs\security-apply.ps1
```

This creates:

- ServiceAccounts: `developer`, `admin-user`
- Roles: `developer-role` (read-only), `admin-role` (full access)
- NetworkPolicies: `default-deny`, `allow-ingress-to-web`, `allow-k8s-app`
- Secret + `secure-app` pod (hardened container)

---

## Step 2 — Label & redeploy app (tier=web)

```powershell
kubectl apply -f deployment.yaml
kubectl rollout status deployment/k8s-app --timeout=120s
kubectl get pods -l app=k8s-app --show-labels
```

Expect label `tier=web` on pods.

---

## Step 3 — Verify RBAC

```powershell
.\labs\security-verify.ps1
```

**Expected:**

| Check | Result |
|-------|--------|
| Developer `get` deployments | `yes` |
| Developer `delete` deployments | `no` |
| Admin `delete` deployments | `yes` |

**Manual tests:**

```powershell
kubectl auth can-i delete deployments --as=system:serviceaccount:default:developer
kubectl auth can-i delete deployments --as=system:serviceaccount:default:admin-user
kubectl get roles,rolebindings -n default
```

---

## Step 4 — Verify Network Policies

```powershell
kubectl get networkpolicies
kubectl describe networkpolicy default-deny
kubectl describe networkpolicy allow-k8s-app
```

**Test app still works:**

```powershell
kubectl get pods -l app=k8s-app
$pod = kubectl get pods -l app=k8s-app -o jsonpath="{.items[0].metadata.name}"
kubectl exec $pod -- wget -qO- http://localhost:3000/api/health
```

Or port-forward:

```powershell
kubectl port-forward svc/k8s-app-service 8080:80
```

Browser: http://localhost:8080/api/health

---

## Step 5 — Secure pod

```powershell
kubectl get pod secure-app
kubectl describe pod secure-app | Select-String -Pattern "runAsNonRoot|readOnlyRootFilesystem|drop"
```

Shows pod security hardening (non-root, read-only root FS, dropped capabilities).

---

## Step 6 — Understand the rules (read once)

**Developer role** — can list/get pods and deployments, **cannot** delete:

```1:25:developer-role.yaml
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
// ... more read-only rules ...
```

**Default deny** — blocks all pod traffic until allow rules exist:

```1:11:default-deny-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Unable to connect to the server` | Enable Kubernetes in Docker Desktop |
| App unreachable after NetworkPolicy | `kubectl apply -f labs/security/allow-k8s-app.yaml` |
| `secure-app` ImagePullBackOff | `docker build -t k8s-app:latest .` then re-apply `secure-pod.yaml` |
| Developer can delete | Re-apply `developer-rolebinding.yaml` |

---

## Lab complete checklist

- [ ] `security-apply.ps1` ran without errors
- [ ] Developer **cannot** delete deployments
- [ ] Admin **can** delete deployments
- [ ] NetworkPolicies listed (`default-deny`, `allow-k8s-app`)
- [ ] `/api/health` still returns OK on k8s-app
- [ ] `secure-app` pod is `Running`

---

## Next lab (after Security)

**Blue-Green deployment:**

```powershell
kubectl apply -f labs/blue-green/
```

See `BLUEGREEN_LAB.md` or `DEVOPS_REMAINING_LABS.md`.
