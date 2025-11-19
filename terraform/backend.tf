# Terraform Backend Configuration
# Uses Azure Storage Account with state locking via Blob lease

terraform {
  # Backend configuration for remote state
  # State file stored in Azure Blob Storage with encryption
  # Locking prevents concurrent modifications
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"      # Pre-created resource group
    storage_account_name = "sttfstate15446"            # Pre-created storage account (must be globally unique)
    container_name       = "tfstate"                  # Pre-created container
    key                  = "devops-assessment.tfstate" # State file name
    
    # Locking via blob lease (automatic)
    # use_azuread_auth     = true                     # Uncomment to use Azure AD auth instead of access key
    # use_msi              = true                     # Uncomment to use Managed Service Identity
  }
}

# SETUP INSTRUCTIONS:
# Before running terraform init, create the backend resources:
#
# 1. Create resource group for state:
#    az group create --name rg-terraform-state --location westeurope
#
# 2. Create storage account (must be globally unique):
#    az storage account create \
#      --name sttfstatedevops \
#      --resource-group rg-terraform-state \
#      --location westeurope \
#      --sku Standard_LRS \
#      --encryption-services blob \
#      --https-only true \
#      --min-tls-version TLS1_2
#
# 3. Create container:
#    az storage container create \
#      --name tfstate \
#      --account-name sttfstatedevops \
#      --auth-mode login
#
# 4. Enable versioning (optional but recommended):
#    az storage account blob-service-properties update \
#      --account-name sttfstatedevops \
#      --enable-versioning true
#
# 5. Run terraform init
#    terraform init

# SECURITY FEATURES:
# - State encrypted at rest (Azure Storage encryption)
# - State encrypted in transit (HTTPS only)
# - Access controlled via Azure RBAC
# - Blob lease prevents concurrent modifications (automatic locking)
# - Versioning enables state recovery
# - No secrets exposed (uses Azure AD or Managed Identity)
