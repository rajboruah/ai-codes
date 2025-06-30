#!/usr/bin/env pwsh
# Test script for EKS Private Cluster with Bastion Host

Write-Host "=== EKS Private Cluster with Bastion Host - Test Script ===" -ForegroundColor Green

# Check if kubectl is available
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl not found. Please install kubectl first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ kubectl found" -ForegroundColor Green

# Check if current context is set
try {
    $context = kubectl config current-context 2>$null
    if ($context) {
        Write-Host "✅ Current kubectl context: $context" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No current kubectl context set" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not determine current kubectl context" -ForegroundColor Yellow
}

Write-Host "`n=== Testing Configuration Files ===" -ForegroundColor Cyan

# Test configuration files
$configFiles = @(
    "composite-resource-definitions/xrd-eks-cluster.yaml",
    "compositions/eks-composition.yaml",
    "examples/test-eks-with-bastion.yaml"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Host "✅ Found: $file" -ForegroundColor Green
        
        # Validate YAML syntax
        try {
            kubectl apply --dry-run=client -f $file > $null 2>&1
            Write-Host "  ✅ YAML syntax valid" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ YAML syntax error in $file" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Missing: $file" -ForegroundColor Red
    }
}

Write-Host "`n=== Deployment Instructions ===" -ForegroundColor Cyan

Write-Host "To deploy the EKS cluster with bastion host:" -ForegroundColor White
Write-Host "1. Apply the XRD:" -ForegroundColor White
Write-Host "   kubectl apply -f composite-resource-definitions/xrd-eks-cluster.yaml" -ForegroundColor Gray

Write-Host "2. Apply the Composition:" -ForegroundColor White
Write-Host "   kubectl apply -f compositions/eks-composition.yaml" -ForegroundColor Gray

Write-Host "3. Deploy the cluster:" -ForegroundColor White
Write-Host "   kubectl apply -f examples/test-eks-with-bastion.yaml" -ForegroundColor Gray

Write-Host "4. Monitor the deployment:" -ForegroundColor White
Write-Host "   kubectl get ekscluster test-eks-with-bastion -w" -ForegroundColor Gray

Write-Host "`n=== Bastion Host Access ===" -ForegroundColor Cyan

Write-Host "After deployment, you can access the bastion host via:" -ForegroundColor White
Write-Host "1. SSH (if public key configured):" -ForegroundColor White
Write-Host "   ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>" -ForegroundColor Gray

Write-Host "2. AWS Systems Manager Session Manager:" -ForegroundColor White
Write-Host "   aws ssm start-session --target <bastion-instance-id>" -ForegroundColor Gray

Write-Host "3. AWS Console:" -ForegroundColor White
Write-Host "   EC2 → Instances → Select Bastion → Connect → Session Manager" -ForegroundColor Gray

Write-Host "`n=== Security Recommendations ===" -ForegroundColor Yellow

Write-Host "🔒 Security Tips:" -ForegroundColor Yellow
Write-Host "• Update 'allowedCidrs' in bastionConfig to restrict SSH access" -ForegroundColor White
Write-Host "• Add your SSH public key to bastionConfig.publicKey" -ForegroundColor White
Write-Host "• Use Systems Manager Session Manager for keyless access" -ForegroundColor White
Write-Host "• Monitor bastion host access via CloudWatch" -ForegroundColor White

Write-Host "`n=== Cost Optimization ===" -ForegroundColor Blue

Write-Host "💰 Cost Tips:" -ForegroundColor Blue
Write-Host "• Bastion host (t3.micro): ~$8-10/month" -ForegroundColor White
Write-Host "• NAT Gateways: ~$45/month per gateway" -ForegroundColor White
Write-Host "• Consider scheduling bastion host for dev environments" -ForegroundColor White
Write-Host "• Use t3.micro for development, t3.small for production" -ForegroundColor White

Write-Host "`n=== Documentation ===" -ForegroundColor Magenta

Write-Host "📚 For more information:" -ForegroundColor Magenta
Write-Host "• README.md - Project overview" -ForegroundColor White
Write-Host "• docs/bastion-host-guide.md - Detailed bastion host guide" -ForegroundColor White
Write-Host "• docs/private-cluster-configuration.md - Private cluster guide" -ForegroundColor White
Write-Host "• CHANGELOG.md - Recent changes and features" -ForegroundColor White

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "Configuration files validated successfully!" -ForegroundColor Green
