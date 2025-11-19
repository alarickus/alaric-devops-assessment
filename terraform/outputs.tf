# Terraform Outputs

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "Login server for Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  description = "Admin username for ACR"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for ACR"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "cnpg_backup_storage_account" {
  description = "Storage account for CNPG backups"
  value       = azurerm_storage_account.cnpg_backups.name
}

output "cnpg_backup_container" {
  description = "Storage container for CNPG backups"
  value       = azurerm_storage_container.cnpg_backups.name
}

output "cnpg_backup_url" {
  description = "Azure Blob URL for CNPG backups"
  value       = "https://${azurerm_storage_account.cnpg_backups.name}.blob.core.windows.net/${azurerm_storage_container.cnpg_backups.name}"
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = var.enable_aks ? azurerm_kubernetes_cluster.main[0].name : null
}

output "aks_kube_config_command" {
  description = "Command to get AKS credentials"
  value       = var.enable_aks ? "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main[0].name}" : null
}

output "cnpg_connection_info" {
  description = "CloudNativePG connection information"
  value = {
    primary_service   = "mirror-db-rw.mirror-app.svc.cluster.local:5432"
    replica_service   = "mirror-db-ro.mirror-app.svc.cluster.local:5432"
    read_service      = "mirror-db-r.mirror-app.svc.cluster.local:5432"
    database_name     = "mirrordb"
    app_username      = "app"
    note              = "PostgreSQL runs inside AKS cluster via CloudNativePG operator"
  }
}
