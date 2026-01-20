# Production-Grade Terraform for Bookify EKS Infrastructure

This directory contains enterprise-grade Terraform configurations for deploying AWS EKS clusters across multiple environments (dev, staging, prod).

## Directory Structure

```
Terraform/
├── provider.tf                 # Provider and plugin configurations
├── variables.tf               # Input variables definitions
├── outputs.tf                 # Output values
├── locals.tf                  # Local values and data sources
├── data.tf                    # Data sources
├── vpc.tf                     # VPC and networking configuration
├── eks.tf                     # EKS cluster and node groups
├── iam-policies.tf           # IAM policies for add-ons
├── backend.tf                # State management (S3 + DynamoDB)
├── environments/
│   ├── dev.tfvars            # Development environment variables
│   ├── staging.tfvars        # Staging environment variables
│   └── prod.tfvars           # Production environment variables
├── deploy.sh                 # Deployment automation script
└── README.md                 # This file
```

## Quick Start

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI >= 2.0
- kubectl >= 1.24
- AWS credentials configured
- jq (optional, for JSON parsing)

Install prerequisites:

```bash
# macOS
brew install terraform awscli kubectl jq

# Ubuntu/Debian
sudo apt-get install terraform awscli kubectl jq

# Verify installations
terraform version
aws --version
kubectl version --client
```

### Deployment Options

#### Option 1: Using the Deploy Script (Recommended)

```bash
# Make the script executable
chmod +x deploy.sh

# Initialize Terraform
./deploy.sh init dev

# Validate configuration
./deploy.sh validate

# Plan deployment
./deploy.sh plan dev

# Apply configuration
./deploy.sh apply dev

# Full deployment (init -> validate -> plan -> apply -> configure kubectl)
./deploy.sh full-deploy dev

# Configure kubectl
./deploy.sh configure dev

# View outputs
./deploy.sh output dev

# Destroy infrastructure
./deploy.sh destroy dev
```

#### Option 2: Manual Deployment

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format files
terraform fmt -recursive

# Plan deployment for specific environment
terraform plan -var-file="environments/dev.tfvars" -out=tfplan.dev

# Apply configuration
terraform apply tfplan.dev

# Get outputs
terraform output

# Configure kubectl
aws eks update-kubeconfig --name bookify-dev-cluster --region ap-south-1
kubectl get nodes
```

## Configuration

### Environment Variables

Each environment has its own `.tfvars` file in the `environments/` directory:

#### Development (`dev.tfvars`)

- **Features**: Cost-optimized, single NAT Gateway, SPOT instances
- **Node Groups**: Single general purpose node group (t3.medium)
- **HA**: Not enabled
- **Monitoring**: Enabled with 7-day log retention
- **Best for**: Development and testing

#### Staging (`staging.tfvars`)

- **Features**: Multi-AZ, production-like configuration
- **Node Groups**: General + optional GPU nodes
- **HA**: Partial (2 AZs)
- **Monitoring**: Enabled with 14-day log retention
- **Best for**: Pre-production testing and QA

#### Production (`prod.tfvars`)

- **Features**: High availability, multi-AZ, comprehensive monitoring
- **Node Groups**: System + Application + GPU nodes with automatic scaling
- **HA**: Full (3 AZs)
- **Monitoring**: Enabled with 90-day log retention for compliance
- **Best for**: Production workloads

### Custom Variables

To customize a deployment, either:

1. **Create a new `.tfvars` file**:

```bash
cp environments/dev.tfvars environments/custom.tfvars
# Edit custom.tfvars
terraform plan -var-file="environments/custom.tfvars"
```

2. **Pass variables via CLI**:

```bash
terraform plan \
  -var-file="environments/dev.tfvars" \
  -var="cluster_version=1.29" \
  -var="enable_kms_encryption=true"
```

3. **Edit variable defaults in `variables.tf`**:

```hcl
variable "cluster_version" {
  default = "1.29"  # Changed from 1.28
}
```

## Architecture Overview

### VPC Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC CIDR Block                            │
│              (dev: 10.100.0.0/16)                           │
│              (staging: 10.110.0.0/16)                       │
│              (prod: 10.120.0.0/16)                          │
├─────────────────────────────────────────────────────────────┤
│  Public Subnets (NAT Gateway)                               │
│  ├─ 10.xxx.1.0/24 (AZ-a)                                   │
│  ├─ 10.xxx.2.0/24 (AZ-b)                                   │
│  └─ 10.xxx.3.0/24 (AZ-c) [prod only]                       │
├─────────────────────────────────────────────────────────────┤
│  Private Subnets (Worker Nodes - NAT egress)                │
│  ├─ 10.xxx.11.0/24 (AZ-a)                                  │
│  ├─ 10.xxx.12.0/24 (AZ-b)                                  │
│  └─ 10.xxx.13.0/24 (AZ-c) [prod only]                      │
├─────────────────────────────────────────────────────────────┤
│  Intra Subnets (Control Plane, internal services)           │
│  ├─ 10.xxx.21.0/24 (AZ-a)                                  │
│  ├─ 10.xxx.22.0/24 (AZ-b)                                  │
│  └─ 10.xxx.23.0/24 (AZ-c) [prod only]                      │
└─────────────────────────────────────────────────────────────┘
```

### EKS Cluster Architecture

```
┌────────────────────────────────────────────────────────────┐
│                     EKS Control Plane                       │
│  (AWS Managed - Multi-AZ, High Availability)               │
└────────────────────────────────────────────────────────────┘
         ↓              ↓              ↓
┌─────────────────────────────────────────────────────────────┐
│            Managed Node Groups (Auto Scaling)               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ System Nodes │  │   App Nodes  │  │  GPU Nodes   │      │
│  │  (t3.medium) │  │ (t3.large)   │  │(g4dn.2xlarge)      │
│  │  Min: 1      │  │  Min: 3      │  │  Min: 1      │      │
│  │  Max: 2      │  │  Max: 10     │  │  Max: 4      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                          │
├─────────────────────────────────────────────────────────────┤
│  1. Network Security
│     - Security Groups with least privilege
│     - Private subnets for workloads
│     - VPC endpoints for AWS services
│
│  2. Encryption
│     - KMS encryption at rest (EBS, RDS, logs)
│     - TLS for data in transit
│
│  3. IAM
│     - IRSA (IAM Roles for Service Accounts)
│     - Least privilege policies
│     - Service-specific roles
│
│  4. Monitoring & Logging
│     - CloudWatch logs for control plane
│     - VPC Flow Logs
│     - Audit logging enabled
└─────────────────────────────────────────────────────────────┘
```

## Outputs

After applying the Terraform configuration, the following outputs are available:

```bash
# Get all outputs
terraform output

# Get specific outputs
terraform output cluster_id
terraform output cluster_endpoint
terraform output configure_kubectl
```

Key outputs include:

- `cluster_id`: EKS cluster ID
- `cluster_arn`: EKS cluster ARN
- `cluster_endpoint`: Kubernetes API endpoint
- `cluster_name`: EKS cluster name
- `vpc_id`: VPC ID
- `public_subnet_ids`: List of public subnet IDs
- `private_subnet_ids`: List of private subnet IDs
- `oidc_provider_arn`: ARN of the OIDC provider for IRSA
- `configure_kubectl`: Command to configure kubectl
- `tags`: Tags applied to all resources

## Remote State Management

To enable remote state management with S3 backend:

1. **Create S3 bucket and DynamoDB table** (using `backend.tf`):

```bash
# Create backend resources (run once)
terraform plan -target=aws_s3_bucket.terraform_state \
               -target=aws_dynamodb_table.terraform_locks \
               -var-file="environments/dev.tfvars"
terraform apply  -target=aws_s3_bucket.terraform_state \
                -target=aws_dynamodb_table.terraform_locks \
                -var-file="environments/dev.tfvars"
```

2. **Uncomment backend configuration in `provider.tf`**:

```hcl
backend "s3" {
  bucket         = "bookify-dev-terraform-state-123456789012"
  key            = "eks/terraform.tfstate"
  region         = "ap-south-1"
  encrypt        = true
  dynamodb_table = "bookify-dev-terraform-locks"
}
```

3. **Re-initialize Terraform**:

```bash
terraform init
# You'll be asked to copy state to the new backend
```

## Troubleshooting

### Common Issues

#### 1. Authentication Errors

```bash
# Check AWS credentials
aws sts get-caller-identity

# Ensure you have the necessary permissions
aws eks describe-cluster --name bookify-dev-cluster --region ap-south-1
```

#### 2. Kubernetes Connection Issues

```bash
# Update kubeconfig
aws eks update-kubeconfig --name bookify-dev-cluster --region ap-south-1

# Test connection
kubectl cluster-info
kubectl get nodes
```

#### 3. Terraform State Issues

```bash
# Force unlock (if state is locked)
terraform force-unlock <LOCK_ID>

# Refresh state
terraform refresh -var-file="environments/dev.tfvars"
```

### Debug Mode

Enable debug logging:

```bash
export TF_LOG=DEBUG
terraform plan -var-file="environments/dev.tfvars"
```

## Best Practices

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/update-eks-version

# 2. Modify configuration
# Edit variables.tf, environments/dev.tfvars, etc.

# 3. Validate changes
./deploy.sh validate
terraform fmt -recursive

# 4. Plan changes
./deploy.sh plan dev

# 5. Review plan output carefully
cat tfplan.dev

# 6. Apply changes to dev first
./deploy.sh apply dev

# 7. Test thoroughly in dev
kubectl get nodes
kubectl get pods -A

# 8. Apply to staging
./deploy.sh apply staging

# 9. Testing in staging...
# 10. Finally apply to production
./deploy.sh apply prod

# 11. Commit changes
git add .
git commit -m "Update EKS configuration"
git push origin feature/update-eks-version
```

### Code Review Checklist

- [ ] All variables have descriptions
- [ ] Sensitive values marked with `sensitive = true`
- [ ] Tags are consistent across environments
- [ ] Security groups follow least-privilege principle
- [ ] High availability is enabled for staging/prod
- [ ] Monitoring and logging are enabled
- [ ] Backup retention is appropriate for environment
- [ ] Cost optimization considered for dev

### Production Deployment Checklist

- [ ] Changes tested in dev environment
- [ ] Changes staged in staging environment
- [ ] Cluster endpoint restricted to known IPs
- [ ] KMS encryption enabled
- [ ] Backup retention set to 30+ days
- [ ] CloudWatch logs retention set to 90+ days
- [ ] Multi-AZ configuration verified
- [ ] Auto-scaling limits appropriate
- [ ] Disaster recovery plan documented
- [ ] Rollback procedure tested

## Disaster Recovery

### Backup State

```bash
# Backup current state
terraform state pull > terraform.tfstate.backup

# Backup S3 backend
aws s3 sync s3://bookify-prod-terraform-state-123456789012 \
          ./terraform-state-backup/
```

### Rollback Procedure

```bash
# 1. Identify the failed change
terraform plan -var-file="environments/prod.tfvars"

# 2. Revert to previous version if using git
git revert <commit-hash>

# 3. Plan the rollback
terraform plan -var-file="environments/prod.tfvars" -destroy

# 4. Carefully apply rollback
# (This should be a targeted destruction, not full destroy)
terraform apply -var-file="environments/prod.tfvars"
```

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Best Practices](https://www.terraform.io/language)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## Contributing

When contributing to this Terraform configuration:

1. Follow the existing code structure and naming conventions
2. Ensure all variables are properly documented
3. Test changes in dev environment first
4. Run `terraform fmt` before committing
5. Create descriptive commit messages
6. Update documentation when adding new features

## License

This Terraform configuration is part of the Bookify project. See the LICENSE file for details.
