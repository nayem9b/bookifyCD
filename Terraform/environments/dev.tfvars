################################################################################
# Development Environment Variables
# This configuration is suitable for development and testing environments
################################################################################

environment = "dev"
aws_region  = "ap-south-1"
project_name = "bookify"

# VPC Configuration for Development
vpc_cidr             = "10.100.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.100.1.0/24", "10.100.2.0/24"]
private_subnet_cidrs = ["10.100.11.0/24", "10.100.12.0/24"]
intra_subnet_cidrs   = ["10.100.21.0/24", "10.100.22.0/24"]

enable_nat_gateway   = true
single_nat_gateway   = true  # Cost optimization for dev
enable_vpn_gateway   = false
enable_dns_hostnames = true
enable_dns_support   = true

# EKS Cluster Configuration
cluster_version = "1.28"

cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Open for development

enable_cluster_logging       = true
cluster_log_retention_days   = 7  # Short retention for cost optimization
cluster_enabled_log_types    = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Node Groups for Development
node_group_configs = {
  general = {
    min_size       = 1
    max_size       = 2
    desired_size   = 1
    instance_types = ["t3.medium"]
    capacity_type  = "SPOT"  # Use SPOT for cost savings
    disk_size      = 30

    labels = {
      NodeType = "general"
      Workload = "mixed"
    }

    taints = []
  }
}

# Add-ons
enable_ebs_csi_driver                = true
enable_efs_csi_driver                = false
enable_aws_load_balancer_controller  = true
enable_cluster_autoscaler_addon      = true

# IAM
enable_irsa = true

# Monitoring and Logging
enable_monitoring = true

# Cluster Autoscaling
enable_cluster_autoscaling = true

# KMS Encryption
enable_kms_encryption = false  # Disabled for development to reduce costs

# Backup and Disaster Recovery
backup_retention_days = 3
enable_rds            = false

# Custom Tags
tags = {
  CostCenter = "Engineering"
  Owner      = "DevOps"
  Tier       = "Development"
}
