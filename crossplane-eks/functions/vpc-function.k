import "schemas/eks-schemas.k" as schemas

# KCL function to generate VPC resources for EKS cluster
generateVPCResources = lambda spec: schemas.EKSClusterSpec {
    """Generate VPC and networking resources for EKS cluster"""
    
    vpc = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "VPC"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-vpc"
            labels = {
                "cluster": spec.clusterName
                "component": "networking"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                cidrBlock = spec.networking.vpcCidr
                enableDnsHostnames = True
                enableDnsSupport = True
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-vpc"
                    "kubernetes.io/cluster/${spec.clusterName}": "shared"
                }
            }
        }
    }
    
    # Internet Gateway
    igw = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "InternetGateway"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-igw"
            labels = {
                "cluster": spec.clusterName
                "component": "networking"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                vpcIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "networking"
                    }
                }
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-igw"
                }
            }
        }
    }
    
    # Public Subnets
    publicSubnets = [
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "Subnet"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-public-subnet-${i}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "networking"
                    "subnet-type": "public"
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    availabilityZone = "${spec.region}${chr(ord('a') + i)}"
                    cidrBlock = cidr
                    mapPublicIpOnLaunch = True
                    vpcIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                        }
                    }
                    tags = spec.tags | {
                        "Name": "${spec.clusterName}-public-subnet-${i}"
                        "kubernetes.io/cluster/${spec.clusterName}": "shared"
                        "kubernetes.io/role/elb": "1"
                    }
                }
            }
        } for i, cidr in enumerate(spec.networking.subnetCidrs.publicSubnets)
    ]
    
    # Private Subnets
    privateSubnets = [
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "Subnet"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-private-subnet-${i}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "networking"
                    "subnet-type": "private"
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    availabilityZone = "${spec.region}${chr(ord('a') + i)}"
                    cidrBlock = cidr
                    vpcIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                        }
                    }
                    tags = spec.tags | {
                        "Name": "${spec.clusterName}-private-subnet-${i}"
                        "kubernetes.io/cluster/${spec.clusterName}": "shared"
                        "kubernetes.io/role/internal-elb": "1"
                    }
                }
            }
        } for i, cidr in enumerate(spec.networking.subnetCidrs.privateSubnets)
    ]
    
    [vpc, igw] + publicSubnets + privateSubnets
}
