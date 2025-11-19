# Testing Guide

**External IP**: `<EXTERNAL_IP>`

## API Tests

```bash
# Health check
curl http://<EXTERNAL_IP>/api/health
# Expected: {"status":"ok"}

# Mirror transformation (required example)
curl "http://<EXTERNAL_IP>/api/mirror?word=fOoBar25"
# Expected: {"transformed":"52RAbOoF"}

# View history
curl http://<EXTERNAL_IP>/api/history
```

## More Examples

```bash
curl "http://<EXTERNAL_IP>/api/mirror?word=hello"
# Expected: {"transformed":"OLLEH"}

curl "http://<EXTERNAL_IP>/api/mirror?word=ABC"
# Expected: {"transformed":"cba"}
```

## Browser Testing

- http://<EXTERNAL_IP>/api/health
- http://<EXTERNAL_IP>/api/mirror?word=fOoBar25
- http://<EXTERNAL_IP>/api/history

## Infrastructure Check

```bash
# Check pods
kubectl get pods -n mirror-app

# Check database
kubectl get cluster -n mirror-app

# Check autoscaling
kubectl get hpa -n mirror-app
```

## Database Query

```bash
kubectl run psql-query --image=postgres:14 --rm -i --restart=Never \
  -n mirror-app --env="PGPASSWORD=AppUser_SecurePassword123!" \
  -- psql -h mirror-db-rw -U app -d mirrordb \
  -c "SELECT * FROM mirror_words ORDER BY created_at DESC LIMIT 5;"
```

## Troubleshooting

```bash
# Check logs
kubectl logs -n mirror-app deployment/mirror-app --tail=50

# Restart app
kubectl rollout restart deployment/mirror-app -n mirror-app
```

## GitHub Actions

https://github.com/alarickus/alaric-devops-assessment/actions
