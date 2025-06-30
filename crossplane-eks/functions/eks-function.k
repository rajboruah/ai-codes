import "schemas/eks-schemas.k" as schemas

# KCL function to generate EKS cluster and node group resources
generateEKSResources = lambda spec: schemas.EKSClusterSpec {
    """Generate EKS cluster and node group resources"""
    
    # EKS Cluster
    eksCluster = schemas.AWSResource {
        apiVersion = "eks.aws.crossplane.io/v1beta1"
        kind = "Cluster"
        metadata = schemas.ResourceMetadata {
            name = spec.clusterName
            labels = {
                "cluster": spec.clusterName
                "component": "eks"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                name = spec.clusterName
                version = spec.version
                roleArnSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "iam"
                        "role-type": "cluster"
                    }
                }
                resourcesVpcConfig = {
                    endpointConfigPrivate = True
                    endpointConfigPublic = False
                    subnetIdSelectors = [
                        {
                            matchLabels = {
                                "cluster": spec.clusterName
                                "component": "networking"
                                "subnet-type": "private"
                            }
                        }
                    ]
                    securityGroupIdSelectors = [
                        {
                            matchLabels = {
                                "cluster": spec.clusterName
                                "component": "security"
                                "sg-type": "cluster"
                            }
                        }
                    ]
                }
                tags = spec.tags | {
                    "Name": spec.clusterName
                }
            }
        }
    }
    
    # EKS Node Group
    eksNodeGroup = schemas.AWSResource {
        apiVersion = "eks.aws.crossplane.io/v1alpha1"
        kind = "NodeGroup"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-nodegroup"
            labels = {
                "cluster": spec.clusterName
                "component": "eks"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                clusterNameSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "eks"
                    }
                }
                nodeGroupName = "${spec.clusterName}-nodegroup"
                nodeRoleSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "iam"
                        "role-type": "nodegroup"
                    }
                }
                subnetIdSelectors = [
                    {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "networking"
                            "subnet-type": "private"
                        }
                    }
                ]
                instanceTypes = spec.nodeGroupConfig.instanceTypes
                capacityType = spec.nodeGroupConfig.capacityType
                scalingConfig = {
                    desiredSize = spec.nodeGroupConfig.desiredSize
                    maxSize = spec.nodeGroupConfig.maxSize
                    minSize = spec.nodeGroupConfig.minSize
                }
                diskSize = spec.nodeGroupConfig.diskSize
                amiType = "AL2_x86_64"
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-nodegroup"
                }
            }
        }
    }
    
    # EKS Addon - VPC CNI
    vpcCniAddon = schemas.AWSResource {
        apiVersion = "eks.aws.crossplane.io/v1alpha1"
        kind = "Addon"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-vpc-cni"
            labels = {
                "cluster": spec.clusterName
                "component": "eks"
                "addon": "vpc-cni"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                clusterNameSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "eks"
                    }
                }
                addonName = "vpc-cni"
                resolveConflicts = "OVERWRITE"
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-vpc-cni"
                }
            }
        }
    }
    
    # EKS Addon - CoreDNS
    coreDnsAddon = schemas.AWSResource {
        apiVersion = "eks.aws.crossplane.io/v1alpha1"
        kind = "Addon"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-coredns"
            labels = {
                "cluster": spec.clusterName
                "component": "eks"
                "addon": "coredns"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                clusterNameSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "eks"
                    }
                }
                addonName = "coredns"
                resolveConflicts = "OVERWRITE"
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-coredns"
                }
            }
        }
    }
    
    # EKS Addon - kube-proxy
    kubeProxyAddon = schemas.AWSResource {
        apiVersion = "eks.aws.crossplane.io/v1alpha1"
        kind = "Addon"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-kube-proxy"
            labels = {
                "cluster": spec.clusterName
                "component": "eks"
                "addon": "kube-proxy"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                clusterNameSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "eks"
                    }
                }
                addonName = "kube-proxy"
                resolveConflicts = "OVERWRITE"
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-kube-proxy"
                }
            }
        }
    }
    
    [eksCluster, eksNodeGroup, vpcCniAddon, coreDnsAddon, kubeProxyAddon]
}
