# Cluster Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = module.eks.cluster_platform_version
}

# Node Group Outputs
output "eks_managed_node_groups" {
  description = "EKS managed node group details"
  value = {
    for k, v in module.eks.eks_managed_node_groups : k => {
      id           = v.id
      arn          = v.arn
      resources    = v.resources
      status       = v.status
      version      = v.version
      disk_size    = v.disk_size
      capacity_type = v.capacity_type
    }
  }
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "intra_subnet_ids" {
  description = "List of intra subnet IDs"
  value       = module.vpc.intra_subnets
}

output "nat_gateway_ips" {
  description = "List of NAT Gateway public IPs"
  value       = module.vpc.nat_public_ips
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

# OIDC Provider Outputs
output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = try(module.eks.oidc_provider_arn, null)
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = try(module.eks.oidc_provider, null)
}

# Add-on Outputs
output "cluster_addons" {
  description = "Map of installed EKS cluster add-ons"
  value = {
    for addon, details in try(module.eks.cluster_addons, {}) : addon => {
      arn             = details.addon_arn
      created_at      = details.created_at
      modified_at     = details.modified_at
      service_account = try(details.service_account_role_arn, null)
      version         = details.addon_version
    }
  }
}

# CloudWatch Logs
output "cluster_cloudwatch_log_group_name" {
  description = "CloudWatch log group name for cluster logs"
  value       = try(module.eks.cloudwatch_log_group_name, null)
}

output "cluster_cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for cluster logs"
  value       = try(module.eks.cloudwatch_log_group_arn, null)
}

# IAM Outputs
output "cluster_iam_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_iam_role_name" {
  description = "IAM role name for the EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "node_security_group_id" {
  description = "Security group ID of the worker nodes"
  value       = try(module.eks.node_security_group_id, null)
}

# Kubeconfig Output
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# Environment Info
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# Cluster Tags
output "tags" {
  description = "Tags applied to cluster resources"
  value       = merge(local.common_tags, var.tags)
}
