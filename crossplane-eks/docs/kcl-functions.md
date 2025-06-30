# KCL Functions Guide

This document explains the KCL (KusionStack Configuration Language) functions used in this Crossplane EKS configuration.

## Overview

KCL functions provide a powerful way to generate and compose Crossplane resources. Our EKS configuration is modularized into several specialized functions:

- **VPC Function**: Creates networking infrastructure
- **IAM Function**: Manages roles and policies  
- **Security Function**: Configures security groups
- **EKS Function**: Creates EKS cluster and node groups
- **Main Function**: Orchestrates all components

## Function Structure

### 1. VPC Function (`functions/vpc-function.k`)

**Purpose**: Creates VPC, subnets, and networking components

**Generated Resources**:
- VPC with DNS support enabled
- Internet Gateway
- Public subnets (for load balancers)
- Private subnets (for worker nodes)

**Key Features**:
- Automatic CIDR block allocation
- Multi-AZ subnet distribution
- Proper tagging for EKS integration

**Example Usage**:
```kcl
import "functions/vpc-function.k" as vpc

spec = {
    clusterName = "my-cluster"
    region = "us-west-2"
    networking = {
        vpcCidr = "10.0.0.0/16"
        subnetCidrs = {
            publicSubnets = ["10.0.1.0/24", "10.0.2.0/24"]
            privateSubnets = ["10.0.10.0/24", "10.0.20.0/24"]
        }
    }
}

resources = vpc.generateVPCResources(spec)
```

### 2. IAM Function (`functions/iam-function.k`)

**Purpose**: Creates IAM roles and policies for EKS

**Generated Resources**:
- EKS Cluster Service Role
- EKS Node Group Role  
- Policy attachments for both roles

**Key Features**:
- Follows AWS EKS security best practices
- Minimal required permissions
- Proper trust relationships

**Required Policies**:
- **Cluster Role**: `AmazonEKSClusterPolicy`
- **Node Group Role**: 
  - `AmazonEKSWorkerNodePolicy`
  - `AmazonEKS_CNI_Policy`
  - `AmazonEC2ContainerRegistryReadOnly`

### 3. Security Function (`functions/security-function.k`) 

**Purpose**: Creates security groups and rules

**Generated Resources**:
- Cluster security group
- Node group security group
- Security group rules for communication

**Security Rules**:
- Cluster ↔ Node group communication (all ports)
- Node group internal communication
- Follows AWS EKS networking requirements

### 4. EKS Function (`functions/eks-function.k`)

**Purpose**: Creates EKS cluster and associated resources

**Generated Resources**:
- EKS Cluster
- EKS Node Group
- EKS Addons (VPC CNI, CoreDNS, kube-proxy)

**Key Features**:
- Configurable Kubernetes version
- Multi-instance type support
- Auto-scaling configuration
- Essential addons included

### 5. Main Function (`functions/main-function.k`)

**Purpose**: Orchestrates all functions and provides utilities

**Key Functions**:
- `generateEKSCluster()`: Main orchestration function
- `createEKSClusterSpec()`: Configuration builder with defaults
- `validateEKSConfig()`: Configuration validation

## Configuration Schema

### EKSClusterSpec
```kcl
schema EKSClusterSpec:
    clusterName: str                    # Required: Cluster name
    region: str = "us-west-2"          # AWS region
    version: str = "1.31"              # Kubernetes version
    nodeGroupConfig: EKSNodeGroupConfig # Node group settings
    networking: EKSNetworkingConfig     # Network configuration
    tags?: {str: str}                   # Optional tags
```

### EKSNodeGroupConfig
```kcl
schema EKSNodeGroupConfig:
    instanceTypes: [str] = ["t3.medium"]  # EC2 instance types
    minSize: int = 1                      # Minimum nodes
    maxSize: int = 10                     # Maximum nodes  
    desiredSize: int = 3                  # Desired nodes
    diskSize: int = 20                    # EBS volume size (GB)
    capacityType: str = "ON_DEMAND"       # ON_DEMAND or SPOT
```

### EKSNetworkingConfig
```kcl
schema EKSNetworkingConfig:
    vpcCidr: str = "10.0.0.0/16"              # VPC CIDR block
    enablePrivateEndpoint: bool = True         # Private API endpoint
    enablePublicEndpoint: bool = True          # Public API endpoint
    subnetCidrs: EKSSubnetCidrs               # Subnet configuration
```

## Best Practices

### 1. Resource Naming
- Use consistent naming patterns
- Include cluster name in resource names
- Add descriptive labels for organization

### 2. Networking
- Use private subnets for worker nodes
- Enable both public and private endpoints for flexibility
- Plan CIDR blocks to avoid conflicts

### 3. Security
- Follow principle of least privilege
- Use security groups instead of NACLs
- Enable audit logging

### 4. Node Groups
- Use multiple instance types for availability
- Set appropriate scaling limits
- Consider using SPOT instances for cost optimization

## Advanced Configuration

### Custom VPC CIDR
```kcl
networking = {
    vpcCidr = "172.16.0.0/16"
    subnetCidrs = {
        publicSubnets = ["172.16.1.0/24", "172.16.2.0/24"]
        privateSubnets = ["172.16.10.0/24", "172.16.20.0/24"]
    }
}
```

### Multiple Node Groups
To create multiple node groups, modify the EKS function or create additional node group resources:

```kcl
# Additional node group for GPU workloads
gpuNodeGroup = {
    instanceTypes = ["p3.2xlarge"]
    minSize = 0
    maxSize = 5
    desiredSize = 0
}
```

### Custom Tags
```kcl
tags = {
    "Environment": "production"
    "Team": "platform-engineering"
    "Project": "microservices"
    "CostCenter": "engineering"
    "Backup": "required"
}
```

## Debugging KCL Functions

### Validate Syntax
```bash
kcl run functions/ --dry-run
```

### Test Individual Functions
```bash
kcl run functions/vpc-function.k --dry-run
```

### Debug Output
Add print statements in KCL functions:
```kcl
print("Debug: VPC CIDR = ${spec.networking.vpcCidr}")
```

## Integration with Crossplane

The KCL functions integrate with Crossplane through pipeline steps:

```yaml
spec:
  mode: Pipeline
  pipeline:
  - step: generate-vpc-resources
    functionRef:
      name: function-kcl
    input:
      apiVersion: krm.kcl.dev/v1alpha1
      kind: KCLInput
      spec:
        source: |
          import "functions/vpc-function.k" as vpc
          spec = option("params").oxr.spec.parameters
          items = vpc.generateVPCResources(spec)
```

This approach provides:
- **Modularity**: Each function handles specific resources
- **Reusability**: Functions can be shared across compositions
- **Maintainability**: Easy to update and test individual components
- **Flexibility**: Easy to customize for different requirements
