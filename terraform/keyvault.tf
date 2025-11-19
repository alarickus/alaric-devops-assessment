# Azure Key Vault Configuration

# Random suffix for Key Vault name (must be globally unique)
resource "random_string" "keyvault_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.environment}-${random_string.keyvault_suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update"
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = {
    Environment = var.environment
    Project     = "DevOps-Assessment"
  }
}

# Store ACR admin password
resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-admin-password"
  value        = azurerm_container_registry.main.admin_password
  key_vault_id = azurerm_key_vault.main.id
}

# Store ACR username
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-admin-username"
  value        = azurerm_container_registry.main.admin_username
  key_vault_id = azurerm_key_vault.main.id
}

# Store CNPG backup storage credentials
resource "azurerm_key_vault_secret" "cnpg_storage_account" {
  name         = "cnpg-storage-account"
  value        = azurerm_storage_account.cnpg_backups.name
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "cnpg_storage_key" {
  name         = "cnpg-storage-key"
  value        = azurerm_storage_account.cnpg_backups.primary_access_key
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_storage_account.cnpg_backups]
}

# Note: Database credentials for CNPG are managed in Kubernetes secrets
# See k8s/cnpg/02-credentials.yaml
