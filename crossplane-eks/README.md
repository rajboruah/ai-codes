# Crossplane EKS Private Cluster Configuration

This project contains Crossplane scripts written in KCL (KusionStack Configuration Language) to create and manage private Amazon EKS clusters.

## Architecture

This configuration creates a **private-only EKS cluster** with the following characteristics:

- **Private API Server Endpoint**: The EKS API server is only accessible from within the VPC
- **Private Node Groups**: Worker nodes are deployed in private subnets only
- **NAT Gateway**: Provides outbound internet access for private subnets
- **No Public Endpoint**: The cluster cannot be accessed directly from the internet

## Structure

- `compositions/` - Crossplane Composition definitions
- `composite-resource-definitions/` - XRD (Composite Resource Definition) files
- `functions/` - KCL pipeline functions
- `examples/` - Example usage and test configurations
- `schemas/` - KCL schema definitions

## Prerequisites

1. Kubernetes cluster with Crossplane installed
2. AWS Provider for Crossplane configured
3. KCL runtime and tools installed
4. Bastion host or VPN connection to access the private EKS cluster

## Quick Start

1. Apply the Composite Resource Definitions:
   ```bash
   kubectl apply -f composite-resource-definitions/
   ```

2. Apply the Compositions:
   ```bash
   kubectl apply -f compositions/
   ```

3. Create an EKS cluster using the example:
   ```bash
   kubectl apply -f examples/dev-eks-cluster.yaml
   ```

## Features

- **Private EKS cluster** with no public API endpoint
- **Bastion host** for secure access to the private cluster
- Complete VPC and networking setup with NAT Gateway
- Private subnets for worker nodes
- Public subnets for NAT Gateway and load balancers
- Security groups and IAM roles
- Configurable cluster parameters
- KCL-based composition functions for flexible configuration

## Network Architecture

The cluster creates the following networking components:

- **VPC** with configurable CIDR block
- **Public Subnets** for NAT Gateways and load balancers
- **Private Subnets** for EKS worker nodes
- **Internet Gateway** for public subnet internet access
- **NAT Gateways** for private subnet outbound internet access
- **Route Tables** with appropriate routing rules

## Accessing the Private Cluster

The configuration automatically creates a bastion host that provides secure access to your private EKS cluster:

### 🖥️ **Bastion Host Features**
- Deployed in public subnet with controlled access
- Pre-installed with kubectl, aws-cli, and helm
- Auto-configured kubeconfig for your cluster
- Support for SSH and AWS Systems Manager access

### 🔑 **Access Methods**
1. **SSH Access**: Use your SSH key pair for traditional access
2. **AWS Systems Manager**: Keyless browser-based access
3. **Session Manager**: Secure terminal access via AWS CLI

### 📋 **Quick Access Steps**
```bash
# Option 1: SSH Access (if SSH key configured)
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>

# Option 2: AWS Systems Manager
aws ssm start-session --target <bastion-instance-id>

# Once connected to bastion:
./update-kubeconfig.sh  # Configure kubectl
kubectl get nodes       # Test cluster access
```

For detailed bastion host configuration and usage, see the [Bastion Host Guide](docs/bastion-host-guide.md).
