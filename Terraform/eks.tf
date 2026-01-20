################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  # Cluster networking
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = concat(module.vpc.private_subnets, module.vpc.intra_subnets)
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Cluster endpoint access
  cluster_endpoint_private_access          = var.cluster_endpoint_private_access
  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs     = var.cluster_endpoint_public_access_cidrs

  # Cluster encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # Cluster logging
  cluster_enabled_log_types = var.enable_cluster_logging ? var.cluster_enabled_log_types : []
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_days

  # Cluster add-ons
  cluster_addons = {
    coredns = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
      configuration_values = jsonencode({
        env = {
          WARM_IP_TARGET           = 5
          MINIMUM_IP_TARGET        = 10
          ENABLE_WINDOW_IPAM       = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }
    ebs-csi-driver = var.enable_ebs_csi_driver ? {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    } : null
    efs-csi-driver = var.enable_efs_csi_driver ? {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    } : null
  }

  # Managed node groups
  eks_managed_node_group_defaults = {
    disk_size              = 50
    instance_types         = ["t3.medium"]
    iam_role_attach_cni_policy = true
    vpc_security_group_ids = [aws_security_group.node_additional.id]

    # Taints
    taints = []

    # Labels
    labels = {
      Environment = var.environment
      Cluster     = local.cluster_name
    }

    # Block device mappings
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 50
          volume_type           = "gp3"
          delete_on_termination = true
          iops                  = 3000
          throughput            = 125
          encrypted             = true
          kms_key_id            = aws_kms_key.eks.arn
        }
      }
    }
  }

  eks_managed_node_groups = {
    for ng_name, ng_config in var.node_group_configs : ng_name => {
      name         = "${local.name_prefix}-${ng_name}"
      min_size     = ng_config.min_size
      max_size     = ng_config.max_size
      desired_size = ng_config.desired_size

      instance_types = ng_config.instance_types
      capacity_type  = ng_config.capacity_type
      disk_size      = ng_config.disk_size

      labels = merge(
        {
          NodeGroup = ng_name
        },
        ng_config.labels
      )

      taints = ng_config.taints

      tags = merge(
        local.common_tags,
        var.tags,
        {
          NodeGroup = ng_name
        }
      )
    }
  }

  # Security groups
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_security_group_id   = aws_security_group.node_additional.id
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
    ingress_cluster_all = {
      description              = "Cluster to node all ports/protocols"
      protocol                 = "-1"
      from_port                = 0
      to_port                  = 65535
      type                     = "ingress"
      source_security_group_id = module.eks.cluster_security_group_id
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = var.enable_irsa

  # Tags
  tags = merge(local.common_tags, var.tags)
}

################################################################################
# KMS Key for EKS Encryption
################################################################################

resource "aws_kms_key" "eks" {
  description             = "EKS cluster encryption key for ${local.cluster_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-eks-key"
    }
  )
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.name_prefix}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "cluster" {
  name              = local.cluster_log_group_name
  retention_in_days = var.cluster_log_retention_days

  kms_key_id = aws_kms_key.eks.arn

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-cluster-logs"
    }
  )
}

################################################################################
# Cluster Autoscaler IAM Policy (if needed)
################################################################################

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaling ? 1 : 0

  name        = "${local.name_prefix}-cluster-autoscaler"
  description = "Policy for Cluster Autoscaler in ${local.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, var.tags)
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaling ? 1 : 0

  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = try(module.eks.eks_managed_node_groups_autoscaling_group_iam_role_name, "")
}

