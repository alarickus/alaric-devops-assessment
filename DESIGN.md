# Architecture Design

## Overview

This project implements a production-ready Flask API on Azure Kubernetes Service (AKS) with automated CI/CD, database persistence, and Helm-based deployment.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Actions CI/CD                      │
│  [.github/workflows/deploy.yml]                                  │
│  Test → Build → Push to ACR → Deploy via Helm                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Container Registry                       │
│  alaric1.azurecr.io/mirror-app                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   Azure Kubernetes Service                        │
│                    (aks-alaric-devops)                           │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Namespace: mirror-app                                     │  │
│  │                                                            │  │
│  │  ┌─────────────────┐      ┌──────────────────────────┐  │  │
│  │  │ Traefik Ingress │──────│ mirror-app Service       │  │  │
│  │  │ (External IP)   │      │ ClusterIP:4004           │  │  │
│  │  └─────────────────┘      └──────────────────────────┘  │  │
│  │           │                         │                     │  │
│  │           │                         ↓                     │  │
│  │           │              ┌──────────────────────┐        │  │
│  │           │              │ mirror-app Pods      │        │  │
│  │           │              │ (2 replicas, HPA)    │        │  │
│  │           │              │ Flask API:4004       │        │  │
│  │           │              └──────────────────────┘        │  │
│  │           │                         │                     │  │
│  │           │                         ↓                     │  │
│  │           │              ┌──────────────────────┐        │  │
│  │           │              │ PostgreSQL (CNPG)    │        │  │
│  │           │              │ mirror-db (HA)       │        │  │
│  │           │              │ - Primary: mirror-db-1│       │  │
│  │           │              │ - Replica: mirror-db-2│       │  │
│  │           │              └──────────────────────┘        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↑
┌─────────────────────────────────────────────────────────────────┐
│                    Terraform Infrastructure                       │
│  [terraform/]                                                     │
│  - AKS Cluster                                                    │
│  - Virtual Network                                                │
│  - ACR Integration                                                │
│  - RBAC Configuration                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Links

### Infrastructure (Terraform)

**Main Configuration:**
- [`terraform/main.tf`](terraform/main.tf) - Main infrastructure definition
- [`terraform/variables.tf`](terraform/variables.tf) - Variable definitions
- [`terraform/outputs.tf`](terraform/outputs.tf) - Output values
- [`terraform/backend.tf`](terraform/backend.tf) - Remote state configuration

**Environment Configuration:**
- [`terraform/environments/assessment.tfvars`](terraform/environments/assessment.tfvars) - Assessment environment values

**Modules:**
- [`terraform/modules/aks/`](terraform/modules/aks/) - AKS cluster module
- [`terraform/modules/acr/`](terraform/modules/acr/) - Container registry module
- [`terraform/modules/networking/`](terraform/modules/networking/) - VNet and subnets

---

### Application Deployment (Helm)

**Helm Chart:**
- [`helm/mirror-app/Chart.yaml`](helm/mirror-app/Chart.yaml) - Chart metadata
- [`helm/mirror-app/values.yaml`](helm/mirror-app/values.yaml) - Default configuration values

**Templates:**
- [`helm/mirror-app/templates/deployment.yaml`](helm/mirror-app/templates/deployment.yaml) - Application deployment
- [`helm/mirror-app/templates/service.yaml`](helm/mirror-app/templates/service.yaml) - Service definition
- [`helm/mirror-app/templates/hpa.yaml`](helm/mirror-app/templates/hpa.yaml) - Horizontal Pod Autoscaler
- [`helm/mirror-app/templates/ingressroute.yaml`](helm/mirror-app/templates/ingressroute.yaml) - Traefik ingress
- [`helm/mirror-app/templates/secrets.yaml`](helm/mirror-app/templates/secrets.yaml) - Database credentials

---

### Database (CloudNativePG)

**CNPG Configuration:**
- [`k8s/00-namespace.yaml`](k8s/00-namespace.yaml) - Namespace definition
- [`k8s/cnpg/01-postgres-cluster.yaml`](k8s/cnpg/01-postgres-cluster.yaml) - PostgreSQL cluster (HA)
- [`k8s/cnpg/02-credentials.yaml`](k8s/cnpg/02-credentials.yaml) - Database credentials
- [`k8s/cnpg/03-scheduled-backup.yaml`](k8s/cnpg/03-scheduled-backup.yaml) - Backup schedule

---

### CI/CD Pipeline

**GitHub Actions:**
- [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) - Complete CI/CD workflow
  - Job 1: Test (pytest with coverage)
  - Job 2: Build & Push (Docker → ACR)
  - Job 3: Deploy (Helm → AKS)

---

### Application Code

**Flask Application:**
- [`app/main.py`](app/main.py) - Flask API implementation
- [`app/requirements.txt`](app/requirements.txt) - Python dependencies
- [`app/tests/test_app.py`](app/tests/test_app.py) - Unit tests (29 tests)

**Docker:**
- [`docker/Dockerfile`](docker/Dockerfile) - Multi-stage build with non-root user

---

### Documentation

**Main Documentation:**
- [`README.md`](README.md) - Quick start and overview
- [`DEPLOY.md`](DEPLOY.md) - Complete deployment guide
- [`TEST-THIS-APP.md`](TEST-THIS-APP.md) - Testing instructions with actual IPs
- [`BONUS_QUESTION.md`](BONUS_QUESTION.md) - Multi-tenant scaling strategy

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Infrastructure** | Terraform | Infrastructure as Code |
| **Container Orchestration** | Azure AKS | Kubernetes cluster (2 nodes) |
| **Container Registry** | Azure ACR | Docker image storage |
| **Application Deployment** | Helm Charts | Kubernetes package manager |
| **Database** | PostgreSQL + CNPG | HA database with replication |
| **Ingress** | Traefik | HTTP routing and load balancing |
| **CI/CD** | GitHub Actions | Automated testing and deployment |
| **Application** | Flask (Python 3.11) | REST API |
| **Monitoring** | HPA | CPU/Memory-based autoscaling |

---

## Resource Details

### AKS Cluster
- **Name:** aks-alaric-devops
- **Resource Group:** rg-devops-assessment
- **Node Count:** 2
- **Node Size:** Standard_B2s
- **Kubernetes Version:** 1.32.9

### Container Registry
- **Name:** alaric1.azurecr.io
- **Integration:** Attached to AKS for seamless pulling

### Application
- **Namespace:** mirror-app
- **Replicas:** 2 (min: 1, max: 3 via HPA)
- **Port:** 4004
- **External IP:** 20.76.75.231

### Database
- **Type:** PostgreSQL 14
- **Instances:** 2 (primary + replica)
- **Service:** mirror-db-rw (read-write), mirror-db-ro (read-only)
- **Database Name:** mirrordb

---

## Key Design Decisions

### 1. Helm for Application Deployment
- **Why:** Versioned releases, easy rollbacks, templated configuration
- **Alternative Considered:** Plain kubectl manifests (less maintainable)

### 2. CloudNativePG for Database
- **Why:** Kubernetes-native, HA with replication, automated backups
- **Alternative Considered:** External Azure Database for PostgreSQL (higher cost)

### 3. GitHub Actions over Azure DevOps
- **Why:** Azure DevOps blocked by parallelism limitations
- **Benefit:** Tighter integration with repository, simpler setup

### 4. Traefik as Ingress Controller
- **Why:** Dynamic configuration, CRDs for advanced routing
- **Alternative Considered:** NGINX Ingress (more complex config)

### 5. Multi-stage Docker Build
- **Why:** Smaller image size, security (non-root user)
- **Optimization:** Dependencies cached separately from app code

---

## Deployment Flow

```
Developer Push → GitHub Actions
                      ↓
                  Run Tests (pytest)
                      ↓
              Build Docker Image (multi-arch)
                      ↓
              Push to ACR (alaric1.azurecr.io)
                      ↓
         Deploy to AKS via Helm (namespace: mirror-app)
                      ↓
              Wait for Readiness Probes
                      ↓
            Verify Health Endpoint (/api/health)
                      ↓
                  Deployment Complete
```

---

## API Endpoints

| Endpoint | Method | Purpose | Example |
|----------|--------|---------|---------|
| `/api/health` | GET | Health check | `{"status":"ok"}` |
| `/api/mirror?word=<word>` | GET | Transform word | `fOoBar25` → `52RAbOoF` |
| `/api/history` | GET | View transformations | Returns JSON array |

**Base URL:** http://20.76.75.231

---

## Scaling Strategy

**Current (Single Tenant):**
- HPA: 1-3 replicas based on CPU/memory
- Database: 2 instances (primary + replica)
- Cost: ~$74/month

**Future (Multi-Tenant):**
See [`BONUS_QUESTION.md`](BONUS_QUESTION.md) for detailed multi-tenant architecture
- Namespace-level isolation per customer
- Shared cluster (cost reduction: 83%)
- Estimated: $12-25/customer

---

## Security Features

- Non-root container user (appuser:1000)
- Secrets managed via Kubernetes secrets
- Network policies (CNPG isolation)
- ACR integration (no image pull secrets needed)
- RBAC for AKS access control

---

## Monitoring & Observability

**Health Checks:**
- Liveness probe: `/api/health` (30s initial delay)
- Readiness probe: `/api/health` (10s initial delay)

**Autoscaling:**
- CPU threshold: 80%
- Memory threshold: 80%
- Scale: 1-3 replicas

**Database:**
- CNPG operator monitoring
- Automated backups (scheduled)
- Replication lag tracking

---

## Repository Structure

```
devops-assessment/
├── .github/workflows/      # CI/CD pipelines
│   └── deploy.yml
├── app/                    # Flask application
│   ├── main.py
│   ├── requirements.txt
│   └── tests/
├── docker/                 # Docker configuration
│   └── Dockerfile
├── helm/                   # Helm charts
│   └── mirror-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── k8s/                    # Kubernetes manifests
│   ├── 00-namespace.yaml
│   └── cnpg/              # Database configuration
├── terraform/              # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── environments/
│   └── modules/
├── README.md              # Quick start
├── DEPLOY.md              # Deployment guide
├── TEST-THIS-APP.md       # Testing guide
├── BONUS_QUESTION.md      # Scaling strategy
└── DESIGN.md              # This file
```

---

## Quick Links

**Get Started:**
1. [Deployment Guide](DEPLOY.md) - Step-by-step setup
2. [Testing Guide](TEST-THIS-APP.md) - Verify deployment
3. [GitHub Actions](https://github.com/alarickus/alaric-devops-assessment/actions) - View pipeline runs

**Configuration:**
- [Terraform Variables](terraform/environments/assessment.tfvars)
- [Helm Values](helm/mirror-app/values.yaml)
- [Workflow Config](.github/workflows/deploy.yml)

**Implementation:**
- [Flask App](app/main.py)
- [Dockerfile](docker/Dockerfile)
- [Database Cluster](k8s/cnpg/01-postgres-cluster.yaml)
