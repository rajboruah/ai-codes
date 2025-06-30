# EKS Private Cluster Configuration

## Overview

This Crossplane configuration creates a fully private Amazon EKS cluster where the API server endpoint is only accessible from within the VPC. This provides enhanced security by preventing direct internet access to the cluster's control plane.

## Architecture Components

### Network Architecture

```
Internet Gateway
       |
   Public Subnets (NAT Gateway + Load Balancers)
       |
   NAT Gateway
       |
   Private Subnets (EKS Nodes)
       |
   EKS Cluster (Private API Endpoint)
```

### Key Resources Created

1. **VPC**: Virtual Private Cloud with configurable CIDR block
2. **Public Subnets**: For NAT Gateways and Application Load Balancers
3. **Private Subnets**: For EKS worker nodes and pods
4. **Internet Gateway**: Provides internet access to public subnets
5. **NAT Gateways**: Enable outbound internet access for private subnets
6. **Elastic IPs**: Static IP addresses for NAT Gateways
7. **Route Tables**: Control traffic routing between subnets
8. **EKS Cluster**: Private API endpoint, deployed across private subnets
9. **EKS Node Groups**: Worker nodes in private subnets only

## Security Benefits

1. **No Direct Internet Access**: The EKS API server cannot be accessed directly from the internet
2. **Controlled Access**: Access to the cluster requires VPN, bastion host, or AWS connectivity
3. **Outbound Internet**: Nodes can still pull container images and communicate with AWS services
4. **Load Balancer Support**: Applications can still expose services via ALB/NLB in public subnets

## Configuration Parameters

### Networking Configuration

```yaml
networking:
  vpcCidr: "10.0.0.0/16"                    # VPC CIDR block
  enablePrivateEndpoint: true               # Always true for private clusters
  enablePublicEndpoint: false               # Always false for private clusters
  subnetCidrs:
    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]    # For NAT Gateway
    privateSubnets: ["10.0.10.0/24", "10.0.20.0/24"] # For EKS nodes
```

### Node Group Configuration

```yaml
nodeGroupConfig:
  instanceTypes: ["t3.medium", "t3.large"]  # EC2 instance types
  minSize: 2                                # Minimum number of nodes
  maxSize: 10                               # Maximum number of nodes
  desiredSize: 3                            # Desired number of nodes
  diskSize: 50                              # Root volume size in GB
  capacityType: "ON_DEMAND"                 # ON_DEMAND or SPOT
```

## Access Patterns

### 1. Bastion Host Access

Deploy a bastion host in a public subnet:

```yaml
# Example bastion host configuration
apiVersion: ec2.aws.crossplane.io/v1alpha1
kind: Instance
metadata:
  name: eks-bastion
spec:
  forProvider:
    region: us-west-2
    instanceType: t3.micro
    subnetIdSelector:
      matchLabels:
        subnet-type: "public"
    # Configure security groups to allow SSH
```

### 2. VPN Access

Set up AWS Client VPN or Site-to-Site VPN:
- Client VPN for individual developer access
- Site-to-Site VPN for office/datacenter connectivity

### 3. AWS Systems Manager Session Manager

Access nodes without SSH using SSM:

```bash
aws ssm start-session --target i-1234567890abcdef0
```

### 4. AWS CloudShell

Use AWS CloudShell from the AWS Console for kubectl access.

## Application Deployment

### Load Balancer Configuration

Applications can still be exposed to the internet using AWS Load Balancers:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-subnets: public-subnet-1,public-subnet-2
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
```

### Ingress Configuration

Use AWS Load Balancer Controller for advanced ingress features:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/subnets: public-subnet-1,public-subnet-2
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
```

## Monitoring and Logging

### CloudWatch Container Insights

Enable container insights for monitoring:

```yaml
# This is automatically configured in the composition
# EKS addons include CloudWatch observability
```

### VPC Flow Logs

Monitor network traffic:

```yaml
apiVersion: ec2.aws.crossplane.io/v1alpha1
kind: FlowLog
metadata:
  name: vpc-flow-logs
spec:
  forProvider:
    region: us-west-2
    resourceType: VPC
    resourceIdSelector:
      matchLabels:
        component: "networking"
    trafficType: ALL
    logDestinationType: cloud-watch-logs
```

## Cost Considerations

### NAT Gateway Costs

- NAT Gateways have hourly charges and data processing fees
- Consider using NAT Instances for cost optimization in non-production environments
- One NAT Gateway per private subnet for high availability

### EIP Costs

- Elastic IP addresses have hourly charges when not associated
- EIPs are automatically associated with NAT Gateways

## Troubleshooting

### Common Issues

1. **Cannot access cluster**: Ensure you're connecting from within the VPC or through VPN
2. **Pods cannot pull images**: Check NAT Gateway configuration and routes
3. **LoadBalancer not working**: Verify subnets are tagged correctly for ALB/NLB

### Debugging Commands

```bash
# Check cluster endpoint configuration
aws eks describe-cluster --name <cluster-name> --query cluster.endpoint

# Verify private endpoint access
aws eks describe-cluster --name <cluster-name> --query cluster.resourcesVpcConfig.endpointConfigPrivate

# Check subnet configurations
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/cluster/<cluster-name>,Values=shared"
```

## Migration from Public Cluster

If migrating from a public EKS cluster:

1. **Plan Access**: Set up VPN or bastion host before migration
2. **Update CI/CD**: Ensure build systems can access the private cluster
3. **Load Balancer**: Verify application load balancers work with new subnets
4. **DNS**: Update DNS entries if using custom domains

## Best Practices

1. **High Availability**: Deploy across multiple AZs
2. **Security Groups**: Use least-privilege access rules
3. **Backup Access**: Always have multiple ways to access the cluster
4. **Monitoring**: Set up comprehensive monitoring and alerting
5. **Documentation**: Document access procedures for team members
