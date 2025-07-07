
output "cluster_id" {
  description = "The ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.id
}

output "kube_config_raw" {
  description = "Raw Kubernetes config for the AKS cluster."
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "resource_group_name" {
  description = "The name of the resource group in which the AKS cluster is created."
  value       = azurerm_resource_group.main.name
}

output "virtual_network_name" {
  description = "The name of the virtual network."
  value       = azurerm_virtual_network.main.name
}

output "subnet_id" {
  description = "The ID of the subnet where the AKS cluster nodes are deployed."
  value       = azurerm_subnet.internal.id
}


