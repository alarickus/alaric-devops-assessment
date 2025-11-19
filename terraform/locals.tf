# Local Values
# Computed values and common configurations used across resources

locals {
  # Common naming convention
  name_prefix = "${var.environment}-devops"
  
  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "DevOps-Assessment"
      CreatedDate = timestamp()
    }
  )
  
  # Resource naming with consistent pattern
  resource_names = {
    aks            = "aks-${local.name_prefix}"
    vnet           = "vnet-${local.name_prefix}"
    subnet_aks     = "snet-aks-${local.name_prefix}"
    acr            = var.acr_name
    keyvault       = "kv-${var.environment}-${random_string.keyvault_suffix.result}"
    log_analytics  = "law-${local.name_prefix}"
    storage_cnpg   = "stcnpg${var.environment}${random_string.keyvault_suffix.result}"
    nsg            = "nsg-${local.name_prefix}"
  }
  
  # Network configuration
  network_config = {
    vnet_address_space      = ["10.0.0.0/16"]
    aks_subnet_prefix       = ["10.0.1.0/24"]
    service_cidr            = "10.1.0.0/16"
    dns_service_ip          = "10.1.0.10"
  }
  
  # AKS configuration
  aks_config = {
    kubernetes_version = "1.28.3"
    network_plugin     = "azure"
    network_policy     = "azure"
    load_balancer_sku  = "standard"
  }
  
  # Storage tiers by environment
  storage_tier = {
    dev     = "Standard_LRS"
    staging = "Standard_LRS"
    prod    = "Standard_LRS"
  }
  
  # Backup retention by environment
  backup_retention = {
    dev     = 7
    staging = 14
    prod    = 30
  }
}
