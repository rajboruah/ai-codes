# EKS Private Cluster Configuration - Changes Summary

## Overview
This document summarizes the changes made to convert the EKS cluster configuration from a mixed public/private setup to a **private-only** configuration with **bastion host support**.

## Latest Changes (Bastion Host Addition)

### 1. Bastion Host Function (`functions/bastion-function.k`)

**New Function Added:**
- Complete bastion host configuration with security groups, IAM roles, and EC2 instance
- Pre-installed tools: kubectl, aws-cli, helm
- Auto-configured kubeconfig for EKS cluster access
- Support for both SSH and AWS Systems Manager access
- Configurable instance type, AMI, and security settings

### 2. Schema Updates (`schemas/eks-schemas.k`)

**Added Bastion Configuration Schema:**
```kcl
schema EKSBastionConfig:
    enabled: bool = True
    instanceType: str = "t3.micro"
    ami?: str
    publicKey?: str
    allowedCidrs?: [str] = ["0.0.0.0/0"]
```

**Updated Main Schema:**
```kcl
schema EKSClusterSpec:
    # ...existing fields...
    bastionConfig?: EKSBastionConfig
    # ...
```

### 3. Composition Updates (`compositions/eks-composition.yaml`)

**Added Bastion Generation Step:**
```yaml
- step: generate-bastion-resources
  functionRef:
    name: function-kcl
  input:
    # Generate bastion resources if enabled
```

### 4. Example Configurations

**Updated Files:**
- `examples/dev-eks-cluster.yaml` - Added bastion configuration
- `examples/prod-eks-cluster.yaml` - Added production bastion config
- `examples/test-eks-with-bastion.yaml` - New test configuration

### 5. Documentation

**New Documentation:**
- `docs/bastion-host-guide.md` - Comprehensive bastion host guide
- Updated `README.md` with bastion host information

## Bastion Host Features

### 🔒 **Security Features**
- Dedicated security group with restricted SSH access
- IAM role with minimal required permissions
- Integration with AWS Systems Manager for keyless access
- Support for IP range restrictions

### 🛠️ **Pre-installed Tools**
- **kubectl**: Kubernetes CLI with auto-configured kubeconfig
- **aws-cli**: AWS Command Line Interface
- **helm**: Kubernetes package manager
- **Session Manager**: AWS Systems Manager integration

### 🔑 **Access Methods**
1. **SSH Access**: Traditional SSH with key pair authentication
2. **AWS Systems Manager**: Browser-based access via AWS Console
3. **Session Manager**: CLI-based keyless access

### 💰 **Cost Impact**
- Development: ~$8-10/month (t3.micro)
- Production: ~$15-20/month (t3.small)
- Optional: Can be scheduled to stop/start to reduce costs

## Resources Created by Bastion Configuration

### IAM Resources
- **Role**: `${cluster-name}-bastion-role`
- **Policy**: `${cluster-name}-bastion-policy` (EKS access)
- **Policy Attachment**: SSM managed policy attachment
- **Instance Profile**: `${cluster-name}-bastion-profile`

### EC2 Resources
- **Security Group**: `${cluster-name}-bastion-sg`
- **Security Group Rules**: SSH inbound, all outbound, EKS cluster access
- **Key Pair**: `${cluster-name}-bastion-key` (if public key provided)
- **EC2 Instance**: `${cluster-name}-bastion`

### Network Integration
- **Subnet Placement**: Deployed in public subnet
- **Security Group Rule**: Allows bastion to access EKS cluster on port 443
- **Public IP**: Auto-assigned for internet access

## Configuration Examples

### Basic Configuration
```yaml
bastionConfig:
  enabled: true
  instanceType: "t3.micro"
  allowedCidrs: ["0.0.0.0/0"]
```

### Production Configuration
```yaml
bastionConfig:
  enabled: true
  instanceType: "t3.small"
  allowedCidrs: ["10.0.0.0/8", "172.16.0.0/12"]
  publicKey: "ssh-rsa AAAAB3NzaC1yc2E..."
```

### Secure Configuration
```yaml
bastionConfig:
  enabled: true
  instanceType: "t3.micro"
  allowedCidrs: ["203.0.113.0/24"]  # Your office IP range
  publicKey: "ssh-rsa AAAAB3NzaC1yc2E..."
```

## Architecture Impact

### Complete Architecture
```
Internet → IGW → Public Subnets → NAT Gateway + Bastion Host
                              → Private Subnets → EKS Nodes
                                              → EKS API (Private Only)
```

### Access Flow
```
User → Bastion Host → EKS Cluster → Kubernetes Resources
     ↓
   SSH/SSM → kubectl → Private API Server
```

## Usage Instructions

### 1. Deploy with Bastion
```bash
kubectl apply -f examples/test-eks-with-bastion.yaml
```

### 2. Access Bastion Host
```bash
# Option 1: SSH (if key configured)
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-ip>

# Option 2: Systems Manager
aws ssm start-session --target <bastion-instance-id>
```

### 3. Access EKS Cluster
```bash
# On bastion host
./update-kubeconfig.sh
kubectl get nodes
kubectl cluster-info
```

## Previous Changes (Private Cluster Configuration)

### 1. EKS Cluster Configuration (`functions/eks-function.k`)

**Before:**
```kcl
resourcesVpcConfig = {
    endpointConfigPrivate = spec.networking.enablePrivateEndpoint
    endpointConfigPublic = spec.networking.enablePublicEndpoint
    subnetIdSelectors = [
        {
            matchLabels = {
                "subnet-type": "public"
            }
        },
        {
            matchLabels = {
                "subnet-type": "private"
            }
        }
    ]
}
```

**After:**
```kcl
resourcesVpcConfig = {
    endpointConfigPrivate = True
    endpointConfigPublic = False
    subnetIdSelectors = [
        {
            matchLabels = {
                "subnet-type": "private"
            }
        }
    ]
}
```

**Impact:** EKS cluster now only uses private subnets and has no public API endpoint.

### 2. VPC Function Enhancement (`functions/vpc-function.k`)

**Added Components:**
- **Elastic IP addresses** for NAT Gateways
- **NAT Gateways** (one per private subnet for HA)
- **Public Route Table** with route to Internet Gateway
- **Private Route Tables** (one per private subnet)
- **Private Routes** to NAT Gateways
- **Route Table Associations** for both public and private subnets

**Network Flow:**
```
Internet → IGW → Public Subnets → NAT Gateway → Private Subnets → EKS Nodes
```

### 3. Schema Updates (`schemas/eks-schemas.k`)

**Before:**
```kcl
enablePrivateEndpoint: bool = True
enablePublicEndpoint: bool = True
```

**After:**
```kcl
enablePrivateEndpoint: bool = True
enablePublicEndpoint: bool = False  # Forced to false for private-only cluster
```

### 4. Example Configurations

**Updated Files:**
- `examples/dev-eks-cluster.yaml`
- `examples/prod-eks-cluster.yaml`

**Changes:**
- Set `enablePublicEndpoint: false`
- Added comments explaining subnet usage
- Maintained public subnets for NAT Gateway placement

### 5. Documentation Updates

**Updated Files:**
- `README.md` - Updated to reflect private cluster architecture
- `docs/private-cluster-configuration.md` - New comprehensive guide

## Migration Considerations

When deploying this enhanced configuration:

1. **Plan Access**: Bastion host provides immediate access to private cluster
2. **CI/CD Updates**: Update build pipelines to use bastion or VPN
3. **Security**: Configure appropriate CIDR blocks for bastion access
4. **Cost Management**: Consider scheduling bastion host for cost optimization
5. **Monitoring**: Set up CloudWatch alarms for bastion host access

## Rollback

To disable bastion host:
```yaml
bastionConfig:
  enabled: false
```

To rollback to public cluster:
1. Revert EKS function subnet selectors
2. Set `endpointConfigPublic = True`
3. Update schema defaults
4. Remove NAT Gateway resources if desired

This enhanced configuration now provides a complete, secure, production-ready EKS setup with easy access management through the integrated bastion host.

### 1. EKS Cluster Configuration (`functions/eks-function.k`)

**Before:**
```kcl
resourcesVpcConfig = {
    endpointConfigPrivate = spec.networking.enablePrivateEndpoint
    endpointConfigPublic = spec.networking.enablePublicEndpoint
    subnetIdSelectors = [
        {
            matchLabels = {
                "subnet-type": "public"
            }
        },
        {
            matchLabels = {
                "subnet-type": "private"
            }
        }
    ]
}
```

**After:**
```kcl
resourcesVpcConfig = {
    endpointConfigPrivate = True
    endpointConfigPublic = False
    subnetIdSelectors = [
        {
            matchLabels = {
                "subnet-type": "private"
            }
        }
    ]
}
```

**Impact:** EKS cluster now only uses private subnets and has no public API endpoint.

### 2. VPC Function Enhancement (`functions/vpc-function.k`)

**Added Components:**
- **Elastic IP addresses** for NAT Gateways
- **NAT Gateways** (one per private subnet for HA)
- **Public Route Table** with route to Internet Gateway
- **Private Route Tables** (one per private subnet)
- **Private Routes** to NAT Gateways
- **Route Table Associations** for both public and private subnets

**Network Flow:**
```
Internet → IGW → Public Subnets → NAT Gateway → Private Subnets → EKS Nodes
```

### 3. Schema Updates (`schemas/eks-schemas.k`)

**Before:**
```kcl
enablePrivateEndpoint: bool = True
enablePublicEndpoint: bool = True
```

**After:**
```kcl
enablePrivateEndpoint: bool = True
enablePublicEndpoint: bool = False  # Forced to false for private-only cluster
```

### 4. Example Configurations

**Updated Files:**
- `examples/dev-eks-cluster.yaml`
- `examples/prod-eks-cluster.yaml`

**Changes:**
- Set `enablePublicEndpoint: false`
- Added comments explaining subnet usage
- Maintained public subnets for NAT Gateway placement

### 5. Documentation Updates

**Updated Files:**
- `README.md` - Updated to reflect private cluster architecture
- `docs/private-cluster-configuration.md` - New comprehensive guide

## Architecture Impact

### Before (Mixed Public/Private)
```
Internet → IGW → Public Subnets → EKS API (Public + Private)
                              → Private Subnets → EKS Nodes
```

### After (Private Only)
```
Internet → IGW → Public Subnets → NAT Gateway
                              → Private Subnets → EKS Nodes
                                              → EKS API (Private Only)
```

## Security Improvements

1. **No Direct Internet Access**: EKS API server cannot be accessed from the internet
2. **Controlled Access**: Requires VPN, bastion host, or AWS connectivity
3. **Maintained Functionality**: Applications can still use load balancers in public subnets
4. **Outbound Connectivity**: Nodes maintain internet access for updates and image pulls

## Access Methods

Users now need one of the following to access the cluster:

1. **Bastion Host**: EC2 instance in public subnet
2. **VPN Connection**: AWS Client VPN or Site-to-Site VPN
3. **AWS CloudShell**: Browser-based terminal from AWS Console
4. **Direct Connect**: Enterprise connectivity option

## Resource Changes

### New Resources Added:
- `Address` (Elastic IP) - One per NAT Gateway
- `NATGateway` - One per private subnet
- `RouteTable` - One public + one per private subnet
- `Route` - Routes for internet access
- `RouteTableAssociation` - Associates subnets with route tables

### Resources Modified:
- `Cluster` - Changed endpoint configuration and subnet selection
- Examples - Updated networking configuration

### Resources Unchanged:
- VPC, Subnets, Internet Gateway, Security Groups, IAM roles, Node Groups

## Migration Considerations

When deploying this configuration:

1. **Plan Access**: Set up access method before deployment
2. **CI/CD Updates**: Update build pipelines to access private cluster
3. **Load Balancers**: Verify applications can still expose services
4. **Cost Impact**: NAT Gateways add ~$45/month per gateway
5. **High Availability**: NAT Gateways provide redundancy across AZs

## Testing

To verify the private cluster works correctly:

1. **Deploy the cluster**: `kubectl apply -f examples/dev-eks-cluster.yaml`
2. **Check endpoint**: Verify API server is private-only
3. **Test connectivity**: Ensure nodes can pull images
4. **Deploy application**: Test load balancer functionality
5. **Access cluster**: Verify access methods work

## Rollback

To rollback to public cluster:

1. Revert EKS function subnet selectors
2. Set `endpointConfigPublic = True`
3. Update schema defaults
4. Remove NAT Gateway resources if desired (though they can remain for security)

This configuration provides a more secure, production-ready EKS setup suitable for enterprise environments where security is paramount.
