import "schemas/eks-schemas.k" as schemas

# KCL function to generate bastion host resources
generateBastionResources = lambda spec: schemas.EKSClusterSpec {
    """Generate bastion host resources for accessing private EKS cluster"""
    
    # Bastion Security Group
    bastionSecurityGroup = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "SecurityGroup"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-sg"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "sg-type": "bastion"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                name = "${spec.clusterName}-bastion-sg"
                description = "Security group for bastion host"
                vpcIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "networking"
                    }
                }
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-bastion-sg"
                    "Purpose": "bastion-host"
                }
            }
        }
    }
    
    # Bastion Security Group Rule - SSH Inbound
    bastionSshRule = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "SecurityGroupRule"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-ssh-rule"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "rule-type": "ssh-inbound"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                type = "ingress"
                fromPort = 22
                toPort = 22
                protocol = "tcp"
                cidrBlocks = spec.bastionConfig?.allowedCidrs or ["0.0.0.0/0"]  # Restrict as needed
                securityGroupIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "bastion"
                        "sg-type": "bastion"
                    }
                }
            }
        }
    }
    
    # Bastion Security Group Rule - All Outbound
    bastionOutboundRule = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "SecurityGroupRule"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-outbound-rule"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "rule-type": "all-outbound"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                type = "egress"
                fromPort = 0
                toPort = 65535
                protocol = "-1"
                cidrBlocks = ["0.0.0.0/0"]
                securityGroupIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "bastion"
                        "sg-type": "bastion"
                    }
                }
            }
        }
    }
    
    # Bastion IAM Role
    bastionRole = schemas.AWSResource {
        apiVersion = "iam.aws.crossplane.io/v1beta1"
        kind = "Role"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-role"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "role-type": "bastion"
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
                    "Name": "${spec.clusterName}-bastion-role"
                }
            }
        }
    }
    
    # Bastion IAM Policy for EKS Access
    bastionPolicy = schemas.AWSResource {
        apiVersion = "iam.aws.crossplane.io/v1beta1"
        kind = "Policy"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-policy"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "policy-type": "bastion"
            }
        }
        spec = {
            forProvider = {
                name = "${spec.clusterName}-bastion-policy"
                description = "Policy for bastion host to access EKS cluster"
                policyDocument = """{
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Action": [
                                "eks:DescribeCluster",
                                "eks:ListClusters",
                                "eks:AccessKubernetesApi"
                            ],
                            "Resource": "*"
                        },
                        {
                            "Effect": "Allow",
                            "Action": [
                                "ssm:*",
                                "ssmmessages:*",
                                "ec2messages:*"
                            ],
                            "Resource": "*"
                        }
                    ]
                }"""
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-bastion-policy"
                }
            }
        }
    }
    
    # Attach SSM Managed Policy to Bastion Role
    bastionSSMPolicyAttachment = schemas.AWSResource {
        apiVersion = "iam.aws.crossplane.io/v1beta1"
        kind = "RolePolicyAttachment"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-ssm-policy"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "attachment-type": "ssm"
            }
        }
        spec = {
            forProvider = {
                policyArn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
                roleSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "bastion"
                        "role-type": "bastion"
                    }
                }
            }
        }
    }
    
    # Attach Custom Policy to Bastion Role
    bastionPolicyAttachment = schemas.AWSResource {
        apiVersion = "iam.aws.crossplane.io/v1beta1"
        kind = "RolePolicyAttachment"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-custom-policy"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "attachment-type": "custom"
            }
        }
        spec = {
            forProvider = {
                policyArnSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "bastion"
                        "policy-type": "bastion"
                    }
                }
                roleSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "bastion"
                        "role-type": "bastion"
                    }
                }
            }
        }
    }
    
    # Instance Profile for Bastion
    bastionInstanceProfile = schemas.AWSResource {
        apiVersion = "iam.aws.crossplane.io/v1beta1"
        kind = "InstanceProfile"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-profile"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "profile-type": "bastion"
            }
        }
        spec = {
            forProvider = {
                name = "${spec.clusterName}-bastion-profile"
                roleSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "bastion"
                        "role-type": "bastion"
                    }
                }
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-bastion-profile"
                }
            }
        }
    }
    
    # Key Pair for Bastion (if specified)
    bastionKeyPair = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "KeyPair"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-key"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "key-type": "bastion"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                keyName = "${spec.clusterName}-bastion-key"
                publicKey = spec.bastionConfig?.publicKey or ""
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-bastion-key"
                }
            }
        }
    }
    
    # Bastion EC2 Instance
    bastionInstance = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "Instance"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion"
            labels = {
                "cluster": spec.clusterName
                "component": "bastion"
                "instance-type": "bastion"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                instanceType = spec.bastionConfig?.instanceType or "t3.micro"
                ami = spec.bastionConfig?.ami or "ami-0c02fb55956c7d316"  # Amazon Linux 2 AMI (update as needed)
                **({keyName = "${spec.clusterName}-bastion-key"} if spec.bastionConfig?.publicKey else {})
                subnetIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "networking"
                        "subnet-type": "public"
                    }
                }
                vpcSecurityGroupIdSelectors = [
                    {
                        matchLabels = {
                            "cluster": spec.clusterName
                            "component": "bastion"
                            "sg-type": "bastion"
                        }
                    }
                ]
                iamInstanceProfileSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "bastion"
                        "profile-type": "bastion"
                    }
                }
                associatePublicIpAddress = True
                userData = """#!/bin/bash
yum update -y
yum install -y aws-cli

# Install kubectl
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.31.0/2024-09-12/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Configure AWS CLI to use instance role
echo 'export AWS_DEFAULT_REGION=${spec.region}' >> /home/ec2-user/.bashrc

# Update kubeconfig for EKS cluster
echo '#!/bin/bash' > /home/ec2-user/update-kubeconfig.sh
echo 'aws eks update-kubeconfig --region ${spec.region} --name ${spec.clusterName}' >> /home/ec2-user/update-kubeconfig.sh
chmod +x /home/ec2-user/update-kubeconfig.sh
chown ec2-user:ec2-user /home/ec2-user/update-kubeconfig.sh

# Create a welcome message
cat << 'EOF' > /etc/motd
===================================================
    Welcome to ${spec.clusterName} Bastion Host
===================================================

This bastion host provides secure access to your private EKS cluster.

Getting Started:
1. Update kubeconfig: ./update-kubeconfig.sh
2. Test cluster access: kubectl get nodes
3. View cluster info: kubectl cluster-info

Tools installed:
- kubectl (Kubernetes CLI)
- aws-cli (AWS CLI)
- helm (Kubernetes package manager)

For support, refer to the cluster documentation.
===================================================
EOF
"""
                tags = spec.tags | {
                    "Name": "${spec.clusterName}-bastion"
                    "Purpose": "EKS-bastion-host"
                }
            }
        }
    }
    
    # Allow bastion to access EKS cluster security group
    bastionToEksRule = schemas.AWSResource {
        apiVersion = "ec2.aws.crossplane.io/v1beta1"
        kind = "SecurityGroupRule"
        metadata = schemas.ResourceMetadata {
            name = "${spec.clusterName}-bastion-to-eks-rule"
            labels = {
                "cluster": spec.clusterName
                "component": "security"
                "rule-type": "bastion-to-eks"
            }
        }
        spec = {
            forProvider = {
                region = spec.region
                type = "ingress"
                fromPort = 443
                toPort = 443
                protocol = "tcp"
                sourceSecurityGroupIdSelector = {
                    matchLabels = {
                        "cluster": spec.clusterName
                        "component": "bastion"
                        "sg-type": "bastion"
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
    }
    
    resources = [
        bastionSecurityGroup,
        bastionSshRule,
        bastionOutboundRule,
        bastionRole,
        bastionPolicy,
        bastionSSMPolicyAttachment,
        bastionPolicyAttachment,
        bastionInstanceProfile,
        bastionInstance,
        bastionToEksRule
    ]
    
    # Add key pair if public key is provided
    if spec.bastionConfig?.publicKey:
        resources = resources + [bastionKeyPair]
    
    resources
}
