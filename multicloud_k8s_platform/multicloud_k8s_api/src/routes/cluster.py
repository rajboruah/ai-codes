from flask import Blueprint, request, jsonify
from src.models.cluster import db, Cluster
from src.routes.auth import require_auth, require_admin
import subprocess
import os
import json
import threading
import time

cluster_bp = Blueprint('cluster', __name__)

def run_terraform_async(cluster_id, action='apply'):
    """Run Terraform commands asynchronously"""
    try:
        cluster = Cluster.query.get(cluster_id)
        if not cluster:
            return
        
        # Update status to creating/deleting
        cluster.status = 'creating' if action == 'apply' else 'deleting'
        db.session.commit()
        
        # Create working directory for this cluster
        work_dir = f"/tmp/terraform_clusters/{cluster.name}"
        os.makedirs(work_dir, exist_ok=True)
        
        # Generate Terraform configuration based on cloud provider
        if cluster.cloud_provider == 'aws':
            generate_aws_terraform_config(cluster, work_dir)
        elif cluster.cloud_provider == 'azure':
            generate_azure_terraform_config(cluster, work_dir)
        
        # Run Terraform commands
        os.chdir(work_dir)
        
        # Initialize Terraform
        subprocess.run(['terraform', 'init'], check=True, capture_output=True)
        
        if action == 'apply':
            # Plan and apply
            subprocess.run(['terraform', 'plan'], check=True, capture_output=True)
            result = subprocess.run(['terraform', 'apply', '-auto-approve'], 
                                  check=True, capture_output=True, text=True)
            
            # Get outputs
            output_result = subprocess.run(['terraform', 'output', '-json'], 
                                         capture_output=True, text=True)
            if output_result.returncode == 0:
                outputs = json.loads(output_result.stdout)
                if 'cluster_endpoint' in outputs:
                    cluster.cluster_endpoint = outputs['cluster_endpoint']['value']
            
            cluster.status = 'running'
            cluster.terraform_state_path = os.path.join(work_dir, 'terraform.tfstate')
            
        elif action == 'destroy':
            # Destroy infrastructure
            subprocess.run(['terraform', 'destroy', '-auto-approve'], 
                          check=True, capture_output=True)
            cluster.status = 'deleted'
        
        db.session.commit()
        
    except subprocess.CalledProcessError as e:
        cluster.status = 'failed'
        db.session.commit()
        print(f"Terraform error: {e}")
    except Exception as e:
        cluster.status = 'failed'
        db.session.commit()
        print(f"Error: {e}")

def generate_aws_terraform_config(cluster, work_dir):
    """Generate Terraform configuration for AWS"""
    main_tf = f"""
terraform {{
  required_providers {{
    aws = {{
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }}
  }}
}}

provider "aws" {{
  region = "{cluster.region}"
}}

module "aws_kubernetes" {{
  source = "/home/ubuntu/terraform/modules/aws_kubernetes"
  
  cluster_name = "{cluster.name}"
  kubernetes_version = "{cluster.kubernetes_version}"
  vpc_cidr_block = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  node_count = {cluster.node_count}
  instance_type = "{cluster.instance_type}"
}}

output "cluster_endpoint" {{
  value = module.aws_kubernetes.cluster_endpoint
}}

output "cluster_id" {{
  value = module.aws_kubernetes.cluster_id
}}
"""
    
    with open(os.path.join(work_dir, 'main.tf'), 'w') as f:
        f.write(main_tf)

def generate_azure_terraform_config(cluster, work_dir):
    """Generate Terraform configuration for Azure"""
    main_tf = f"""
terraform {{
  required_providers {{
    azurerm = {{
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }}
  }}
}}

provider "azurerm" {{
  features {{}}
}}

module "azure_kubernetes" {{
  source = "/home/ubuntu/terraform/modules/azure_kubernetes"
  
  resource_group_name = "{cluster.name}-rg"
  location = "{cluster.region}"
  cluster_name = "{cluster.name}"
  kubernetes_version = "{cluster.kubernetes_version}"
  vnet_address_space = "10.0.0.0/16"
  subnet_address_prefix = "10.0.1.0/24"
  node_count = {cluster.node_count}
  vm_size = "{cluster.instance_type}"
  client_id = "${{var.azure_client_id}}"
  client_secret = "${{var.azure_client_secret}}"
}}

variable "azure_client_id" {{
  description = "Azure Service Principal Client ID"
  type        = string
}}

variable "azure_client_secret" {{
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}}

output "cluster_id" {{
  value = module.azure_kubernetes.cluster_id
}}
"""
    
    with open(os.path.join(work_dir, 'main.tf'), 'w') as f:
        f.write(main_tf)

@cluster_bp.route('/clusters', methods=['GET'])
@require_auth
def get_clusters():
    """Get all clusters"""
    clusters = Cluster.query.all()
    return jsonify([cluster.to_dict() for cluster in clusters])

@cluster_bp.route('/clusters/<int:cluster_id>', methods=['GET'])
@require_auth
def get_cluster(cluster_id):
    """Get a specific cluster"""
    cluster = Cluster.query.get_or_404(cluster_id)
    return jsonify(cluster.to_dict())

@cluster_bp.route('/clusters', methods=['POST'])
@require_auth
def create_cluster():
    """Create a new cluster"""
    data = request.get_json()
    
    # Validate required fields
    required_fields = ['name', 'cloud_provider', 'region', 'kubernetes_version', 'instance_type']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Missing required field: {field}'}), 400
    
    # Validate cloud provider
    if data['cloud_provider'] not in ['aws', 'azure']:
        return jsonify({'error': 'cloud_provider must be either "aws" or "azure"'}), 400
    
    # Create new cluster record
    cluster = Cluster(
        name=data['name'],
        cloud_provider=data['cloud_provider'],
        region=data['region'],
        kubernetes_version=data['kubernetes_version'],
        node_count=data.get('node_count', 2),
        instance_type=data['instance_type'],
        status='pending'
    )
    
    db.session.add(cluster)
    db.session.commit()
    
    # Start Terraform provisioning in background
    thread = threading.Thread(target=run_terraform_async, args=(cluster.id, 'apply'))
    thread.daemon = True
    thread.start()
    
    return jsonify(cluster.to_dict()), 201

@cluster_bp.route('/clusters/<int:cluster_id>', methods=['DELETE'])
@require_admin
def delete_cluster(cluster_id):
    """Delete a cluster"""
    cluster = Cluster.query.get_or_404(cluster_id)
    
    if cluster.status in ['creating', 'deleting']:
        return jsonify({'error': 'Cannot delete cluster while it is being created or deleted'}), 400
    
    # Start Terraform destroy in background
    thread = threading.Thread(target=run_terraform_async, args=(cluster.id, 'destroy'))
    thread.daemon = True
    thread.start()
    
    return jsonify({'message': 'Cluster deletion initiated'}), 200

@cluster_bp.route('/clusters/<int:cluster_id>/status', methods=['GET'])
@require_auth
def get_cluster_status(cluster_id):
    """Get cluster status"""
    cluster = Cluster.query.get_or_404(cluster_id)
    return jsonify({
        'id': cluster.id,
        'name': cluster.name,
        'status': cluster.status,
        'updated_at': cluster.updated_at.isoformat() if cluster.updated_at else None
    })

