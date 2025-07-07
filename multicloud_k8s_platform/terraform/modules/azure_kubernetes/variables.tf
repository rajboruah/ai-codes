
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the Virtual Machine for worker nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "client_id" {
  description = "Client ID of the Service Principal for AKS"
  type        = string
}

variable "client_secret" {
  description = "Client Secret of the Service Principal for AKS"
  type        = string
  sensitive   = true
}


