
output "cluster_id" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.main.id
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "kubeconfig_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with your cluster."
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID for the EKS worker nodes."
  value       = aws_security_group.node.id
}

output "vpc_id" {
  description = "The VPC ID of the EKS cluster."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public[*].id
}


