################################################################################
# Production Environment Variables
# This configuration is suitable for production workloads with high availability
################################################################################

environment = "prod"
aws_region  = "ap-south-1"
project_name = "bookify"

# VPC Configuration for Production
vpc_cidr             = "10.120.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnet_cidrs  = ["10.120.1.0/24", "10.120.2.0/24", "10.120.3.0/24"]
private_subnet_cidrs = ["10.120.11.0/24", "10.120.12.0/24", "10.120.13.0/24"]
intra_subnet_cidrs   = ["10.120.21.0/24", "10.120.22.0/24", "10.120.23.0/24"]

enable_nat_gateway   = true
single_nat_gateway   = false  # High availability - NAT in each AZ
enable_vpn_gateway   = true   # For hybrid connectivity
enable_dns_hostnames = true
enable_dns_support   = true

# EKS Cluster Configuration
cluster_version = "1.28"

cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["203.0.113.0/24"]  # Restrict to known IPs in production

enable_cluster_logging       = true
cluster_log_retention_days   = 90  # Long retention for compliance
cluster_enabled_log_types    = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Node Groups for Production
node_group_configs = {
  system = {
    min_size       = 3
    max_size       = 6
    desired_size   = 3
    instance_types = ["m5.xlarge"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 100

    labels = {
      NodeType = "system"
      Workload = "system"
    }

    taints = [
      {
        key    = "dedicated"
        value  = "system"
        effect = "NO_SCHEDULE"
      }
    ]
  }

  application = {
    min_size       = 3
    max_size       = 10
    desired_size   = 5
    instance_types = ["m5.large", "m5.xlarge"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 100

    labels = {
      NodeType = "application"
      Workload = "application"
    }

    taints = []
  }

  gpu = {
    min_size       = 1
    max_size       = 4
    desired_size   = 1
    instance_types = ["g4dn.2xlarge"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 100

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
backup_retention_days = 30
enable_rds            = true

# RDS Configuration
rds_engine         = "postgres"
rds_engine_version = "15.3"
rds_allocated_storage = 500
rds_instance_class    = "db.m5.xlarge"

# Custom Tags
tags = {
  CostCenter  = "Platform"
  Owner       = "DevOps"
  Tier        = "Production"
  Compliance  = "true"
  Environment = "prod"
  Backup      = "daily"
  Monitoring  = "intensive"
}
