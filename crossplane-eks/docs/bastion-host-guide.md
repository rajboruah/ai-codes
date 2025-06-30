# Bastion Host Configuration Guide

## Overview

The bastion host (also known as a jump box) provides secure access to your private EKS cluster. It's deployed in a public subnet and acts as a gateway for administrators to access the private cluster resources.

## Architecture

```
Internet → Bastion Host (Public Subnet) → EKS Cluster (Private Subnet)
```

## Features

### 🔒 **Security**
- Deployed in public subnet with controlled access
- Dedicated security group with restricted SSH access
- IAM role with minimal required permissions
- Integration with AWS Systems Manager for keyless access

### 🛠️ **Pre-installed Tools**
- **kubectl**: Kubernetes command-line tool
- **aws-cli**: AWS Command Line Interface
- **helm**: Kubernetes package manager
- Auto-configured kubeconfig for your EKS cluster

### 🔑 **Access Methods**
- **SSH**: Traditional SSH access with key pair
- **AWS Systems Manager**: Keyless access via browser or CLI
- **Session Manager**: Secure shell access without open ports

## Configuration

### Basic Configuration

```yaml
bastionConfig:
  enabled: true                           # Enable/disable bastion host
  instanceType: "t3.micro"               # EC2 instance type
  allowedCidrs: ["0.0.0.0/0"]           # IP ranges allowed to SSH
```

### Advanced Configuration

```yaml
bastionConfig:
  enabled: true
  instanceType: "t3.small"               # Larger instance for production
  ami: "ami-0c02fb55956c7d316"          # Custom AMI (optional)
  publicKey: "ssh-rsa AAAAB3NzaC1yc2E..." # SSH public key
  allowedCidrs: ["203.0.113.0/24"]      # Restrict to your IP range
```

### Production Configuration

```yaml
bastionConfig:
  enabled: true
  instanceType: "t3.small"
  allowedCidrs: 
    - "10.0.0.0/8"      # Internal networks only
    - "172.16.0.0/12"   # Private IP ranges
    - "192.168.0.0/16"  # Local networks
  publicKey: "ssh-rsa AAAAB3NzaC1yc2E..." # Your SSH public key
```

## Access Methods

### 1. SSH Access (with Key Pair)

If you provide a public key in the configuration:

```bash
# SSH to bastion host
ssh -i ~/.ssh/your-key.pem ec2-user@<bastion-public-ip>

# Update kubeconfig
./update-kubeconfig.sh

# Test cluster access
kubectl get nodes
```

### 2. AWS Systems Manager Session Manager

Access without SSH keys:

```bash
# Start session via AWS CLI
aws ssm start-session --target <bastion-instance-id>

# Or use AWS Console
# Navigate to EC2 → Instances → Select Bastion → Connect → Session Manager
```

### 3. AWS Systems Manager Connect

Browser-based terminal access:

1. Open AWS Console
2. Navigate to EC2 → Instances
3. Select the bastion instance
4. Click "Connect"
5. Choose "Session Manager"
6. Click "Connect"

## Security Configuration

### Security Group Rules

The bastion host has a dedicated security group with:

**Inbound Rules:**
- Port 22 (SSH) from specified CIDR ranges
- HTTPS (443) outbound for AWS API calls

**Outbound Rules:**
- All traffic (for package updates and EKS access)

### IAM Permissions

The bastion host has these IAM permissions:

```json
{
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
}
```

## Using the Bastion Host

### Initial Setup

1. **Connect to bastion host** using your preferred method
2. **Update kubeconfig** to access your EKS cluster:
   ```bash
   ./update-kubeconfig.sh
   ```
3. **Verify cluster access**:
   ```bash
   kubectl get nodes
   kubectl cluster-info
   ```

### Common Tasks

#### View Cluster Resources
```bash
# Get cluster information
kubectl cluster-info

# List all nodes
kubectl get nodes -o wide

# Get all pods across namespaces
kubectl get pods --all-namespaces

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Deploy Applications
```bash
# Create a deployment
kubectl create deployment nginx --image=nginx

# Expose the deployment
kubectl expose deployment nginx --port=80 --type=ClusterIP

# Check deployment status
kubectl get deployments
kubectl get pods -l app=nginx
```

#### Manage Helm Charts
```bash
# Add a helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install a chart
helm install my-app bitnami/nginx

# List releases
helm list

# Upgrade a release
helm upgrade my-app bitnami/nginx
```

### File Transfer

#### Using SCP (with SSH key)
```bash
# Copy file to bastion
scp -i ~/.ssh/your-key.pem local-file.yaml ec2-user@<bastion-ip>:~/

# Copy file from bastion
scp -i ~/.ssh/your-key.pem ec2-user@<bastion-ip>:~/remote-file.yaml ./
```

#### Using AWS S3
```bash
# Upload to S3 from local machine
aws s3 cp local-file.yaml s3://your-bucket/

# Download from S3 on bastion
aws s3 cp s3://your-bucket/local-file.yaml ./
```

## Monitoring and Logging

### CloudWatch Logs

The bastion host automatically sends logs to CloudWatch:

```bash
# View system logs
sudo journalctl -u cloud-init

# View SSH logs
sudo tail -f /var/log/secure

# View system messages
sudo tail -f /var/log/messages
```

### Session Manager Logging

All Session Manager sessions are logged to CloudWatch automatically.

## Cost Optimization

### Instance Sizing

- **Development**: `t3.micro` ($8-10/month)
- **Production**: `t3.small` ($15-20/month)
- **High Usage**: `t3.medium` ($30-35/month)

### Scheduling

For non-production environments, consider:

```bash
# Stop bastion at night (save ~70% on compute costs)
aws ec2 stop-instances --instance-ids <bastion-instance-id>

# Start bastion when needed
aws ec2 start-instances --instance-ids <bastion-instance-id>
```

### Automation

Use AWS Lambda to automatically start/stop bastion hosts based on schedule:

```python
import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    
    # Stop bastion hosts tagged for scheduling
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:AutoSchedule', 'Values': ['true']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            ec2.stop_instances(InstanceIds=[instance['InstanceId']])
    
    return {'statusCode': 200, 'body': 'Bastion hosts stopped'}
```

## Security Best Practices

### 1. Restrict SSH Access

Always restrict SSH access to known IP ranges:

```yaml
bastionConfig:
  allowedCidrs: 
    - "203.0.113.0/24"  # Your office IP range
    - "198.51.100.0/24" # Your home IP range
```

### 2. Use Systems Manager Instead of SSH

Prefer Session Manager over SSH when possible:
- No need to manage SSH keys
- All sessions are logged
- No open SSH ports required

### 3. Regular Updates

Keep the bastion host updated:

```bash
# Update system packages
sudo yum update -y

# Update kubectl
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.31.0/2024-09-12/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

### 4. Monitor Access

Set up CloudWatch alarms for:
- Failed SSH attempts
- Unusual login patterns
- High resource utilization

### 5. Use MFA

Enable MFA for IAM users accessing the bastion host:

```bash
# Configure AWS CLI with MFA
aws configure set aws_access_key_id YOUR_ACCESS_KEY
aws configure set aws_secret_access_key YOUR_SECRET_KEY
aws configure set default.region us-west-2

# Use MFA token
aws sts get-session-token --serial-number arn:aws:iam::123456789012:mfa/user --token-code 123456
```

## Troubleshooting

### Common Issues

#### 1. Cannot SSH to Bastion
- Check security group allows your IP
- Verify key pair is correct
- Ensure bastion instance is running

#### 2. Cannot Access EKS Cluster
- Run `./update-kubeconfig.sh`
- Check IAM permissions
- Verify cluster is in same region

#### 3. kubectl Commands Fail
- Ensure kubeconfig is updated
- Check cluster endpoint accessibility
- Verify security group rules

#### 4. Session Manager Not Working
- Check IAM role has SSM permissions
- Verify SSM agent is installed
- Ensure outbound HTTPS is allowed

### Debugging Commands

```bash
# Check bastion instance status
aws ec2 describe-instances --instance-ids <bastion-instance-id>

# View security group rules
aws ec2 describe-security-groups --group-ids <security-group-id>

# Test EKS cluster connectivity
aws eks describe-cluster --name <cluster-name>

# Check kubectl configuration
kubectl config view
kubectl config current-context

# Test network connectivity
curl -I https://eks.<region>.amazonaws.com
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Deploy to EKS via Bastion

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Deploy via Bastion
      run: |
        # Start bastion if stopped
        aws ec2 start-instances --instance-ids ${{ secrets.BASTION_INSTANCE_ID }}
        
        # Wait for bastion to be ready
        aws ec2 wait instance-running --instance-ids ${{ secrets.BASTION_INSTANCE_ID }}
        
        # Execute deployment via SSM
        aws ssm send-command \
          --instance-ids ${{ secrets.BASTION_INSTANCE_ID }} \
          --document-name "AWS-RunShellScript" \
          --parameters 'commands=["kubectl apply -f /path/to/manifests/"]'
```

This bastion host configuration provides a secure, feature-rich access point for your private EKS cluster while maintaining security best practices and operational efficiency.
