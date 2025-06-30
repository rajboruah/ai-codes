#!/usr/bin/env pwsh

# Deploy EKS Cluster using Crossplane and KCL
# This script deploys the Crossplane resources for EKS cluster creation

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$KubectlContext = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "🚀 Deploying EKS Cluster with Crossplane and KCL" -ForegroundColor Green

# Set kubectl context if provided
if ($KubectlContext) {
    Write-Host "📝 Setting kubectl context to: $KubectlContext" -ForegroundColor Yellow
    kubectl config use-context $KubectlContext
}

# Check if Crossplane is installed
Write-Host "🔍 Checking Crossplane installation..." -ForegroundColor Yellow
$crossplaneStatus = kubectl get pods -n crossplane-system -l app=crossplane --no-headers 2>$null
if (-not $crossplaneStatus) {
    Write-Host "❌ Crossplane not found. Please install Crossplane first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Crossplane is installed and running" -ForegroundColor Green

# Install KCL Function if not exists
Write-Host "🔍 Checking KCL Function installation..." -ForegroundColor Yellow
$kclFunction = kubectl get function function-kcl --no-headers 2>$null
if (-not $kclFunction) {
    Write-Host "📦 Installing KCL Function..." -ForegroundColor Yellow
    if ($DryRun) {
        Write-Host "[DRY RUN] Would install: compositions/function-kcl.yaml" -ForegroundColor Cyan
    } else {
        kubectl apply -f compositions/function-kcl.yaml
        Write-Host "✅ KCL Function installed" -ForegroundColor Green
    }
} else {
    Write-Host "✅ KCL Function already installed" -ForegroundColor Green
}

# Apply Composite Resource Definition
Write-Host "📋 Applying Composite Resource Definition..." -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "[DRY RUN] Would apply: composite-resource-definitions/xrd-eks-cluster.yaml" -ForegroundColor Cyan
} else {
    kubectl apply -f composite-resource-definitions/xrd-eks-cluster.yaml
    Write-Host "✅ XRD applied successfully" -ForegroundColor Green
}

# Apply Composition
Write-Host "🏗️  Applying EKS Composition..." -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "[DRY RUN] Would apply: compositions/eks-composition.yaml" -ForegroundColor Cyan
} else {
    kubectl apply -f compositions/eks-composition.yaml
    Write-Host "✅ Composition applied successfully" -ForegroundColor Green
}

# Wait for XRD to be established
if (-not $DryRun) {
    Write-Host "⏳ Waiting for XRD to be established..." -ForegroundColor Yellow
    kubectl wait --for=condition=established xrd/xeksclusters.aws.platform.io --timeout=60s
    Write-Host "✅ XRD is established" -ForegroundColor Green
}

# Apply example cluster based on environment
$exampleFile = "examples/$Environment-eks-cluster.yaml"
if (Test-Path $exampleFile) {
    Write-Host "🎯 Deploying $Environment EKS cluster..." -ForegroundColor Yellow
    if ($DryRun) {
        Write-Host "[DRY RUN] Would apply: $exampleFile" -ForegroundColor Cyan
        kubectl apply -f $exampleFile --dry-run=client -o yaml
    } else {
        kubectl apply -f $exampleFile
        Write-Host "✅ EKS cluster deployment initiated" -ForegroundColor Green
        
        # Monitor the deployment
        Write-Host "📊 Monitoring cluster deployment..." -ForegroundColor Yellow
        Write-Host "You can monitor the progress with:" -ForegroundColor Cyan
        Write-Host "  kubectl get ekscluster" -ForegroundColor White
        Write-Host "  kubectl describe ekscluster $Environment-eks-cluster" -ForegroundColor White
        Write-Host "  kubectl get managed" -ForegroundColor White
    }
} else {
    Write-Host "⚠️  Example file not found: $exampleFile" -ForegroundColor Red
    Write-Host "Available examples:" -ForegroundColor Yellow
    Get-ChildItem examples/*.yaml | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor White }
}

Write-Host "🎉 Deployment script completed!" -ForegroundColor Green
