# Bonus Question: Scaling to Multiple Customers

## The Problem

Current setup is hardcoded for one customer. Serving 10 customers by copying everything 10 times = management nightmare and exploding costs.

**Cost impact:**
- Single-tenant: $74/month per customer
- Multi-tenant (10 customers): $12/customer (83% savings)

---

## Solution: Multi-Tenant Architecture

### Core Approach

Use **namespace-level isolation** in a shared AKS cluster:
- Each customer = separate Kubernetes namespace
- Shared infrastructure, isolated resources
- Scale from 10 to 100 customers without rewrites

---

## Key Improvements

### 1. Infrastructure (Terraform)

**Current:** Monolithic, hardcoded for one customer

**Needed:**
- Modular Terraform (reusable customer module)
- Per-customer config files
- Variables for tier sizing (small/medium/large)

**Result:** Onboard new customer in 10 minutes vs 2-4 hours

### 2. Isolation

Each namespace needs:
- **Resource quotas** - CPU, memory, storage limits
- **Network policies** - Block cross-namespace traffic
- **Dedicated database** - Own CNPG PostgreSQL cluster
- **RBAC** - Customers only access their resources

### 3. Automation

**Onboarding:**
- Script to create namespace, deploy resources
- Input: customer name, tier, domain
- Output: Live instance in 10 minutes

**CI/CD:**
- Parameterized pipeline (deploy to specific namespace)
- Progressive rollout: canary → 10% → 50% → 100%
- Auto-rollback on health check failure

**Config Management:**
- Global defaults
- Tier-specific overrides
- Customer-specific customizations

### 4. Operations

**Monitoring:**
- Per-namespace metrics and logs
- Customer-isolated dashboards
- Route alerts to customer-specific channels

**Cost Tracking:**
- Tag all resources with customer/tier labels
- Azure Cost Management + Kubecost
- Automated per-customer billing

**Security:**
- Network policies blocking inter-namespace traffic
- Separate secrets per namespace
- Compliance tags (HIPAA, GDPR)
