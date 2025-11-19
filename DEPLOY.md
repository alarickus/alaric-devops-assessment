# Step-by-Step Deployment Guide

Complete guide to deploy this project to your Azure subscription.

---

## 📋 Deployment Overview

### **What You'll Do:**

**ONE-TIME SETUP (Parts 1-7):** ~45-60 minutes
- Create Azure infrastructure with Terraform
- Configure Azure DevOps pipeline
- First deployment

**ONGOING (Part 9):** ~12-15 minutes per deployment
- Just `git push` - everything else is automatic!

### **Manual vs Automated:**

| What | How | Frequency |
|------|-----|-----------|
| **Infrastructure** (AKS, ACR, VNet) | Manual - Terraform | Once |
| **Pipeline Setup** | Manual - Azure DevOps | Once |
| **Application Deployment** | Automated - CI/CD | Every push |

### **After Initial Setup:**
```bash
git push origin main  # That's it! Pipeline does everything
```

---

## Prerequisites

### Required Tools:
- **Azure CLI** - [Install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Terraform** (>= 1.6.0) - [Install](https://developer.hashicorp.com/terraform/downloads)
- **kubectl** (>= 1.28) - [Install](https://kubernetes.io/docs/tasks/tools/)
- **Git** - [Install](https://git-scm.com/downloads)

### Required Accounts:
- **Azure subscription** with Owner/Contributor access
- **Azure DevOps** organization

### Verify installations:
```bash
az --version
terraform --version
kubectl version --client
git --version
```

---

## Part 1: Azure Login & Setup

### Step 1.1: Login to Azure

```bash
# Login to Azure
az login

# List your subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "<your-subscription-id>"

# Verify
az account show
```

### Step 1.2: Create Service Principal (for Terraform)

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal
az ad sp create-for-rbac \
  --name "sp-alaric-devops-assessment" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID

# Save the output - you'll need:
# - appId (client ID)
# - password (client secret)
# - tenant
```

**⚠️ Important:** Save these credentials securely! You'll need them for Terraform.

### Step 1.3: Set Environment Variables

```bash
# Replace with your values from previous step
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<tenant>"

# Verify
echo $ARM_CLIENT_ID
```

---

## Part 2: Terraform Backend Setup

### Step 2.1: Create Backend Storage

```bash
# Create resource group for Terraform state
az group create \
  --name rg-terraform-state \
  --location westeurope

# Create storage account (must be globally unique)
RANDOM_SUFFIX=$RANDOM
az storage account create \
  --name sttfstate${RANDOM_SUFFIX} \
  --resource-group rg-terraform-state \
  --location westeurope \
  --sku Standard_LRS \
  --encryption-services blob

# Save the storage account name
echo "Storage Account: sttfstate${RANDOM_SUFFIX}"

# Create container
az storage container create \
  --name tfstate \
  --account-name sttfstate${RANDOM_SUFFIX} \
  --auth-mode login
```

### Step 2.2: Update Terraform Backend Configuration

```bash
cd terraform

# Edit backend.tf - update the storage_account_name
nano backend.tf
# Change: storage_account_name = "sttfstate<YOUR_SUFFIX>"
```

Or use sed:
```bash
cd terraform
sed -i '' 's/storage_account_name = ".*"/storage_account_name = "sttfstate'${RANDOM_SUFFIX}'"/' backend.tf
```

---

## Part 3: Configure Terraform Variables

### Step 3.1: Update ACR Name (Must Be Globally Unique)

```bash
cd terraform/environments

# Edit assessment.tfvars
nano assessment.tfvars

# Update this line with a unique name:
# acr_name = "acrdevopsYOURNAME"  # Must be globally unique, lowercase, no hyphens
```

Example:
```hcl
acr_name = "acrdevopsjohn123"  # Use your name + numbers
```

---

## Part 4: Deploy Infrastructure with Terraform

### Step 4.1: Initialize Terraform

```bash
cd terraform

# Initialize (downloads providers, connects to backend)
terraform init

# Should see: "Terraform has been successfully initialized!"
```

### Step 4.2: Review Plan

```bash
# See what will be created
terraform plan -var-file="environments/assessment.tfvars"

# Review the output - should create:
# - Resource group
# - Virtual network
# - AKS cluster (2 nodes)
# - Container registry
# - Key Vault
# - Storage account (for DB backups)
```

### Step 4.3: Apply Infrastructure

```bash
# Deploy (takes ~10-15 minutes)
terraform apply -var-file="environments/assessment.tfvars"

# Type 'yes' when prompted

# ☕ Wait for completion...
```

### Step 4.4: Save Outputs

```bash
# Get important values
terraform output

# Save these values:
terraform output acr_login_server    # Example: acrdevopsjohn123.azurecr.io
terraform output aks_cluster_name    # Should be: aks-dev-devops
terraform output resource_group_name # Should be: rg-devops-assessment
```

**⚠️ Save these values - you'll need them for Azure DevOps!**

---

## Part 5: Configure kubectl Access

### Step 5.1: Get AKS Credentials

```bash
# Get credentials
az aks get-credentials \
  --resource-group rg-devops-assessment \
  --name aks-dev-devops \
  --overwrite-existing

# Verify connection
kubectl get nodes

# Should see 2 nodes in Ready state
```

---

## Part 6: Azure DevOps Setup

### Step 6.1: Create Azure DevOps Organization (if needed)

1. Go to https://dev.azure.com
2. Sign in with your Microsoft account
3. Create organization (if you don't have one)
4. Create a new project: `devops-assessment`

### Step 6.2: Push Code to Azure DevOps

```bash
# Initialize git (if not already done)
cd /path/to/devops-assessment
git init

# Add remote (get this URL from Azure DevOps)
# Azure DevOps → Repos → Files → Clone
git remote add origin https://dev.azure.com/<your-org>/devops-assessment/_git/devops-assessment

# Add all files
git add .

# Commit
git commit -m "Initial commit: DevOps assessment"

# Push
git push -u origin main
```

### Step 6.3: Create Service Connection

1. Azure DevOps → Project Settings (bottom left)
2. Pipelines → Service connections
3. Click "New service connection"
4. Select "Azure Resource Manager"
5. Click "Next"
6. Authentication method: "Service principal (automatic)"
7. Scope level: "Subscription"
8. Select your subscription
9. Resource group: Leave empty (full subscription access)
10. Service connection name: `azure-connection`
11. Check "Grant access permission to all pipelines"
12. Click "Save"

**⚠️ Important:** The name must be exactly `azure-connection` (the pipeline expects this).

### Step 6.4: Create Variable Group

1. Azure DevOps → Pipelines → Library
2. Click "+ Variable group"
3. Variable group name: `app-variables`
4. Add variables:
   - Name: `AZURE_CONTAINER_REGISTRY`
   - Value: `<your-acr-name>` (just the name, not full URL)
   - Example: `acrdevopsjohn123`
5. Click "Save"

**⚠️ Important:**
- Variable group name must be exactly `app-variables`
- Use only the ACR name (from terraform output, without .azurecr.io)

### Step 6.5: Create Pipeline

1. Azure DevOps → Pipelines → Pipelines
2. Click "New pipeline" or "Create Pipeline"
3. Where is your code? → "Azure Repos Git"
4. Select your repository: `devops-assessment`
5. Configure your pipeline: "Existing Azure Pipelines YAML file"
6. Branch: `main`
7. Path: `/azure-pipelines.yml`
8. Click "Continue"
9. Review the pipeline YAML
10. Click "Run"

---

## Part 7: First Deployment

### Step 7.1: Monitor Pipeline

1. Pipeline starts automatically
2. Watch the 4 stages:
   - ✅ **Stage 1: Test** (runs on all branches)
   - ✅ **Stage 2: Build** (builds Docker image)
   - ✅ **Stage 3: Push** (pushes to ACR)
   - ✅ **Stage 4: Deploy** (deploys to AKS)

**Duration:** 12-15 minutes

### Step 7.2: Pipeline Progress

Watch for:
- Tests passing (25+ tests)
- Docker image built
- Image pushed to ACR
- CNPG operator installed
- PostgreSQL cluster deployed
- Application deployed
- Health checks passing

---

## Part 8: Verify Deployment

### Step 8.1: Check Kubernetes Resources

```bash
# Check all pods are running
kubectl get pods -n mirror-app

# Should see:
# - mirror-app-xxx (2 replicas)
# - mirror-db-1 (PostgreSQL primary)
# - mirror-db-2 (PostgreSQL replica)

# Check database cluster
kubectl get cluster -n mirror-app

# Check services
kubectl get svc -n mirror-app
kubectl get svc -n traefik
```

### Step 8.2: Get External IP

```bash
# Get load balancer IP
kubectl get svc -n traefik traefik

# Wait until EXTERNAL-IP shows (not <pending>)
# May take 2-3 minutes for Azure to assign IP

# Save the IP
EXTERNAL_IP=$(kubectl get svc -n traefik traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP: $EXTERNAL_IP"
```

### Step 8.3: Test API Endpoints

```bash
# Test health endpoint
curl http://$EXTERNAL_IP/api/health

# Expected: {"status":"ok"}

# Test mirror transformation
curl "http://$EXTERNAL_IP/api/mirror?word=fOoBar25"

# Expected: {"transformed":"52RAbOoF"}

# Test history
curl http://$EXTERNAL_IP/api/history

# Expected: JSON array with transformations
```

### Step 8.4: Test in Browser

Open in your browser:
- http://YOUR_EXTERNAL_IP/api/health
- http://YOUR_EXTERNAL_IP/api/mirror?word=fOoBar25

---

## Part 9: Continuous Deployment (Automated - This is What You'll Do Forever)

**🎉 Setup complete! From now on, deployments are fully automated.**

Every time you push to `main`, the pipeline automatically:
- ✅ Runs all tests
- ✅ Builds Docker image
- ✅ Pushes to ACR
- ✅ Deploys to AKS
- ✅ Verifies health checks

**Duration:** 12-15 minutes per deployment

---

### Step 9.1: Make a Change

```bash
# Edit something (e.g., README)
echo "# Test deployment" >> README.md

# Commit and push
git add README.md
git commit -m "Test: trigger pipeline"
git push origin main
```

### Step 9.2: Watch Auto-Deployment

1. Go to Azure DevOps → Pipelines
2. Pipeline starts automatically
3. All 4 stages run
4. Application updates automatically

**That's it!** Any push to `main` triggers full deployment.

---

## Part 10: Verify Everything Works

### Step 10.1: Database Persistence

```bash
# Make several requests
curl "http://$EXTERNAL_IP/api/mirror?word=hello"
curl "http://$EXTERNAL_IP/api/mirror?word=world"
curl "http://$EXTERNAL_IP/api/mirror?word=azure"

# Check history
curl http://$EXTERNAL_IP/api/history

# Should show all 3 transformations
```

### Step 10.2: Check Database Directly

```bash
# Connect to PostgreSQL
kubectl exec -it mirror-db-1 -n mirror-app -- psql -U app -d mirrordb

# Inside psql:
SELECT * FROM mirror_words;

# You should see all transformations
# Exit: \q
```

### Step 10.3: Check Auto-Scaling

```bash
# Check HPA
kubectl get hpa -n mirror-app

# Should show current replicas (min: 1, max: 10)
```

---

## Troubleshooting

### Issue: Pipeline fails at Deploy stage

**Check:**
```bash
# Verify service connection has permissions
az aks list -o table

# Verify variable group
# Azure DevOps → Library → app-variables
```

### Issue: Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n mirror-app

# Check logs
kubectl logs <pod-name> -n mirror-app

# Common issues:
# - ImagePullBackOff: ACR authentication issue
# - CrashLoopBackOff: Application error
```

### Issue: Can't pull image from ACR

```bash
# Verify ACR integration
az aks check-acr \
  --name aks-dev-devops \
  --resource-group rg-devops-assessment \
  --acr <your-acr-name>.azurecr.io
```

### Issue: Database not ready

```bash
# Check CNPG cluster
kubectl get cluster -n mirror-app

# Check operator logs
kubectl logs -n cnpg-system deployment/cnpg-controller-manager
```

---

## Cleanup (When Done)

### Option 1: Terraform Destroy

```bash
cd terraform
terraform destroy -var-file="environments/assessment.tfvars"

# Type 'yes' to confirm

# Also delete state storage
az group delete --name rg-terraform-state --yes
```

### Option 2: Azure Portal

```bash
# Delete resource groups
az group delete --name rg-devops-assessment --yes --no-wait
az group delete --name rg-terraform-state --yes --no-wait
```

---

## Quick Reference

### Essential Commands

```bash
# View all resources
kubectl get all -n mirror-app

# View logs
kubectl logs -n mirror-app deployment/mirror-app --tail=50 -f

# Restart deployment
kubectl rollout restart deployment/mirror-app -n mirror-app

# Check database
kubectl exec -it mirror-db-1 -n mirror-app -- psql -U app -d mirrordb

# Get external IP
kubectl get svc -n traefik traefik
```

### URLs to Keep Handy

- **Azure Portal:** https://portal.azure.com
- **Azure DevOps:** https://dev.azure.com/<your-org>
- **Your API:** http://<EXTERNAL_IP>/api/health

---

## Cost Estimate

**Running costs:**
- AKS: ~$62/month (2× Standard_B2s nodes)
- Storage: ~$5/month (disks + backups)
- Network: ~$5/month (load balancer)
- **Total: ~$72/month (~$17/week)**

**💡 Tip:** Delete resources when not in use to save costs!

---

## Success Checklist

✅ Azure subscription set up
✅ Service principal created
✅ Terraform backend created
✅ Infrastructure deployed (terraform apply)
✅ kubectl connected to AKS
✅ Code pushed to Azure DevOps
✅ Service connection created (`azure-connection`)
✅ Variable group created (`app-variables`)
✅ Pipeline created and run
✅ All 4 pipeline stages passed
✅ Pods running in AKS
✅ External IP assigned
✅ API endpoints responding
✅ Database persisting data

**If all checked ✅ - YOU'RE DONE!** 🎉

---

**Total Time:** ~45-60 minutes (first time)
**Subsequent deployments:** 12-15 minutes (automatic)
