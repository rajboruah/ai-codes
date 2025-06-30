#!/usr/bin/env pwsh

# Monitor EKS Cluster deployment status
param(
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "dev-eks-cluster",
    
    [Parameter(Mandatory=$false)]
    [string]$KubectlContext = "",
    
    [Parameter(Mandatory=$false)]
    [int]$RefreshInterval = 30
)

Write-Host "📊 Monitoring EKS Cluster deployment: $ClusterName" -ForegroundColor Green

# Set kubectl context if provided
if ($KubectlContext) {
    Write-Host "📝 Setting kubectl context to: $KubectlContext" -ForegroundColor Yellow
    kubectl config use-context $KubectlContext
}

function Show-ClusterStatus {
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "📅 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host "="*80 -ForegroundColor Cyan
    
    # Check EKS Cluster status
    Write-Host "`n🎯 EKS Cluster Status:" -ForegroundColor Yellow
    kubectl get ekscluster $ClusterName -o wide 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ EKS Cluster not found or not ready" -ForegroundColor Red
    }
    
    # Check all managed resources
    Write-Host "`n🔧 Managed Resources:" -ForegroundColor Yellow
    $managedResources = kubectl get managed --no-headers 2>$null
    if ($managedResources) {
        kubectl get managed -o wide
        
        # Count resources by status
        $ready = ($managedResources | Where-Object { $_ -match "True" }).Count
        $total = $managedResources.Count
        Write-Host "`n📈 Progress: $ready/$total resources ready" -ForegroundColor Cyan
    } else {
        Write-Host "No managed resources found" -ForegroundColor Red
    }
    
    # Check for any failed resources
    Write-Host "`n❌ Failed Resources:" -ForegroundColor Red
    kubectl get managed -o wide | Where-Object { $_ -match "False" }
    
    # Show recent events
    Write-Host "`n📋 Recent Events:" -ForegroundColor Yellow
    kubectl get events --sort-by=.metadata.creationTimestamp | Select-Object -Last 10
}

function Show-DetailedStatus {
    param($ResourceName)
    
    Write-Host "`n🔍 Detailed status for $ResourceName:" -ForegroundColor Cyan
    kubectl describe ekscluster $ResourceName
}

# Main monitoring loop
Write-Host "🔄 Starting monitoring (Ctrl+C to stop)..." -ForegroundColor Green
Write-Host "Press 'd' + Enter for detailed status" -ForegroundColor Cyan

try {
    while ($true) {
        Show-ClusterStatus
        
        # Check if user wants detailed status
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.KeyChar -eq 'd') {
                Show-DetailedStatus $ClusterName
            }
        }
        
        Write-Host "`n⏳ Next update in $RefreshInterval seconds..." -ForegroundColor Gray
        Start-Sleep $RefreshInterval
        Clear-Host
    }
}
catch {
    Write-Host "`n👋 Monitoring stopped" -ForegroundColor Yellow
}

Write-Host "`n🎉 Monitoring completed!" -ForegroundColor Green
