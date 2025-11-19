# Azure Kubernetes Service Configuration

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  count               = var.enable_aks ? 1 : 0
  name                = "aks-${var.environment}-devops"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${var.environment}-devops"
  
  # Kubernetes version - pinned for stability
  kubernetes_version = "1.32.9"  # Stable version - tested and working in westeurope
  
  # Automatic upgrade channel (optional)
  automatic_channel_upgrade = "patch"  # Auto-upgrade patch versions only

  default_node_pool {
    name                = "default"
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
    os_disk_size_gb     = 30
    
    # Node labels
    node_labels = {
      environment = var.environment
      nodepool    = "default"
    }
    
    # Upgrade settings
    upgrade_settings {
      max_surge = "33%"  # Max 33% nodes upgraded at once
    }
  }

  # Use System-Assigned Managed Identity (no service principal credentials!)
  identity {
    type = "SystemAssigned"
  }
  
  # Alternative: User-Assigned Managed Identity
  # identity {
  #   type         = "UserAssigned"
  #   identity_ids = [azurerm_user_assigned_identity.aks.id]
  # }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"  # Enable network policies
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  # Azure Monitor integration
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Enable Azure Policy addon
  azure_policy_enabled = true
  
  # Enable RBAC
  role_based_access_control_enabled = true
  
  # Azure AD integration (optional)
  # azure_active_directory_role_based_access_control {
  #   managed                = true
  #   azure_rbac_enabled     = true
  # }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Component   = "AKS-Cluster"
    }
  )
}

# Role assignment for AKS to pull images from ACR
# Uses AKS System-Assigned Managed Identity (no credentials needed!)
resource "azurerm_role_assignment" "aks_acr" {
  count                = var.enable_aks ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.main[0].kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.main.id
  
  # Prevents deletion if assignment is being used
  skip_service_principal_aad_check = true
}

# Additional role for AKS to manage network
resource "azurerm_role_assignment" "aks_network" {
  count                = var.enable_aks ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.main[0].identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_virtual_network.main.id
  
  skip_service_principal_aad_check = true
}

# Note: Using Managed Identity eliminates need for:
# - Service Principal credentials
# - Client secrets
# - Password management
# - Manual key rotation
# Azure handles all authentication automatically!
