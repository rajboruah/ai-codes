import "schemas/eks-schemas.k" as schemas

# KCL function to generate IAM roles and policies for EKS cluster
generateIAMResources = lambda spec: schemas.EKSClusterSpec {
    """Generate IAM roles and policies for EKS cluster and node groups"""
    
    # EKS Cluster Service Role
    clusterRole = schemas.AWSResource {
        apiVersion = "iam.aws.crossplane.io/v1beta1"
        kind = "Role"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-cluster-role"
            labels = {
                "cluster": spec.clusterName
                "component": "iam"
                "role-type": "cluster"
            }
        }
        spec = {
            forProvider = {
                assumeRolePolicyDocument = """{
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {
                                "Service": "eks.amazonaws.com"
                            },
                            "Action": "sts:AssumeRole"
                        }
                    ]
                }"""
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-cluster-role"
                }
            }
        }
    }
    
    # EKS Cluster Policy Attachment
    clusterPolicyAttachment = schemas.AWSResource {
        apiVersion = "iam.aws.crossplane.io/v1beta1"
        kind = "RolePolicyAttachment"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-cluster-policy"
            labels = {
                "cluster": spec.clusterName
                "component": "iam"
            }
        }
        spec = {
            forProvider = {
                policyArn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
                roleSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "iam"
                        "role-type": "cluster"
                    }
                }
            }
        }
    }
    
    # EKS Node Group Role
    nodeGroupRole = schemas.AWSResource {
        apiVersion = "iam.aws.crossplane.io/v1beta1"
        kind = "Role"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-nodegroup-role"
            labels = {
                "cluster": spec.clusterName
                "component": "iam"
                "role-type": "nodegroup"
            }
        }
        spec = {
            forProvider = {
                assumeRolePolicyDocument = """{
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {
                                "Service": "ec2.amazonaws.com"
                            },
                            "Action": "sts:AssumeRole"
                        }
                    ]
                }"""
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-nodegroup-role"
                }
            }
        }
    }
    
    # Node Group Policy Attachments
    nodeGroupPolicies = [
        schemas.AWSResource {
            apiVersion = "iam.aws.crossplane.io/v1beta1"
            kind = "RolePolicyAttachment"
            metadata = schemas.ResourceMetadata {
                name = "${spec.clusterName}-nodegroup-${policy.split(':')[-1]}"
                labels = {
                    "cluster": spec.clusterName
                    "component": "iam"
                }
            }
            spec = {
                forProvider = {
                    policyArn = policy
                    roleSelector = {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "iam"
                            "role-type": "nodegroup"
                        }
                    }
                }
            }
        } for policy in [
            "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
            "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
            "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        ]
    ]
    
    [clusterRole, clusterPolicyAttachment, nodeGroupRole] + nodeGroupPolicies
}
