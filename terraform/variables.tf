# Terraform Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-devops-assessment"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Environment name (dev or alaric for testing)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "alaric"], var.environment)
    error_message = "Environment must be dev or alaric (test environments only)."
  }
}

variable "acr_name" {
  description = "Name of the Azure Container Registry (must be globally unique)"
  type        = string
  default     = "acrdevopsassessment"
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 2
  validation {
    condition     = var.aks_node_count >= 1 && var.aks_node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "aks_node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"  # Burstable - perfect for this workload
  # Standard_B2s: 2 vCPUs, 4GB RAM - $30.37/month per node
  # Sufficient for lightweight CNPG (2 instances) + App (2 pods)
  # Total resources needed: ~1.5GB RAM, 1 vCPU
  # This VM provides: 4GB RAM, 2 vCPU (plenty of headroom!)
}

variable "enable_aks" {
  description = "Enable AKS cluster deployment"
  type        = bool
  default     = true
}

variable "enable_vm" {
  description = "Enable VM deployment (alternative to AKS)"
  type        = bool
  default     = false
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    Project   = "DevOps-Assessment"
    ManagedBy = "Terraform"
  }
}
