# Multi-Cloud Kubernetes Platform Deployment Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Environment Setup](#environment-setup)
4. [Backend Deployment](#backend-deployment)
5. [Frontend Deployment](#frontend-deployment)
6. [Cloud Provider Configuration](#cloud-provider-configuration)
7. [Security Configuration](#security-configuration)
8. [Monitoring and Maintenance](#monitoring-and-maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Appendices](#appendices)

## Introduction

This deployment guide provides comprehensive instructions for setting up and deploying the Multi-Cloud Kubernetes Platform in a production environment. The platform enables users to provision and manage Kubernetes clusters across AWS and Azure through a web-based interface, utilizing Terraform for infrastructure automation.

The deployment process involves setting up the Flask backend API, React frontend application, configuring cloud provider credentials, and ensuring proper security measures are in place. This guide assumes you have basic knowledge of cloud platforms, containerization, and web application deployment.

## Prerequisites

Before beginning the deployment process, ensure you have the following prerequisites in place:

### System Requirements

- **Operating System**: Ubuntu 20.04 LTS or later, CentOS 8+, or compatible Linux distribution
- **Memory**: Minimum 4GB RAM, recommended 8GB or more
- **Storage**: At least 20GB available disk space
- **Network**: Stable internet connection with outbound access to AWS and Azure APIs

### Software Dependencies

- **Python**: Version 3.8 or later
- **Node.js**: Version 16 or later
- **npm/yarn**: Latest stable version
- **Terraform**: Version 1.0 or later
- **Git**: For source code management
- **Docker** (optional): For containerized deployment

### Cloud Provider Accounts

- **AWS Account**: With appropriate IAM permissions for EKS cluster creation
- **Azure Account**: With subscription and service principal for AKS cluster creation
- **Domain Name** (optional): For custom domain configuration

### Access Credentials

- **AWS Access Keys**: IAM user with programmatic access
- **Azure Service Principal**: Client ID and secret for authentication
- **SSH Key Pairs**: For accessing EC2/VM instances if needed

## Environment Setup

### Server Preparation

Begin by preparing your deployment server with the necessary software and configurations. Update your system packages and install required dependencies:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Python and pip
sudo apt install python3 python3-pip python3-venv -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Directory Structure

Create a well-organized directory structure for the deployment:

```bash
# Create application directory
sudo mkdir -p /opt/multicloud-k8s
sudo chown $USER:$USER /opt/multicloud-k8s
cd /opt/multicloud-k8s

# Create subdirectories
mkdir -p {backend,frontend,terraform,logs,config}
```

### Environment Variables

Set up environment variables for configuration management. Create a `.env` file in the application root:

```bash
# Application Configuration
FLASK_ENV=production
SECRET_KEY=your-super-secret-key-here
DATABASE_URL=sqlite:///app.db

# AWS Configuration
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_DEFAULT_REGION=us-east-1

# Azure Configuration
AZURE_CLIENT_ID=your-azure-client-id
AZURE_CLIENT_SECRET=your-azure-client-secret
AZURE_TENANT_ID=your-azure-tenant-id
AZURE_SUBSCRIPTION_ID=your-azure-subscription-id

# Application Settings
ALLOWED_HOSTS=localhost,your-domain.com
CORS_ORIGINS=https://your-domain.com
```

## Backend Deployment

### Source Code Deployment

Clone or copy the backend source code to the deployment server:

```bash
cd /opt/multicloud-k8s/backend
# Copy your backend source code here
# Ensure the following structure exists:
# src/
# ├── models/
# ├── routes/
# ├── static/
# └── main.py
# requirements.txt
```

### Python Environment Setup

Create and configure a Python virtual environment for the backend:

```bash
cd /opt/multicloud-k8s/backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Database Configuration

Initialize the database and ensure proper permissions:

```bash
# Create database directory
mkdir -p /opt/multicloud-k8s/backend/src/database

# Set proper permissions
chmod 755 /opt/multicloud-k8s/backend/src/database

# Initialize database (will be created automatically on first run)
python src/main.py --init-db
```

### Systemd Service Configuration

Create a systemd service for the backend application to ensure it starts automatically and runs reliably:

```bash
sudo tee /etc/systemd/system/multicloud-k8s-backend.service > /dev/null <<EOF
[Unit]
Description=Multi-Cloud Kubernetes Platform Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/multicloud-k8s/backend
Environment=PATH=/opt/multicloud-k8s/backend/venv/bin
ExecStart=/opt/multicloud-k8s/backend/venv/bin/python src/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable multicloud-k8s-backend
sudo systemctl start multicloud-k8s-backend
```

### Nginx Configuration

Configure Nginx as a reverse proxy for the backend application:

```bash
sudo apt install nginx -y

sudo tee /etc/nginx/sites-available/multicloud-k8s > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static/ {
        alias /opt/multicloud-k8s/backend/src/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable the site
sudo ln -s /etc/nginx/sites-available/multicloud-k8s /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Frontend Deployment

### Build Process

The frontend React application needs to be built for production and integrated with the backend:

```bash
cd /opt/multicloud-k8s/frontend
# Copy your frontend source code here

# Install dependencies
npm install

# Build for production
npm run build

# Copy built files to backend static directory
cp -r dist/* /opt/multicloud-k8s/backend/src/static/
```

### Static File Optimization

Optimize static files for better performance:

```bash
# Install compression tools
sudo apt install gzip brotli -y

# Compress static files
find /opt/multicloud-k8s/backend/src/static -name "*.js" -exec gzip -k {} \;
find /opt/multicloud-k8s/backend/src/static -name "*.css" -exec gzip -k {} \;
find /opt/multicloud-k8s/backend/src/static -name "*.js" -exec brotli -k {} \;
find /opt/multicloud-k8s/backend/src/static -name "*.css" -exec brotli -k {} \;
```

## Cloud Provider Configuration

### AWS Configuration

Configure AWS credentials and permissions for EKS cluster creation:

#### IAM Policy Creation

Create an IAM policy with the necessary permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PassRole",
                "iam:GetRole",
                "iam:ListAttachedRolePolicies"
            ],
            "Resource": "*"
        }
    ]
}
```

#### IAM User Setup

Create an IAM user and attach the policy:

```bash
# Using AWS CLI
aws iam create-user --user-name multicloud-k8s-user
aws iam attach-user-policy --user-name multicloud-k8s-user --policy-arn arn:aws:iam::YOUR-ACCOUNT:policy/MultiCloudK8sPolicy
aws iam create-access-key --user-name multicloud-k8s-user
```

### Azure Configuration

Configure Azure service principal and permissions for AKS cluster creation:

#### Service Principal Creation

Create a service principal with the necessary permissions:

```bash
# Using Azure CLI
az ad sp create-for-rbac --name "multicloud-k8s-sp" --role="Contributor" --scopes="/subscriptions/YOUR-SUBSCRIPTION-ID"
```

#### Role Assignment

Assign additional roles if needed:

```bash
az role assignment create --assignee YOUR-CLIENT-ID --role "User Access Administrator" --scope "/subscriptions/YOUR-SUBSCRIPTION-ID"
```

### Terraform State Management

Configure remote state management for Terraform:

#### AWS S3 Backend

```bash
# Create S3 bucket for state
aws s3 mb s3://multicloud-k8s-terraform-state-YOUR-UNIQUE-ID

# Create DynamoDB table for locking
aws dynamodb create-table \
    --table-name multicloud-k8s-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

#### Backend Configuration

Update the Terraform backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "multicloud-k8s-terraform-state-YOUR-UNIQUE-ID"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "multicloud-k8s-terraform-locks"
    encrypt        = true
  }
}
```

## Security Configuration

### SSL/TLS Configuration

Configure SSL certificates for secure communication:

#### Let's Encrypt Setup

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Test automatic renewal
sudo certbot renew --dry-run
```

#### Nginx SSL Configuration

Update Nginx configuration for SSL:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

### Firewall Configuration

Configure UFW firewall for security:

```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Check status
sudo ufw status
```

### Application Security

#### Secret Key Management

Generate a secure secret key for Flask:

```python
import secrets
print(secrets.token_hex(32))
```

#### Database Security

Secure the SQLite database:

```bash
# Set proper permissions
chmod 600 /opt/multicloud-k8s/backend/src/database/app.db
chown ubuntu:ubuntu /opt/multicloud-k8s/backend/src/database/app.db
```

## Monitoring and Maintenance

### Log Configuration

Configure comprehensive logging for monitoring and troubleshooting:

#### Application Logs

```python
import logging
from logging.handlers import RotatingFileHandler

# Configure logging in Flask app
if not app.debug:
    file_handler = RotatingFileHandler('/opt/multicloud-k8s/logs/app.log', maxBytes=10240000, backupCount=10)
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
    ))
    file_handler.setLevel(logging.INFO)
    app.logger.addHandler(file_handler)
    app.logger.setLevel(logging.INFO)
```

#### System Logs

Monitor system logs for the application:

```bash
# View application logs
sudo journalctl -u multicloud-k8s-backend -f

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Health Checks

Implement health check endpoints:

```python
@app.route('/health')
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    })
```

### Backup Strategy

#### Database Backup

```bash
#!/bin/bash
# Create backup script
cat > /opt/multicloud-k8s/scripts/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/multicloud-k8s/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
cp /opt/multicloud-k8s/backend/src/database/app.db $BACKUP_DIR/app_db_$DATE.db

# Backup configuration
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /opt/multicloud-k8s/config

# Clean old backups (keep last 30 days)
find $BACKUP_DIR -name "*.db" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
EOF

chmod +x /opt/multicloud-k8s/scripts/backup.sh

# Add to crontab
echo "0 2 * * * /opt/multicloud-k8s/scripts/backup.sh" | crontab -
```

### Performance Monitoring

#### System Monitoring

Install and configure monitoring tools:

```bash
# Install htop for system monitoring
sudo apt install htop -y

# Install and configure Prometheus (optional)
# This is a more advanced setup for production monitoring
```

#### Application Performance

Monitor application performance metrics:

```python
import time
from functools import wraps

def monitor_performance(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        start_time = time.time()
        result = f(*args, **kwargs)
        end_time = time.time()
        app.logger.info(f'{f.__name__} took {end_time - start_time:.2f} seconds')
        return result
    return decorated_function
```

## Troubleshooting

### Common Issues and Solutions

#### Backend Service Issues

**Issue**: Backend service fails to start
**Solution**: Check logs and verify dependencies

```bash
# Check service status
sudo systemctl status multicloud-k8s-backend

# View detailed logs
sudo journalctl -u multicloud-k8s-backend -n 50

# Check Python dependencies
cd /opt/multicloud-k8s/backend
source venv/bin/activate
pip check
```

#### Database Connection Issues

**Issue**: Database connection errors
**Solution**: Verify database file permissions and path

```bash
# Check database file
ls -la /opt/multicloud-k8s/backend/src/database/

# Test database connection
cd /opt/multicloud-k8s/backend
source venv/bin/activate
python -c "from src.models.cluster import db; print('Database connection successful')"
```

#### Terraform Execution Issues

**Issue**: Terraform commands fail
**Solution**: Verify cloud provider credentials and permissions

```bash
# Test AWS credentials
aws sts get-caller-identity

# Test Azure credentials
az account show

# Check Terraform version
terraform version

# Validate Terraform configuration
cd /tmp/terraform_clusters/test-cluster
terraform validate
```

#### Frontend Loading Issues

**Issue**: Frontend not loading properly
**Solution**: Check static file serving and build process

```bash
# Verify static files exist
ls -la /opt/multicloud-k8s/backend/src/static/

# Check Nginx configuration
sudo nginx -t

# Rebuild frontend if necessary
cd /opt/multicloud-k8s/frontend
npm run build
cp -r dist/* /opt/multicloud-k8s/backend/src/static/
```

### Debugging Tools

#### Log Analysis

```bash
# Real-time log monitoring
sudo tail -f /opt/multicloud-k8s/logs/app.log

# Search for specific errors
grep -i error /opt/multicloud-k8s/logs/app.log

# Analyze Nginx access patterns
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr
```

#### Network Debugging

```bash
# Check port availability
sudo netstat -tlnp | grep :5000

# Test API endpoints
curl -X GET http://localhost:5000/health

# Check SSL certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

### Performance Optimization

#### Database Optimization

```bash
# Analyze database size
du -h /opt/multicloud-k8s/backend/src/database/app.db

# Vacuum SQLite database
sqlite3 /opt/multicloud-k8s/backend/src/database/app.db "VACUUM;"
```

#### Web Server Optimization

```nginx
# Add to Nginx configuration for better performance
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

# Enable browser caching
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Appendices

### Appendix A: Complete Configuration Files

#### Environment Configuration (.env)

```bash
# Flask Configuration
FLASK_ENV=production
SECRET_KEY=your-generated-secret-key-here
DATABASE_URL=sqlite:///app.db

# AWS Configuration
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=us-east-1

# Azure Configuration
AZURE_CLIENT_ID=...
AZURE_CLIENT_SECRET=...
AZURE_TENANT_ID=...
AZURE_SUBSCRIPTION_ID=...

# Application Settings
ALLOWED_HOSTS=localhost,your-domain.com
CORS_ORIGINS=https://your-domain.com
```

#### Systemd Service File

```ini
[Unit]
Description=Multi-Cloud Kubernetes Platform Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/multicloud-k8s/backend
Environment=PATH=/opt/multicloud-k8s/backend/venv/bin
EnvironmentFile=/opt/multicloud-k8s/.env
ExecStart=/opt/multicloud-k8s/backend/venv/bin/python src/main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Appendix B: Security Checklist

- [ ] SSL/TLS certificates configured and auto-renewal enabled
- [ ] Firewall configured with minimal required ports
- [ ] Strong secret keys generated and configured
- [ ] Database file permissions properly set
- [ ] Cloud provider credentials securely stored
- [ ] Regular security updates scheduled
- [ ] Backup strategy implemented and tested
- [ ] Monitoring and alerting configured
- [ ] Log rotation configured
- [ ] Access controls implemented

### Appendix C: Maintenance Schedule

#### Daily Tasks
- Monitor application logs for errors
- Check system resource usage
- Verify backup completion

#### Weekly Tasks
- Review security logs
- Update system packages
- Test backup restoration
- Monitor SSL certificate expiration

#### Monthly Tasks
- Review and rotate access keys
- Analyze performance metrics
- Update application dependencies
- Conduct security audit

#### Quarterly Tasks
- Review and update documentation
- Conduct disaster recovery testing
- Review and update security policies
- Plan capacity upgrades if needed

This comprehensive deployment guide provides all the necessary information to successfully deploy and maintain the Multi-Cloud Kubernetes Platform in a production environment. Regular maintenance and monitoring are essential for ensuring optimal performance and security.

