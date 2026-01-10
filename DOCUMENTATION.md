# Bookify DevSecOps Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Directory Structure](#directory-structure)
4. [Deployment Process](#deployment-process)
5. [Monitoring and Observability](#monitoring-and-observability)
6. [Security Practices](#security-practices)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance](#maintenance)

## Project Overview

The Bookify DevSecOps platform implements a comprehensive continuous integration and continuous delivery (CI/CD) pipeline with integrated security practices. The platform follows GitOps principles using ArgoCD for declarative, version-controlled infrastructure and application deployment.

### Core Principles
- Infrastructure as Code (IaC)
- GitOps methodology
- Security by design
- Observability-first approach
- Automated compliance

## Architecture

### Components Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git Repository│────│   ArgoCD        │────│   Kubernetes    │
│                 │    │                 │    │                 │
│  ├── Dev/       │    │  ├── App Sync   │    │  ├── Client     │
│  ├── Monitoring │    │  ├── Health     │    │  ├── Server     │
│  └── Docs/      │    │  └── Rollbacks  │    │  └── Monitoring │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack
- **Version Control**: Git with GitHub/GitLab
- **Container Orchestration**: Kubernetes
- **GitOps Tool**: ArgoCD
- **Container Runtime**: Docker
- **Monitoring**: Prometheus, Grafana, AlertManager
- **Security Scanning**: Trivy, SonarQube, OWASP ZAP
- **CI/CD Pipeline**: Jenkins, GitHub Actions, or GitLab CI

## Directory Structure

### Root Directory
```
DevSecOps/
├── README.md                 # Project overview and usage instructions
├── SETUP.md                  # Detailed setup instructions
├── ENVIRONMENT.md            # Environment configuration details
├── DOCUMENTATION.md          # Comprehensive documentation
├── SECURITY.md               # Security practices and policies
├── BACKUP.md                 # Backup and disaster recovery procedures
├── Dev/
│   ├── argo-app.yaml         # ArgoCD application definition
│   ├── app_project.yaml      # ArgoCD project configuration
│   ├── list_generator.yaml   # ArgoCD list generator
│   ├── client/
│   │   ├── deployment.yaml   # Client application deployment
│   │   └── service.yaml      # Client service configuration
│   └── server/
│       ├── deployment.yaml   # Server application deployment
│       └── service.yaml      # Server service configuration
└── monitoring/
    └── argocd-service-monitors.yaml  # Prometheus service monitors
```

### Dev Directory
The `Dev/` directory contains all application deployment configurations:

- **argo-app.yaml**: Defines the ArgoCD application with source repository and target destination
- **app_project.yaml**: Defines ArgoCD project with namespace and cluster access rules
- **list_generator.yaml**: Configuration for list-based application generation
- **client/**: Contains client-side deployment and service configurations
- **server/**: Contains server-side deployment and service configurations

### Monitoring Directory
The `monitoring/` directory contains service monitoring configurations:

- **argocd-service-monitors.yaml**: Service monitors for ArgoCD components to be scraped by Prometheus

## Deployment Process

### GitOps Workflow
1. Application manifests are stored in version control
2. ArgoCD continuously monitors the repository for changes
3. When changes are detected, ArgoCD syncs the live cluster state with the desired state
4. Health checks ensure successful deployment
5. Rollbacks occur automatically if health checks fail

### Deployment Steps
1. **Prepare Manifests**: Ensure all Kubernetes manifests are in the source repository
2. **Create Application**: Apply the ArgoCD application manifest
3. **Monitor Sync**: Verify the application syncs successfully
4. **Validate Health**: Check that all resources are healthy
5. **Promote**: Deploy to next environment when validated

### ArgoCD Application Configuration
The `argo-app.yaml` file defines:
- Source repository and revision
- Destination cluster and namespace
- Sync policy (automated/manual)
- Health assessment criteria
- Resource pruning policies

## Monitoring and Observability

### Metrics Collection
- Application performance metrics
- Infrastructure resource utilization
- Request latency and error rates
- Resource health status

### Service Monitors
The `argocd-service-monitors.yaml` file defines:
- Endpoints to scrape for metrics
- Labels for service discovery
- Scrape intervals and timeouts
- Metric relabeling configurations

### Alerting
- Predefined alert rules for critical conditions
- Notification channels for operations team
- Escalation procedures for unresolved issues
- Automated remediation where possible

## Security Practices

### Image Scanning
- Automated scanning of container images
- Vulnerability assessment and reporting
- Policy enforcement for critical vulnerabilities
- Integration with CI/CD pipeline

### Access Control
- Role-based access control (RBAC)
- Least privilege principle
- Audit logging for access and changes
- Regular access reviews

### Secrets Management
- External secrets management (HashiCorp Vault or similar)
- No hardcoded credentials in configuration files
- Automated rotation of secrets
- Encrypted storage and transmission

## Troubleshooting

### Common Issues
1. **Sync Failures**: Check repository access and manifest validity
2. **Health Checks**: Verify application dependencies and resource availability
3. **Monitoring Gaps**: Ensure service selectors match deployed applications
4. **Permission Issues**: Verify RBAC rules and service account permissions

### Diagnostic Commands
```bash
# Check ArgoCD application status
argocd app get <app-name>

# View application resources
kubectl get applications -n argocd

# Check events for issues
kubectl get events --sort-by=.metadata.creationTimestamp

# View logs for specific pods
kubectl logs <pod-name> -n <namespace>
```

### Debugging Process
1. Identify the failing component
2. Check logs and events
3. Verify configurations and permissions
4. Test connectivity between components
5. Validate configuration syntax
6. Implement fixes and verify resolution

## Maintenance

### Regular Tasks
- Update base images and dependencies
- Review and rotate secrets
- Audit access permissions
- Update security policies
- Verify backup integrity

### Backup Procedures
- Kubernetes resources backup
- Persistent volume snapshots
- Git repository backups
- ArgoCD application states

### Upgrade Process
1. Test upgrades in development environment
2. Create backup before applying updates
3. Apply updates during maintenance windows
4. Validate functionality after updates
5. Roll back if critical issues arise