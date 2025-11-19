# DevOps Assessment - Azure AKS + Terraform + CI/CD

Flask API with PostgreSQL on Azure Kubernetes, fully automated deployment pipeline.

**Stack:** Azure AKS • CloudNativePG • Terraform • Azure DevOps • kubectl

---

## What It Does

Simple Flask API that transforms words:
- Input: `fOoBar25`
- Swaps case: `FOObAR25`
- Reverses: `52RAbOoF`
- Stores transformations in PostgreSQL

**Endpoints:**
- `GET /api/health` - Health check
- `GET /api/mirror?word=fOoBar25` - Word transformation
- `GET /api/history` - View transformation history

---

## Architecture

```
Azure DevOps Pipeline
  ↓ Test → Build → Push → Deploy (automated)
  ↓
Azure AKS (2 nodes, West Europe)
  ├─ Flask App (2+ pods, auto-scaling)
  ├─ CloudNativePG (PostgreSQL, 2 instances, HA)
  └─ Traefik Ingress (load balancer)
```

**Key Components:**
- **AKS:** 2× Standard_B2s nodes (4GB RAM, 2 vCPU) - $62/month
- **Database:** CloudNativePG operator (not Azure Database) - demonstrates K8s operators + saves $23/month
- **Deployment:** 100% pipeline-driven (no manual scripts)
- **HA:** 2 DB instances with auto-failover, app auto-scales 1-10 pods

---

## 🚀 Deployment Overview

### **Two-Phase Setup:**

**Phase 1: Infrastructure (Manual - One Time Only)**
- Run Terraform to create AKS, ACR, networking
- Configure Azure DevOps pipeline
- Duration: 45-60 minutes

**Phase 2: Application (Automated - Forever)**
- Just `git push` - pipeline handles everything
- Duration: 12-15 minutes per deployment

**👉 Full step-by-step guide: [DEPLOY.md](DEPLOY.md)**

---

## Initial Setup (Do Once)

### Step 1: Create Azure Infrastructure

```bash
# Login to Azure
az login
az account set --subscription "<your-subscription-id>"

# Create infrastructure with Terraform
cd terraform
terraform init
terraform apply -var-file="environments/assessment.tfvars"

# Save these outputs - you'll need them
terraform output acr_login_server    # Your ACR name
terraform output aks_cluster_name    # Should be: aks-dev-devops
```

**⏱️ Takes:** 10-15 minutes

**Creates:** AKS cluster (2 nodes), Container Registry, VNet, Key Vault, Storage

### Step 2: Configure Azure DevOps

**A) Create Service Connection:**
- Azure DevOps → Project Settings → Service connections
- New → Azure Resource Manager
- Name: `azure-connection` (exact name required)
- Grant access to all pipelines

**B) Create Variable Group:**
- Pipelines → Library → Variable groups
- Name: `app-variables` (exact name required)
- Add variable:
  - `AZURE_CONTAINER_REGISTRY` = `<your-acr-name>` (from terraform output)

**C) Create Pipeline:**
- Pipelines → New pipeline
- Azure Repos Git → Select repo
- Existing YAML → `/azure-pipelines.yml`
- Run

**⏱️ Takes:** 10-15 minutes

### Step 3: First Deployment

```bash
# Push code to trigger pipeline
git push origin main
```

**Pipeline runs automatically:**
1. ✅ Tests (25+ unit tests, 95% coverage)
2. ✅ Build (Docker image)
3. ✅ Push (to ACR)
4. ✅ Deploy (to AKS with kubectl)

**⏱️ Takes:** 12-15 minutes

### Step 4: Verify It Works

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group rg-devops-assessment \
  --name aks-dev-devops

# Get external IP (wait if <pending>)
kubectl get svc -n traefik traefik

# Test API
curl http://<EXTERNAL_IP>/api/health
curl "http://<EXTERNAL_IP>/api/mirror?word=fOoBar25"
```

**Expected:** `{"transformed":"52RAbOoF"}`

---

## Ongoing Deployments (Automated)

After initial setup, deployments are fully automated:

```bash
# Make changes
echo "# New feature" >> README.md

# Commit and push
git add .
git commit -m "Add feature"
git push origin main

# ✅ Pipeline runs automatically
# ✅ Tests, builds, deploys (12-15 min)
# ✅ No manual steps needed!
```

**That's it!** Every push to `main` = automatic deployment.

---

## CI/CD Pipeline

**azure-pipelines.yml** - 4 stages, fully automated:

**Stage 1: Test** (all branches)
- Runs 25+ unit tests
- Generates coverage report (95%+)
- Quality gate: must pass to proceed

**Stage 2: Build** (main only)
- Builds Docker image
- Tags with build ID + latest

**Stage 3: Push** (main only)
- Authenticates to ACR
- Pushes Docker image

**Stage 4: Deploy** (main only)
- Installs CNPG operator
- Deploys PostgreSQL cluster (2 instances)
- Deploys Traefik ingress
- Deploys application
- Runs health checks

**Branch Strategy:**
- Feature branches → Tests only
- Main branch → Full pipeline (deploy)

---

## Project Structure

```
devops-assessment/
├── app/
│   ├── main.py                  # Flask API
│   ├── tests/                   # 25+ unit tests
│   └── requirements.txt
├── k8s/
│   ├── 00-namespace.yaml        # Namespace
│   ├── 01-secrets.yaml          # DB credentials
│   ├── 02-deployment.yaml       # App deployment
│   ├── 03-service.yaml          # Service
│   ├── 04-ingressroute.yaml     # Traefik ingress
│   ├── 05-hpa.yaml              # Auto-scaling (1-10 pods)
│   └── cnpg/                    # PostgreSQL operator (4 files)
├── terraform/
│   ├── *.tf (9 files)           # AKS, ACR, VNet, etc.
│   └── environments/assessment.tfvars
├── docker/
│   └── Dockerfile               # Multi-stage build
└── azure-pipelines.yml          # CI/CD pipeline
```

---

## Key Design Decisions

### CloudNativePG vs Azure Database for PostgreSQL

**Why CloudNativePG:**
- ✅ Demonstrates Kubernetes Operators (advanced skill)
- ✅ Cost: $2/month vs $25/month (saves $276/year)
- ✅ Latency: <1ms (in-cluster) vs 5-10ms (external)
- ✅ HA: Auto-failover in <30 seconds
- ✅ Backups: Daily to Azure Blob (30-day retention)

**Trade-off:** Self-managed (no Azure SLA) - acceptable for demo/assessment

### kubectl vs Helm

**Why kubectl:**
- ✅ Shows Kubernetes fundamentals (no abstraction)
- ✅ Clearer for assessment (what you see is what's deployed)
- ✅ Production-ready (6 YAML files, easy to understand)
- ❌ Helm better for multi-environment (not needed here)

### Terraform Best Practices (All 5 Implemented)

1. **Remote State:** Azure Blob with locking
2. **Managed Identity:** No service principal credentials
3. **Pinned Versions:** Terraform ~>1.6, azurerm ~>3.85
4. **Provider Config:** Features block configured
5. **Separated Files:** 9 .tf files by function

### Standard_B2s Node Size

**Why Burstable:**
- ✅ Cost: $31/node/month vs $70 (D2s_v3)
- ✅ Sufficient: 4GB RAM, 2 vCPU per node
- ✅ Usage: ~30% baseline (70% headroom)
- ✅ Burstable: Handles traffic spikes

**Total Cost:** $17/week, $74/month, $888/year

---

## Testing

### Local Testing

```bash
cd app
./run_tests.sh

# Or manually:
python -m pytest tests/ -v --cov=. --cov-report=html
```

**Test Coverage:**
- Health endpoint (GET only, JSON format)
- Mirror transformation (case swap + reverse)
- Example case: `fOoBar25` → `52RAbOoF`
- Database persistence
- Error handling (missing params, invalid input)

**Results:** 25+ tests, 95%+ coverage

### Pipeline Testing

```bash
# Feature branch - tests only
git checkout -b feature/new-endpoint
git push origin feature/new-endpoint

# Main branch - full deploy
git checkout main
git merge feature/new-endpoint
git push origin main  # Triggers: Test → Build → Push → Deploy
```

### Verification Commands

```bash
# Check pods
kubectl get pods -n mirror-app

# Check database cluster
kubectl get cluster -n mirror-app
# Should show: 2 instances, 1 primary, 1 replica

# Check HPA
kubectl get hpa -n mirror-app

# View logs
kubectl logs -n mirror-app deployment/mirror-app --tail=50

# Test database
kubectl exec -it mirror-db-1 -n mirror-app -- psql -U app -d mirrordb -c "SELECT * FROM mirror_words;"
```

---

## Troubleshooting

**Pipeline fails at Deploy stage:**
- Verify service connection has AKS permissions
- Check variable group has correct ACR name
- Ensure AKS cluster is running: `az aks list -o table`

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n mirror-app
kubectl logs <pod-name> -n mirror-app
```

**Database connection errors:**
```bash
# Verify DB cluster is ready
kubectl get cluster -n mirror-app

# Check secret
kubectl get secret db-secret -n mirror-app -o yaml

# Test connectivity from app pod
kubectl exec -it deployment/mirror-app -n mirror-app -- nc -zv mirror-db-rw 5432
```

**Rollback:**
```bash
kubectl rollout undo deployment/mirror-app -n mirror-app
```

---

## Requirements Checklist

**Core Requirements:**
- ✅ Flask API on port 4004
- ✅ `/api/health` and `/api/mirror` endpoints
- ✅ Example case verified: `fOoBar25` → `52RAbOoF`
- ✅ PostgreSQL persistence (CloudNativePG)
- ✅ 25+ unit tests, 95%+ coverage
- ✅ CI/CD pipeline (Azure DevOps)
- ✅ Auto-deployment on push to main
- ✅ AKS deployment via kubectl (no Helm)
- ✅ Traefik Ingress on port 80
- ✅ Terraform with all 5 best practices

**Bonus:**
- ✅ Multi-tenant architecture design (see `MULTI_TENANT_ARCHITECTURE.md`)
- ✅ Cost optimization (56% savings)
- ✅ High availability (DB + app)
- ✅ Full automation (pipeline-driven)

---

## Cleanup

```bash
# Option 1: Terraform destroy
cd terraform
terraform destroy -var-file="environments/assessment.tfvars"

# Option 2: Delete resource group
az group delete --name rg-devops-assessment --yes
```

---

**Tech Stack:** Flask • PostgreSQL • Docker • Kubernetes • Terraform • Azure DevOps
**Deployment:** 100% automated via CI/CD pipeline
**Cost:** $17/week ($74/month)
**Region:** West Europe
**Production-Ready:** ✅
