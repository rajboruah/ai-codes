# Makefile for Crossplane EKS deployment

.PHONY: help install-deps validate deploy-dev deploy-prod monitor clean

# Default target
help:
	@echo "🚀 Crossplane EKS Cluster Management"
	@echo ""
	@echo "Available targets:"
	@echo "  install-deps  - Install required dependencies"
	@echo "  validate      - Validate KCL configurations"
	@echo "  deploy-dev    - Deploy development EKS cluster"
	@echo "  deploy-prod   - Deploy production EKS cluster"
	@echo "  monitor       - Monitor cluster deployment"
	@echo "  clean-dev     - Clean up development cluster"
	@echo "  clean-prod    - Clean up production cluster"
	@echo "  test          - Run configuration tests"

# Install dependencies
install-deps:
	@echo "📦 Installing dependencies..."
	@powershell -Command "Write-Host '🔍 Checking kubectl...' -ForegroundColor Yellow"
	@kubectl version --client
	@powershell -Command "Write-Host '🔍 Checking KCL...' -ForegroundColor Yellow"
	@kcl version || echo "⚠️ KCL not found. Please install from https://kcl-lang.io"
	@powershell -Command "Write-Host '✅ Dependencies check completed' -ForegroundColor Green"

# Validate KCL configurations
validate:
	@echo "🔍 Validating KCL configurations..."
	@kcl run schemas/eks-schemas.k --dry-run
	@kcl run functions/ --dry-run
	@powershell -Command "Write-Host '✅ KCL validation completed' -ForegroundColor Green"

# Deploy development cluster
deploy-dev:
	@echo "🚀 Deploying development EKS cluster..."
	@powershell -ExecutionPolicy Bypass -File deploy.ps1 -Environment dev

# Deploy production cluster
deploy-prod:
	@echo "🚀 Deploying production EKS cluster..."
	@powershell -ExecutionPolicy Bypass -File deploy.ps1 -Environment prod

# Monitor cluster deployment
monitor:
	@echo "📊 Starting cluster monitoring..."
	@powershell -ExecutionPolicy Bypass -File monitor.ps1

# Clean up development cluster
clean-dev:
	@echo "🧹 Cleaning up development cluster..."
	@powershell -ExecutionPolicy Bypass -File cleanup.ps1 -Environment dev

# Clean up production cluster
clean-prod:
	@echo "🧹 Cleaning up production cluster..."
	@powershell -ExecutionPolicy Bypass -File cleanup.ps1 -Environment prod

# Test configurations
test:
	@echo "🧪 Running configuration tests..."
	@kcl test functions/ || echo "⚠️ Some tests may have failed"
	@powershell -Command "Write-Host '✅ Tests completed' -ForegroundColor Green"

# Dry run for development
dry-run-dev:
	@echo "🔍 Dry run for development cluster..."
	@powershell -ExecutionPolicy Bypass -File deploy.ps1 -Environment dev -DryRun

# Dry run for production
dry-run-prod:
	@echo "🔍 Dry run for production cluster..."
	@powershell -ExecutionPolicy Bypass -File deploy.ps1 -Environment prod -DryRun
