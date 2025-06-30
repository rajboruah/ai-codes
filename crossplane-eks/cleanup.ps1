#!/usr/bin/env pwsh

# Cleanup EKS Cluster resources deployed with Crossplane
param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$KubectlContext = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "🧹 Cleaning up EKS Cluster resources" -ForegroundColor Yellow

# Set kubectl context if provided
if ($KubectlContext) {
    Write-Host "📝 Setting kubectl context to: $KubectlContext" -ForegroundColor Yellow
    kubectl config use-context $KubectlContext
}

# Confirm deletion unless force is specified
if (-not $Force) {
    $confirmation = Read-Host "Are you sure you want to delete the $Environment EKS cluster and all related resources? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "❌ Cleanup cancelled" -ForegroundColor Red
        exit 0
    }
}

# Delete the EKS cluster instance
$exampleFile = "examples/$Environment-eks-cluster.yaml"
if (Test-Path $exampleFile) {
    Write-Host "🗑️  Deleting $Environment EKS cluster..." -ForegroundColor Yellow
    kubectl delete -f $exampleFile --timeout=300s
    Write-Host "✅ EKS cluster deletion initiated" -ForegroundColor Green
} else {
    Write-Host "⚠️  Example file not found: $exampleFile" -ForegroundColor Red
}

# Wait for managed resources to be cleaned up
Write-Host "⏳ Waiting for managed resources to be cleaned up..." -ForegroundColor Yellow
$timeout = 600  # 10 minutes
$elapsed = 0
do {
    $managedResources = kubectl get managed --no-headers 2>$null
    if (-not $managedResources) {
        Write-Host "✅ All managed resources cleaned up" -ForegroundColor Green
        break
    }
    
    Write-Host "📊 Remaining managed resources: $($managedResources.Count)" -ForegroundColor Cyan
    Start-Sleep 30
    $elapsed += 30
} while ($elapsed -lt $timeout)

if ($elapsed -ge $timeout) {
    Write-Host "⚠️  Timeout waiting for managed resources cleanup" -ForegroundColor Red
    Write-Host "Some resources may still be cleaning up in the background" -ForegroundColor Yellow
}

# Optionally delete the composition and XRD (commented out by default)
# Uncomment these lines if you want to completely remove the Crossplane configuration
<#
Write-Host "🗑️  Deleting Composition..." -ForegroundColor Yellow
kubectl delete -f compositions/eks-composition.yaml

Write-Host "🗑️  Deleting XRD..." -ForegroundColor Yellow
kubectl delete -f composite-resource-definitions/xrd-eks-cluster.yaml

Write-Host "🗑️  Deleting KCL Function..." -ForegroundColor Yellow
kubectl delete -f compositions/function-kcl.yaml
#>

Write-Host "🎉 Cleanup completed!" -ForegroundColor Green
Write-Host "Note: AWS resources may take additional time to fully terminate" -ForegroundColor Yellow
