import "schemas/eks-schemas.k" as schemas

# KCL function to generate security groups for EKS cluster
generateSecurityGroups = lambda spec: schemas.EKSClusterSpec {
    """Generate security groups for EKS cluster and node groups"""
    
    # EKS Cluster Security Group
    clusterSecurityGroup = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "SecurityGroup"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-cluster-sg"
            labels = {
                "cluster": spec.clusterName
                "component": "security"
                "sg-type": "cluster"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                description = "Security group for EKS cluster ${spec.clusterName}"
                groupName = "${spec.clusterName}-cluster-sg"
                vpcIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "networking"
                    }
                }
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-cluster-sg"
                }
            }
        }
    }
    
    # Node Group Security Group
    nodeGroupSecurityGroup = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "SecurityGroup"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-nodegroup-sg"
            labels = {
                "cluster": spec.clusterName
                "component": "security"
                "sg-type": "nodegroup"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                description = "Security group for EKS node group ${spec.clusterName}"
                groupName = "${spec.clusterName}-nodegroup-sg"
                vpcIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "networking"
                    }
                }
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-nodegroup-sg"
                }
            }
        }
    }
    
    # Security Group Rules
    securityGroupRules = [
        # Cluster to node group communication
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "SecurityGroupRule"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-cluster-to-nodegroup"
                labels = {
                    "cluster": spec.clusterName
                    "component": "security"
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    type = "egress"
                    fromPort = 0
                    toPort = 65535
                    protocol = "tcp"
                    sourceSecurityGroupIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "security"
                            "sg-type": "nodegroup"
                        }
                    }
                    securityGroupIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "security"
                            "sg-type": "cluster"
                        }
                    }
                }
            }
        },
        # Node group to cluster communication
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "SecurityGroupRule"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-nodegroup-to-cluster"
                labels = {
                    "cluster": spec.clusterName
                    "component": "security"
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    type = "ingress"
                    fromPort = 0
                    toPort = 65535
                    protocol = "tcp"
                    sourceSecurityGroupIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "security"
                            "sg-type": "cluster"
                        }
                    }
                    securityGroupIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "security"
                            "sg-type": "nodegroup"
                        }
                    }
                }
            }
        },
        # Node group internal communication
        schemas.AWSResource {
            apiVersion = "ec2.aws.crossplane.io/v1beta1"
            kind = "SecurityGroupRule"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-nodegroup-internal"
                labels = {
                    "cluster": spec.clusterName
                    "component": "security"
                }
            }
            spec = {
                forProvider = {
                    region = spec.region
                    type = "ingress"
                    fromPort = 0
                    toPort = 65535
                    protocol = "tcp"
                    sourceSecurityGroupIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "security"
                            "sg-type": "nodegroup"
                        }
                    }
                    securityGroupIdSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "security"
                            "sg-type": "nodegroup"
                        }
                    }
                }
            }
        }
    ]
    
    [clusterSecurityGroup, nodeGroupSecurityGroup] + securityGroupRules
}
