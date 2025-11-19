# Terraform Configuration for CloudNativePG
# This file configures storage and networking for CNPG
# No Azure PostgreSQL Flexible Server needed!

# Storage Account for CNPG Backups (optional but recommended)
resource "azurerm_storage_account" "cnpg_backups" {
  name                     = "stcnpg${var.environment}${random_string.keyvault_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = {
    Environment = var.environment
    Purpose     = "CNPG-Backups"
  }
}

# Container for CNPG backups
resource "azurerm_storage_container" "cnpg_backups" {
  name                  = "postgresql-backups"
  storage_account_name  = azurerm_storage_account.cnpg_backups.name
  container_access_type = "private"
}
