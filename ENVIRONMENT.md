# Environment Configuration

## Development Environment

### dev.env
```
ENVIRONMENT=development
CLIENT_IMAGE_TAG=latest-dev
SERVER_IMAGE_TAG=latest-dev
LOG_LEVEL=debug
MONITORING_ENABLED=true
ARGOCD_REPO_URL=https://github.com/bookify/devops-configs
ARGOCD_TARGET_REVISION=dev
ARGOCD_SYNC_POLICY=automated
KUBERNETES_NAMESPACE=bookify-dev
HELM_VALUES_FILE=values-dev.yaml
```

## Staging Environment

### staging.env
```
ENVIRONMENT=staging
CLIENT_IMAGE_TAG=latest-staging
SERVER_IMAGE_TAG=latest-staging
LOG_LEVEL=info
MONITORING_ENABLED=true
ARGOCD_REPO_URL=https://github.com/bookify/devops-configs
ARGOCD_TARGET_REVISION=staging
ARGOCD_SYNC_POLICY=automated
KUBERNETES_NAMESPACE=bookify-staging
HELM_VALUES_FILE=values-staging.yaml
```

## Production Environment

### prod.env
```
ENVIRONMENT=production
CLIENT_IMAGE_TAG=v1.0.0
SERVER_IMAGE_TAG=v1.0.0
LOG_LEVEL=warn
MONITORING_ENABLED=true
ARGOCD_REPO_URL=https://github.com/bookify/devops-configs
ARGOCD_TARGET_REVISION=main
ARGOCD_SYNC_POLICY=automated
KUBERNETES_NAMESPACE=bookify-prod
HELM_VALUES_FILE=values-prod.yaml
ARGOCD_SYNC_OPTIONS=Prune=true,SelfHeal=true,Validate=true
```

## Docker Environment File

### .env
```
# General Settings
PROJECT_NAME=bookify
REGISTRY_URL=registry.bookify.com
IMAGE_PULL_POLICY=Always

# Kubernetes Settings
CLUSTER_NAME=bookify-cluster
REGION=us-west-2
NODE_COUNT=3
NODE_SIZE=t3.medium

# ArgoCD Settings
ARGOCD_NAMESPACE=argocd
ARGOCD_ADMIN_PASSWORD=admin123  # Replace with secure password in production
ARGOCD_HOST=argocd.bookify.com

# Monitoring Settings
PROMETHEUS_RETENTION=30d
GRAFANA_HOST=grafana.bookify.com
ALERT_MANAGER_HOST=alertmanager.bookify.com

# Security Settings
TLS_ENABLED=true
TLS_CERT_SECRET=tls-certificate
IMAGE_SCANNING_ENABLED=true
VULNERABILITY_THRESHOLD=critical

# Database Settings
DATABASE_HOST=postgres.bookify.svc.cluster.local
DATABASE_PORT=5432
DATABASE_SSLMODE=require

# Cache Settings
REDIS_HOST=redis.bookify.svc.cluster.local
REDIS_PORT=6379

# Other Services
JENKINS_HOST=jenkins.bookify.com
SONARQUBE_HOST=sonarqube.bookify.com
VAULT_HOST=vault.bookify.com
```

## Kubernetes ConfigMap Template

### configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: bookify-config
  namespace: {{ .Values.namespace }}
data:
  ENVIRONMENT: {{ .Values.environment | quote }}
  LOG_LEVEL: {{ .Values.logLevel | quote }}
  DATABASE_HOST: {{ .Values.database.host | quote }}
  REDIS_HOST: {{ .Values.redis.host | quote }}
  API_URL: {{ .Values.api.url | quote }}
  JWT_SECRET_NAME: {{ .Values.jwt.secretName | quote }}
  SENTRY_DSN: {{ .Values.sentry.dsn | quote }}
  ANALYTICS_ID: {{ .Values.analytics.id | quote }}
```