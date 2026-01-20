# Quick Reference Guide for Bookify Terraform

## 🚀 Quick Start Commands

```bash
# Initialize for development
make dev-init

# Plan deployment
make plan ENVIRONMENT=dev

# Apply configuration
make apply ENVIRONMENT=dev

# Get cluster details
make get-cluster-name ENVIRONMENT=dev
make get-cluster-endpoint ENVIRONMENT=dev

# Configure kubectl
make configure-kubectl ENVIRONMENT=dev

# View outputs
make output ENVIRONMENT=dev
```

## 📊 Environment Quick Reference

### Dev Environment

```
CIDR: 10.100.0.0/16
Nodes: 1 general node (t3.medium, SPOT)
NAT: Single (cost savings)
HA: No
Logs: 7 days
Use Case: Development & testing
```

### Staging Environment

```
CIDR: 10.110.0.0/16
Nodes: 2+ general nodes (t3.large) + optional GPU
NAT: Multiple (1 per AZ)
HA: 2 AZs
Logs: 14 days
Use Case: Pre-production testing
```

### Production Environment

```
CIDR: 10.120.0.0/16
Nodes: 3+ system + 3+ app + 1+ GPU (m5.xlarge/g4dn)
NAT: Multiple (1 per AZ)
HA: 3 AZs (multi-AZ)
Logs: 90 days
Use Case: Production workloads
```

## 🔧 Common Terraform Commands

```bash
# Format files
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# Apply configuration
terraform apply

# Show outputs
terraform output

# Show specific output
terraform output cluster_endpoint

# Show state
terraform state list
terraform state show module.eks.aws_eks_cluster.cluster

# Import resource
terraform import aws_instance.example i-1234567890

# Destroy resources
terraform destroy -var-file="environments/dev.tfvars"

# Refresh state
terraform refresh

# Generate resource graph
terraform graph > graph.dot
```

## 🎯 Deployment Workflow

### Step-by-Step Deployment

```bash
# 1. Initialize
make dev-init

# 2. Review the configuration
cat environments/dev.tfvars

# 3. Plan the deployment
make dev-plan

# 4. Review the plan output carefully
# Look for:
# - Correct number of resources
# - Correct instance types
# - Correct CIDR ranges
# - No unexpected changes

# 5. Apply the configuration
make apply ENVIRONMENT=dev

# 6. Wait for deployment (5-10 minutes for EKS)

# 7. Configure kubectl
make configure-kubectl ENVIRONMENT=dev

# 8. Verify the cluster
kubectl get nodes
kubectl get pods -A

# 9. Check outputs
make output ENVIRONMENT=dev
```

## 🔐 Security Checklist

- [ ] Development endpoint restricted to team IPs (if needed)
- [ ] Production endpoint restricted to known CIDRs
- [ ] KMS encryption enabled for production
- [ ] CloudWatch logs enabled
- [ ] VPC Flow Logs enabled
- [ ] Security groups follow least privilege
- [ ] IRSA enabled for pod IAM roles
- [ ] Node IAM roles properly scoped

## 📊 Cost Optimization Tips

### For Development

- Use SPOT instances
- Single NAT Gateway
- Smaller instance types (t3.medium)
- Short log retention (7 days)
- Disable unused features (EFS CSI, VPN, etc.)

### For Staging

- Mix ON_DEMAND and SPOT instances
- Optional resources like GPU nodes
- Moderate log retention (14 days)

### For Production

- ON_DEMAND instances for stability
- Multi-AZ for high availability
- Comprehensive logging (90 days)
- Backup retention (30 days)
- GPU nodes only when needed

## 🐛 Troubleshooting

### Issue: "Terraform init failed"

```bash
# Check AWS credentials
aws sts get-caller-identity

# Check Terraform version
terraform version

# Try re-initializing
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Issue: "Cannot connect to kubectl"

```bash
# Update kubeconfig
aws eks update-kubeconfig --name bookify-dev-cluster --region ap-south-1

# Test connection
kubectl cluster-info

# Check nodes
kubectl get nodes
```

### Issue: "State is locked"

```bash
# List locks
terraform state list

# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### Issue: "Plan changes don't match reality"

```bash
# Refresh state
terraform refresh -var-file="environments/dev.tfvars"

# Pull remote state (if using S3 backend)
terraform state pull > backup.tfstate
```

## 📈 Scaling Guide

### Adding More Node Groups

Edit `environments/prod.tfvars`:

```hcl
node_group_configs = {
  system = { ... },
  application = { ... },
  gpu = { ... },
  cache = {                    # New node group
    min_size       = 2
    max_size       = 5
    desired_size   = 2
    instance_types = ["r5.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 100
    labels = {
      NodeType = "cache"
      Workload = "redis"
    }
    taints = []
  }
}
```

Then apply:

```bash
terraform plan -var-file="environments/prod.tfvars" -out=plan.tfplan
terraform apply plan.tfplan
```

### Increasing Node Count

Edit node group in `environments/prod.tfvars`:

```hcl
node_group_configs = {
  application = {
    min_size       = 5        # Increased from 3
    max_size       = 15       # Increased from 10
    desired_size   = 8        # Increased from 5
    ...
  }
}
```

### Changing Instance Types

Edit in environment tfvars:

```hcl
node_group_configs = {
  application = {
    instance_types = ["m5.xlarge"]  # Changed from m5.large
    ...
  }
}
```

## 🔄 Upgrading EKS

### 1. Update Kubernetes version

Edit `variables.tf`:

```hcl
cluster_version = "1.29"  # Changed from 1.28
```

### 2. Plan the upgrade

```bash
terraform plan -var-file="environments/prod.tfvars"
```

### 3. Apply the upgrade

```bash
terraform apply
```

### 4. Verify the upgrade

```bash
kubectl version --short
aws eks describe-cluster --name bookify-prod-cluster --region ap-south-1 | grep version
```

## 🔗 Useful Links

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Best Practices](https://aws.amazon.com/architecture/well-architected/)

## 📞 Support

For issues or questions:

1. Check the README.md for detailed documentation
2. Review the Terraform plan before applying
3. Check CloudWatch logs for errors
4. Verify AWS credentials and permissions
5. Check Kubernetes cluster health with `kubectl get nodes`
