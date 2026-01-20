# Kustomize GitOps Setup

This repository implements a GitOps workflow using Kustomize and ArgoCD for managing deployments across multiple environments (dev, staging, release).

## Directory Structure

```
yourrepo/
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── secret.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/
│       │   ├── kustomization.yaml
│       │   └── deployment-patch.yaml
│       ├── staging/
│       │   ├── kustomization.yaml
│       │   └── deployment-patch.yaml
│       └── release/
│           ├── kustomization.yaml
│           └── deployment-patch.yaml
├── argocd/
│   ├── app-dev.yaml
│   ├── app-staging.yaml
│   └── app-release.yaml
├── .github/
│   └── workflows/
│       └── ci-cd.yml
└── README.md
```

## Environments

Each environment (dev, staging, release) has its own Kustomize overlay that specifies:
- Different image tags for feature testing
- Environment-specific resource allocations
- Custom environment variables

### Image Tagging Strategy

- **Dev**: `feature-{n}-{commit-hash}` - For testing new features
- **Staging**: `feature-{n}-{commit-hash}` - For pre-production validation
- **Release**: `feature-{n}-{commit-hash}` - For production deployment

## ArgoCD Integration

ArgoCD applications are configured to:
- Pull manifests from the respective overlay directories
- Automatically sync changes
- Prune resources that are removed from the configuration

## CI/CD Workflow

The GitHub Actions workflow:
1. Builds and pushes container images to GHCR
2. Updates the appropriate kustomization files with new image tags
3. Deploys to each environment based on branch/push triggers

## Local Testing

To test the Kustomize configurations locally:

```bash
# Test dev environment
kustomize build k8s/overlays/dev

# Test staging environment
kustomize build k8s/overlays/staging

# Test release environment
kustomize build k8s/overlays/release
```