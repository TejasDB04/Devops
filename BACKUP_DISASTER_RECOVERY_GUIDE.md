# 🔄 Backup & Disaster Recovery with Velero

Protect your Kubernetes cluster from disaster!

---

## The Problem: Disaster Scenarios

```
Monday: Cluster working fine ✅

Tuesday 3 AM:
  - Ransomware deletes all pods
  - Accidental: kubectl delete namespace production
  - Hard drive failure
  - Hacker compromises cluster
  - Misconfiguration breaks everything

Result:
  - Lost all deployments
  - Lost all data
  - Lost all configurations
  - Services down 😱
  - Angry customers 📞
  - Lost revenue 💰
```

---

## Solution: Backup & Disaster Recovery

```
Regular Backups:
Every hour → Backup cluster state → Store in S3
Every hour → Backup database → Store in S3

Disaster happens at 3 AM:
  ↓
Restore from backup → New cluster in 5 minutes ✅
Services back online ✅
Lost only 1 hour of data (acceptable!) ✅
```

---

## What Needs Backup?

```
┌────────────────────────────────┐
│  Kubernetes Cluster            │
├────────────────────────────────┤
│                                │
│ Must Backup: ✅                │
│ ├─ Deployments                │
│ ├─ StatefulSets               │
│ ├─ Services                   │
│ ├─ Ingress                    │
│ ├─ ConfigMaps                 │
│ ├─ Secrets                    │
│ ├─ PersistentVolumes (data)  │
│ └─ RBAC (roles, bindings)     │
│                                │
│ Strategies:                    │
│ ├─ Cluster-level backup       │
│ │  (entire Kubernetes)        │
│ └─ Application-level backup   │
│    (specific data only)        │
└────────────────────────────────┘
```

---

## Velero: Backup Tool for Kubernetes

**Velero** = "Fast" in Spanish = Backup everything quickly!

```
Velero Architecture:

┌─────────────────────────────────┐
│  Kubernetes Cluster             │
│                                 │
│ ┌─────────────────────────────┐ │
│ │   Velero Server             │ │
│ │   (Watches & backs up)      │ │
│ │   ┌───────────────────────┐ │ │
│ │   │ Backup CRD            │ │ │
│ │   │ Restore CRD           │ │ │
│ │   │ BackupLocation CRD    │ │ │
│ │   └───────────────────────┘ │ │
│ └─────────────────────────────┘ │
│                                 │
└────────┬────────────────────────┘
         │
         ├─→ Store in AWS S3 (cloud)
         ├─→ Store in MinIO (on-prem)
         └─→ Store in Azure Blob Storage
```

---

## Backup Scenarios

### Scenario 1: Full Cluster Backup

```powershell
# Backup entire cluster
velero backup create production-backup

# Result: Full cluster saved to S3
# Size: ~1GB per cluster
# Time: ~5 minutes
```

### Scenario 2: Selective Backup (Namespace Only)

```powershell
# Backup only production namespace
velero backup create prod-backup --include-namespaces production

# Backup only app namespace
velero backup create app-backup --include-namespaces app-ns
```

### Scenario 3: Exclude Sensitive Data

```powershell
# Backup everything EXCEPT secrets
velero backup create safe-backup --exclude-resources secrets

# Why? Secrets might contain passwords, API keys
# Backup only what you can share!
```

---

## Restore Scenarios

### Scenario 1: Disaster Recovery (Full Restore)

```
3 AM: Hacker deletes everything!

08:00 AM: You notice
           ↓
08:05 AM: velero restore create --from-backup production-backup
           ↓
08:10 AM: Cluster recovered ✅
           All deployments, services, data back!
```

### Scenario 2: Accidental Delete Recovery

```
Developer: kubectl delete namespace production
           ↓
5 seconds later: "NOOO! Wrong command!"
           ↓
You: velero restore create --from-backup prod-backup
     --namespace-mappings production=production-restored
           ↓
Data recovered in namespace "production-restored"
Can compare old vs new! ✅
```

### Scenario 3: Migrate to Different Cluster

```
Old Cluster (failing hardware):
  velero backup create migration-backup

New Cluster (fresh installation):
  kubectl apply -f velero-installation.yaml
  velero restore create --from-backup migration-backup
  
Result: Everything migrated! ✅
```

---

## Installation: AWS S3

### Step 1: Create AWS S3 Bucket

```powershell
# Create bucket for backups
aws s3 mb s3://my-velero-backups-prod

# Enable versioning (protection against deletion)
aws s3api put-bucket-versioning `
  --bucket my-velero-backups-prod `
  --versioning-configuration Status=Enabled
```

### Step 2: Create IAM User for Velero

```powershell
# Create user with S3 access only
aws iam create-user --user-name velero-user

# Create access keys
aws iam create-access-key --user-name velero-user

# Attach policy (S3 access only!)
aws iam attach-user-policy `
  --user-name velero-user `
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### Step 3: Install Velero in Cluster

```powershell
# Download Velero
# From: https://github.com/vmware-tanzu/velero/releases

# Create credentials file
$creds = @"
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
"@
$creds | Out-File credentials-velero

# Install Velero
velero install `
  --provider aws `
  --bucket my-velero-backups-prod `
  --secret-file .\credentials-velero `
  --use-volume-snapshots=false `
  --snapshot-location-config snapshotLocation=us-east-1
```

### Step 4: Verify Installation

```powershell
kubectl get pods -n velero

# Expected:
# velero-xxxxx  Running
# minio-xxxxx   Running (if using MinIO)
```

---

## Usage: Create & Restore Backups

### Create Backup

```powershell
# Full cluster backup
velero backup create my-backup

# Backup specific namespace
velero backup create ns-backup --include-namespaces production

# Backup specific resources
velero backup create app-backup --include-resources deployments,services

# Scheduled backup (every day at 2 AM)
velero schedule create daily-backup --schedule="0 2 * * *"
```

### List Backups

```powershell
velero backup get

# Output:
# NAME            STATUS    ERRORS  WARNINGS
# my-backup       Completed 0       0
# ns-backup       Completed 0       0
```

### Restore from Backup

```powershell
# Full restore
velero restore create --from-backup my-backup

# Restore to different namespace
velero restore create --from-backup my-backup `
  --namespace-mappings=old-ns=new-ns

# Restore specific resource
velero restore create --from-backup my-backup `
  --include-resources deployments
```

### Monitor Restore

```powershell
velero restore describe my-backup-restore
velero restore logs my-backup-restore
```

---

## Backup Strategy Matrix

```
Every cluster needs strategy:

┌──────────────────────────────────────────┐
│     Backup Strategy Selection            │
├──────────────────────────────────────────┤
│                                          │
│ Development Cluster:                    │
│ ├─ Frequency: Daily                     │
│ ├─ Retention: 7 days                    │
│ ├─ Cost: Low                            │
│ └─ Purpose: Easy recovery               │
│                                          │
│ Production Cluster:                     │
│ ├─ Frequency: Every 4 hours             │
│ ├─ Retention: 90 days                   │
│ ├─ Cost: High                           │
│ └─ Purpose: Disaster recovery           │
│                                          │
│ Data-Critical Services (Databases):     │
│ ├─ Frequency: Every 1 hour              │
│ ├─ Retention: 180 days                  │
│ ├─ Cost: Very High                      │
│ ├─ Multiple locations                   │
│ └─ Purpose: No data loss                │
│                                          │
└──────────────────────────────────────────┘
```

---

## High Availability Backup

```
Multiple backup locations:

┌──────────────────┐
│  Primary Region  │
│  (S3 us-east-1)  │
└────────┬─────────┘
         │
    Backup every 4 hours
         │
         ├───→ Copy to Secondary Region
         │     (S3 us-west-2)
         │
         └───→ Copy to Off-site
              (S3 eu-west-1)

If Primary region fails:
  → Restore from Secondary ✅
  → Restore from Off-site ✅
  → High availability! ✅
```

---

## Real Disaster Scenario Timeline

```
Monday 2 PM: Ransomware attack detected!
            All pods encrypted, can't start

Immediately:
  1. Take cluster offline (prevent spread)
  2. velero get backups (find latest good backup)
  3. Create new cluster (cloud provision)
  4. Install Velero in new cluster
  5. velero restore create --from-backup
  6. Wait 15 minutes...
  7. New cluster up! ✅
  8. Update DNS/load balancers

Result:
  - 30 minute downtime (acceptable for disaster!)
  - All data recovered
  - All deployments restored
  - Back to production ✅
```

---

## Best Practices

```yaml
✅ DO:
- Backup frequently (at least daily)
- Test restores regularly (know it actually works!)
- Store backups in multiple regions
- Encrypt backups (at rest + in transit)
- Monitor backup jobs (alerts on failure)
- Document restore procedures
- Practice disaster recovery drills

❌ DON'T:
- Only backup once (what if that backup fails?)
- Skip testing restores (untested = unreliable)
- Store backups in same region (region failure = lost backup)
- Use weak encryption
- Assume backups work (verify!)
- Forget to backup persistent volumes
```

---

## Common Backup Mistakes

| Mistake | Problem | Solution |
|---------|---------|----------|
| No backups | Any failure = permanent data loss | Daily backup schedule |
| Untested backups | Backups might not work | Test restore monthly |
| Single location backup | Region fails = backup lost | Multi-region backup |
| Backing up secrets in Plain | Hacked backup = leaked passwords | Separate backup for secrets |
| No retention policy | Backup storage grows forever | Delete old backups (30-90 days) |
| Forgot PersistentVolumes | Lost all data in databases | Include volumes in backup |

---

## Compliance & Security

```yaml
Production Backup Requirements:
- ✅ 99.9% availability (backup system rarely down)
- ✅ Encryption in transit (TLS)
- ✅ Encryption at rest (AES-256)
- ✅ Backup integrity checks (MD5, SHA)
- ✅ Access logs (who accessed backups)
- ✅ Geographic redundancy (>500 miles apart)
- ✅ Retention per regulations
  - HIPAA: 7 years
  - Finance: 5 years
  - GDPR: Right to delete
```

---

## Integration with Other Tools

**Velero + Helm:**
```powershell
# Backup Helm releases
velero backup create helm-backup --include-namespaces helm-namespace
```

**Velero + Database:**
```powershell
# Pre-backup hook: Flush database caches
velero backup create db-backup --wait

# Results in clean backup state!
```

**Velero + GitOps (ArgoCD):**
```
Disaster:
1. Restore cluster from Velero backup
2. ArgoCD automatically re-syncs from Git
3. Cluster configuration guaranteed correct ✅
```

---

## Cost Analysis

```
AWS S3 Backup Costs (monthly):

Scenario 1: Small cluster (1 backup/day)
├─ Backup size: 500MB
├─ 30 backups × 500MB = 15GB
├─ S3 storage: $0.023/GB = $0.35/month
└─ Total: ~$0.50/month ✅ Cheap!

Scenario 2: Large production (4 backups/day, 90 days)
├─ Backup size: 10GB
├─ 4 × 90 = 360 backups = 3.6TB
├─ S3 storage: $0.023/GB = $82.80/month
├─ Add lifecycle policies (older→cheaper tier)
└─ Total: ~$50/month 💰 Worth it!

Scenario 3: Failure without backup
├─ Downtime: 8 hours × $50K/hour = $400,000 😱
├─ Data loss: Possibly millions
└─ Cost of backup: Negligible! ✅
```

---

## Testing Disaster Recovery

**Monthly Drill:**
```powershell
# 1. Create test cluster
kubectl create cluster test-cluster

# 2. Restore from backup
velero restore create --from-backup production-backup

# 3. Verify everything works
kubectl get pods
kubectl get services
# Test app connectivity

# 4. Document any issues
# (Your procedures might need updating!)

# 5. Delete test cluster
kubectl delete cluster test-cluster
```

---

## 💡 Key Points

✅ **Backup is a must-have** - Not optional!  
✅ **Test regularly** - Know your backups work!  
✅ **Multiple locations** - Regional failure != total loss  
✅ **Encryption** - Backup data is sensitive!  
✅ **Monitoring** - Know immediately if backup fails  
✅ **Documentation** - Procedures must be clear  
✅ **Practice** - Test restores before you need them!  

---

## 🎯 Implementation Checklist

```
□ Define backup strategy (frequency, retention)
□ Choose storage (AWS S3, Azure, MinIO)
□ Install Velero in cluster
□ Configure credentials (IAM, access keys)
□ Create first backup
□ Verify backup (check S3 console)
□ Test restore (create test cluster)
□ Document procedures
□ Set up monitoring/alerts
□ Schedule regular backups (automated)
□ Monthly: Disaster recovery drills
```

---

## 📊 Final Summary

**You've now completed all 9 DevOps topics!**

✅ #1 StatefulSets (databases with persistent storage)
✅ #2 HPA (auto-scaling based on metrics)
✅ #3 Monitoring (Prometheus + Grafana)
✅ #4 Logging (Loki + log aggregation)
✅ #5 Helm (package management)
✅ #6 Security (RBAC + Network Policies)
✅ #7 Advanced Deployment (Blue-Green, Canary)
✅ #8 GitOps (ArgoCD, Git-driven deployment)
✅ #9 Backup & Disaster Recovery (Velero)

**You are now a Kubernetes DevOps engineer!** 🚀

---

## 🏆 What You've Mastered

| Topic | What You Can Do | Enterprise Value |
|-------|-----------------|-------------------|
| StatefulSets | Deploy & scale databases | Critical |
| HPA | Auto-scale applications | High |
| Monitoring | Track performance metrics | Critical |
| Logging | Centralize & search logs | High |
| Helm | Package & distribute apps | Very High |
| Security | Protect cluster & data | Critical |
| Advanced Deploy | Zero-downtime releases | High |
| GitOps | Version-control everything | Critical |
| Backup/Recovery | Disaster recovery | Critical |

**Total learning time: ~12 hours**  
**Enterprise DevOps skills: ⭐⭐⭐⭐⭐**

Ready to practice everything together? 🎯
