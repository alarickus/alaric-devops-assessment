# Assessment Environment Configuration
# File: environments/assessment.tfvars
# This file contains configuration values for the DevOps assessment

# Resource naming
resource_group_name = "rg-devops-assessment"
environment        = "alaric"  # Using 'alaric' for assessment purposes

# Location
location = "westeurope"

# Container Registry
acr_name = "alaric1"  # Globally unique name (alphanumeric only, no hyphens)

# AKS Configuration
enable_aks     = true
aks_node_count = 2
aks_node_size  = "Standard_B2s"  # Cost-effective: 2 vCPU, 4GB RAM, ~$30/month/node

# Disable VM
enable_vm = false

# Tags for resource organization and cost tracking
tags = {
  Project     = "DevOps-Assessment"
  Environment = "Assessment"
  ManagedBy   = "Terraform"
  Owner       = "Candidate"
  Database    = "CloudNativePG"
  Purpose     = "Technical-Assessment"
}

# Notes:
# 1. ACR name must be globally unique - add random suffix if needed
# 2. Database runs via CloudNativePG operator (no external DB)
# 3. Using Standard_B2s nodes for cost optimization ($17/week)
# 4. All secrets managed via Azure AD and Kubernetes Secrets
