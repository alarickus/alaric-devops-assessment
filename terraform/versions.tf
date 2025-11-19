# Terraform and Provider Version Constraints
# This file explicitly defines all version requirements

terraform {
  # Terraform CLI version
  # ~> 1.6.0 allows 1.6.x (patch updates) but not 1.7.0
  required_version = "~> 1.6.0"  # Stable version - v1.6.6 tested and working
  
  # Required providers with pinned versions
  required_providers {
    # Azure Resource Manager provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"  # Stable version - v3.117.1 tested and working
    }
    
    # Random provider for generating unique strings
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"  # Pin to 3.6.x
    }
  }
}

# Version Upgrade Notes:
# 
# To upgrade Terraform:
# 1. Test in dev environment first
# 2. Update required_version
# 3. Run: terraform init -upgrade
# 4. Test thoroughly
# 5. Update staging, then prod
#
# To upgrade providers:
# 1. Check changelog for breaking changes
# 2. Update version constraint
# 3. Run: terraform init -upgrade
# 4. Test in dev
# 5. Promote through environments
#
# Current versions tested and validated:
# - Terraform: 1.6.x
# - azurerm: 3.85.x
# - random: 3.6.x
# - AKS Kubernetes: 1.28.3
