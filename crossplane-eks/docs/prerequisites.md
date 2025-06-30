# Prerequisites and Installation Guide

## Prerequisites

### 1. Kubernetes Cluster
You need a Kubernetes cluster with Crossplane installed. You can use:
- **EKS** (for AWS)
- **GKE** (for Google Cloud)  
- **AKS** (for Azure)
- **Kind/Minikube** (for local development)

### 2. Install Crossplane

```bash
# Add Crossplane Helm repository
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane
helm install crossplane crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace
```

### 3. Install AWS Provider

```bash
# Create AWS Provider
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-aws:v0.47.0
EOF

# Wait for provider to be healthy
kubectl wait --for=condition=healthy provider.pkg.crossplane.io/provider-aws --timeout=300s
```

### 4. Configure AWS Credentials

```bash
# Create AWS credentials secret
kubectl create secret generic aws-secret \
    -n crossplane-system \
    --from-file=creds=./aws-credentials.txt

# Create ProviderConfig
kubectl apply -f - <<EOF
apiVersion: aws.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
EOF
```

### 5. Install KCL Tools

#### Windows (PowerShell)
```powershell
# Install KCL using winget
winget install KusionStack.KCL

# Or using Chocolatey
choco install kcl
```

#### Linux/macOS
```bash
# Install KCL
curl -fsSL https://kcl-lang.io/script/install.sh | /bin/bash

# Or using Homebrew
brew install kcl-lang/tap/kcl
```

### 6. Verify Installation

```bash
# Check Crossplane
kubectl get pods -n crossplane-system

# Check AWS Provider
kubectl get providers

# Check KCL
kcl version
```

## AWS Credentials Format

Create `aws-credentials.txt` file:
```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

## Required AWS Permissions

Your AWS credentials need the following permissions:
- EC2 (VPC, Subnets, Security Groups, Internet Gateway)
- EKS (Cluster, Node Groups, Addons)
- IAM (Roles, Policies, Policy Attachments)

## Troubleshooting

### Common Issues

1. **Provider not healthy**: Check provider logs
   ```bash
   kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-aws
   ```

2. **AWS permissions**: Ensure your AWS credentials have sufficient permissions

3. **KCL function errors**: Check function logs
   ```bash
   kubectl logs -n crossplane-system -l app.kubernetes.io/name=function-kcl
   ```

### Useful Commands

```bash
# Check all Crossplane resources
kubectl get crossplane

# Check managed resources
kubectl get managed

# Describe a specific resource
kubectl describe cluster my-eks-cluster

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```
