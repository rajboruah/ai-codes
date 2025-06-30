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
    
    # Elastic IPs for NAT Gateways
    elasticIPs = [
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "Address"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-eip-${i}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "networking"
                    "eip-index": str(i)
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    domain = "vpc"
                    tags = spec.tags | {
                        "Name": "${spec.clusterName}-eip-${i}"
                    }
                }
            }
        } for i in range(len(spec.networking.subnetCidrs.privateSubnets))
    ]
    
    # NAT Gateways (one per private subnet for high availability)
    natGateways = [
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "NATGateway"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-nat-gateway-${i}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "networking"
                    "nat-gateway": "true"
                    "nat-index": str(i)
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    allocationIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "eip-index": str(i)
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "subnet-type": "public"
                        }
                    }
                    tags = spec.tags | {
                        "Name": "${spec.clusterName}-nat-gateway-${i}"
                    }
                }
            }
        } for i in range(len(spec.networking.subnetCidrs.privateSubnets))
    ]
    
    # Route Tables for Public Subnets
    publicRouteTable = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "RouteTable"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-public-rt"
            labels = {
                "cluster": spec.clusterName
                "component": "networking"
                "rt-type": "public"
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
                    "Name": "${spec.clusterName}-public-rt"
                }
            }
        }
    }
    
    # Public Route to Internet Gateway
    publicRoute = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "Route"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-public-route"
            labels = {
                "cluster": spec.clusterName
                "component": "networking"
                "route-type": "public"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                routeTableIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "networking"
                        "rt-type": "public"
                    }
                }
                destinationCidrBlock = "0.0.0.0/0"
                gatewayIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "networking"
                    }
                }
            }
        }
    }
    
    # Route Table Associations for Public Subnets
    publicRouteTableAssociations = [
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "RouteTableAssociation"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-public-rta-${i}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "networking"
                    "rta-type": "public"
                    "rta-index": str(i)
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    routeTableIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "rt-type": "public"
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "subnet-type": "public"
                        }
                    }
                }
            }
        } for i in range(len(spec.networking.subnetCidrs.publicSubnets))
    ]
    
    # Route Tables for Private Subnets (one per private subnet)
    privateRouteTables = [
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "RouteTable"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-private-rt-${i}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "networking"
                    "rt-type": "private"
                    "rt-index": str(i)
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
                        "Name": "${spec.clusterName}-private-rt-${i}"
                    }
                }
            }
        } for i in range(len(spec.networking.subnetCidrs.privateSubnets))
    ]
    
    # Private Routes to NAT Gateways
    privateRoutes = [
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "Route"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-private-route-${i}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "networking"
                    "route-type": "private"
                    "route-index": str(i)
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    routeTableIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "rt-type": "private"
                            "rt-index": str(i)
                        }
                    }
                    destinationCidrBlock = "0.0.0.0/0"
                    natGatewayIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "nat-gateway": "true"
                            "nat-index": str(i)
                        }
                    }
                }
            }
        } for i in range(len(spec.networking.subnetCidrs.privateSubnets))
    ]
    
    # Route Table Associations for Private Subnets
    privateRouteTableAssociations = [
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "RouteTableAssociation"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-private-rta-${i}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "networking"
                    "rta-type": "private"
                    "rta-index": str(i)
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    routeTableIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "rt-type": "private"
                            "rt-index": str(i)
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "subnet-type": "private"
                        }
                    }
                }
            }
        } for i in range(len(spec.networking.subnetCidrs.privateSubnets))
    ]
    
    [vpc, igw] + publicSubnets + privateSubnets + elasticIPs + natGateways + [publicRouteTable, publicRoute] + publicRouteTableAssociations + privateRouteTables + privateRoutes + privateRouteTableAssociations
}
