# DevOps Assessment - Azure AKS + GitHub Actions

## Quick Start

1. Deploy infrastructure: See [DEPLOY.md](DEPLOY.md)
2. Test the app: See [TEST-THIS-APP.md](TEST-THIS-APP.md)

## Testing

Get external IP:
```bash
kubectl get svc -n traefik traefik
```

Test the API:
```bash
# Health check
curl http://<EXTERNAL_IP>/api/health

# Mirror transformation
curl "http://<EXTERNAL_IP>/api/mirror?word=fOoBar25"

# View history
curl http://<EXTERNAL_IP>/api/history
```

## Deployment

Application is deployed using Helm:
```bash
helm upgrade --install mirror-app ./helm/mirror-app \
  --namespace mirror-app \
  --wait
```

## Stack

- **Infrastructure**: Terraform (AKS, ACR, networking)
- **Application**: Helm Charts
- **Database**: PostgreSQL (CloudNativePG)
- **Ingress**: Traefik
- **CI/CD**: GitHub Actions
  - *Note: Azure DevOps initially attempted but blocked by "No hosted parallelism has been purchased or granted" message*
- **Runtime**: Flask API on port 4004
