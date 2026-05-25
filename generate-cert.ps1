# Generate self-signed TLS certificate
$cert = New-SelfSignedCertificate -DnsName 'myapp.local', 'api.myapp.local' -CertStoreLocation 'cert:\CurrentUser\My' -FriendlyName 'MyApp TLS Certificate'
Write-Host "Certificate created with thumbprint: $($cert.Thumbprint)"

# Export as PFX
$password = ConvertTo-SecureString -String 'password' -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath 'app.pfx' -Password $password -Force
Write-Host 'Exported app.pfx'

# Create Kubernetes secret files
$pfxBytes = [System.IO.File]::ReadAllBytes("$PWD\app.pfx")
$base64Pfx = [System.Convert]::ToBase64String($pfxBytes)

@"
apiVersion: v1
kind: Secret
metadata:
  name: app-tls-cert
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: $(if (Test-Path app.crt) { [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$PWD\app.crt")) })
  tls.key: $(if (Test-Path app.key) { [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$PWD\app.key")) })
  pfx: $base64Pfx
"@ | Out-File tls-secret.yaml

Write-Host 'Created tls-secret.yaml'
