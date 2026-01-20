################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs
  intra_subnets   = var.intra_subnet_cidrs

  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_vpn_gateway = var.enable_vpn_gateway

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Kubernetes specific tags
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"            = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  intra_subnet_tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }

  tags = merge(local.common_tags, var.tags)
}

################################################################################
# Security Groups
################################################################################

resource "aws_security_group" "cluster_additional" {
  name_prefix = "${local.name_prefix}-sg-"
  vpc_id      = module.vpc.vpc_id
  description = "Additional security group for EKS cluster ${local.cluster_name}"

  ingress {
    description = "Allow all ingress from within VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-cluster-sg"
    }
  )
}

resource "aws_security_group" "node_additional" {
  name_prefix = "${local.name_prefix}-node-sg-"
  vpc_id      = module.vpc.vpc_id
  description = "Additional security group for EKS nodes in ${local.cluster_name}"

  ingress {
    description = "Allow metrics scraping from cluster"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description     = "Allow pods to communicate with the cluster API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_additional.id]
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-node-sg"
    }
  )
}

