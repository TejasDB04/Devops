# Install Velero on Windows

Velero has **two parts**: CLI on your PC + server in the cluster.

## Part A — Install CLI (fixes `velero : not recognized`)

### Option 1: PowerShell script (recommended)

```powershell
cd "C:\Users\tedb\OneDrive - Nokia\Desktop\kubernates"
.\labs\velero\install-velero-cli.ps1
```

Close and reopen PowerShell, then:

```powershell
velero version --client-only
```

### Option 2: Manual download

1. Open https://github.com/vmware-tanzu/velero/releases
2. Download `velero-v1.13.0-windows-amd64.tar.gz` (or latest)
3. Extract `velero.exe` to a folder on your PATH (e.g. `C:\Tools\velero\`)
4. Add that folder to **System PATH** → Environment Variables

## Part B — Install Velero in cluster (required before backup)

Backup needs object storage (MinIO for local lab). Full steps: [BACKUP_DISASTER_RECOVERY_GUIDE.md](../../BACKUP_DISASTER_RECOVERY_GUIDE.md)

**Skip Lab 6** until CLI + cluster install are done — Labs 1–5 do not need Velero.

## Quick test (after CLI install)

```powershell
velero version --client-only
```

Expected: `Client: version v1.x.x`
