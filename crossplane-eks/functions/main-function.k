import "schemas/eks-schemas.k" as schemas
import "functions/vpc-function.k" as vpc
import "functions/iam-function.k" as iam
import "functions/security-function.k" as security
import "functions/eks-function.k" as eks

# Main KCL function to generate complete EKS cluster configuration
generateEKSCluster = lambda spec: schemas.EKSClusterSpec {
    """
    Main function to generate complete EKS cluster with all required resources:
    - VPC and networking components
    - IAM roles and policies
    - Security groups
    - EKS cluster and node groups
    - EKS addons
    """
    
    # Generate all resource components
    vpcResources = vpc.generateVPCResources(spec)
    iamResources = iam.generateIAMResources(spec)
    securityResources = security.generateSecurityGroups(spec)
    eksResources = eks.generateEKSResources(spec)
    
    # Combine all resources
    allResources = vpcResources + iamResources + securityResources + eksResources
    
    allResources
}

# Helper function to create a complete EKS cluster specification
createEKSClusterSpec = lambda config: {
    """Create EKS cluster specification from configuration"""
    
    # Default configuration
    defaultConfig = schemas.EKSClusterSpec {
        clusterName = "my-eks-cluster"
        region = "us-west-2"
        version = "1.31"
        nodeGroupConfig = schemas.EKSNodeGroupConfig {
            instanceTypes = ["t3.medium"]
            minSize = 1
            maxSize = 10
            desiredSize = 3
            diskSize = 20
            capacityType = "ON_DEMAND"
        }
        networking = schemas.EKSNetworkingConfig {
            vpcCidr = "10.0.0.0/16"
            enablePrivateEndpoint = True
            enablePublicEndpoint = True
            subnetCidrs = schemas.EKSSubnetCidrs {
                publicSubnets = ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets = ["10.0.10.0/24", "10.0.20.0/24"]
            }
        }
        tags = {
            "Environment": "dev"
            "Team": "platform"
            "ManagedBy": "crossplane"
        }
    }
    
    # Merge with provided configuration
    spec = defaultConfig | config
    
    spec
}

# Function to validate EKS cluster configuration
validateEKSConfig = lambda spec: schemas.EKSClusterSpec {
    """Validate EKS cluster configuration"""
    
    # Validation rules
    assert spec.clusterName, "Cluster name is required"
    assert spec.region, "AWS region is required"
    assert spec.nodeGroupConfig.minSize >= 1, "Node group minimum size must be at least 1"
    assert spec.nodeGroupConfig.maxSize >= spec.nodeGroupConfig.minSize, "Node group maximum size must be >= minimum size"
    assert spec.nodeGroupConfig.desiredSize >= spec.nodeGroupConfig.minSize and spec.nodeGroupConfig.desiredSize <= spec.nodeGroupConfig.maxSize, "Node group desired size must be between min and max"
    
    True
}
