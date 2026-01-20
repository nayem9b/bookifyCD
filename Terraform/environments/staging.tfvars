################################################################################
# Staging Environment Variables
# This configuration is suitable for staging and pre-production testing
################################################################################

environment = "staging"
aws_region  = "ap-south-1"
project_name = "bookify"

# VPC Configuration for Staging
vpc_cidr             = "10.110.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.110.1.0/24", "10.110.2.0/24"]
private_subnet_cidrs = ["10.110.11.0/24", "10.110.12.0/24"]
intra_subnet_cidrs   = ["10.110.21.0/24", "10.110.22.0/24"]

enable_nat_gateway   = true
single_nat_gateway   = false  # Separate NAT for each AZ
enable_vpn_gateway   = false
enable_dns_hostnames = true
enable_dns_support   = true

# EKS Cluster Configuration
cluster_version = "1.28"

cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

enable_cluster_logging       = true
cluster_log_retention_days   = 14
cluster_enabled_log_types    = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Node Groups for Staging
node_group_configs = {
  general = {
    min_size       = 2
    max_size       = 4
    desired_size   = 2
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"  # More stable for staging
    disk_size      = 50

    labels = {
      NodeType = "general"
      Workload = "mixed"
    }

    taints = []
  }

  gpu = {
    min_size       = 0
    max_size       = 2
    desired_size   = 0
    instance_types = ["g4dn.xlarge"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50

    labels = {
      NodeType = "gpu"
      Workload = "ml"
    }

    taints = [
      {
        key    = "gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

# Add-ons
enable_ebs_csi_driver                = true
enable_efs_csi_driver                = true
enable_aws_load_balancer_controller  = true
enable_cluster_autoscaler_addon      = true

# IAM
enable_irsa = true

# Monitoring and Logging
enable_monitoring = true

# Cluster Autoscaling
enable_cluster_autoscaling = true

# KMS Encryption
enable_kms_encryption = true

# Backup and Disaster Recovery
backup_retention_days = 7
enable_rds            = true

# RDS Configuration
rds_engine         = "postgres"
rds_engine_version = "15.3"
rds_allocated_storage = 100
rds_instance_class    = "db.t3.small"

# Custom Tags
tags = {
  CostCenter = "Engineering"
  Owner      = "DevOps"
  Tier       = "Staging"
  Compliance = "true"
}
