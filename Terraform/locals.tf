locals {
  # Common naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
    Region      = var.aws_region
  }

  # Get current AWS account ID and caller identity
  account_id = data.aws_caller_identity.current.account_id
  caller_arn = data.aws_caller_identity.current.arn

  # Availability zones
  azs = var.availability_zones

  # EKS Cluster name
  cluster_name = "${local.name_prefix}-cluster"

  # Node group names
  default_node_group_name = "${local.name_prefix}-node-group"

  # VPC naming
  vpc_name = "${local.name_prefix}-vpc"

  # CloudWatch log group name
  cluster_log_group_name = "/aws/eks/${local.cluster_name}"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for AWS availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
