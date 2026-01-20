################################################################################
# AWS Load Balancer Controller IAM Policy
################################################################################

resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name        = "${local.name_prefix}-aws-load-balancer-controller"
  description = "Policy for AWS Load Balancer Controller in ${local.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elbv2:CreateListener",
          "elbv2:DeleteListener",
          "elbv2:DescribeListeners",
          "elbv2:DescribeLoadBalancers",
          "elbv2:DescribeTargetGroups",
          "elbv2:ModifyListener",
          "elbv2:ModifyLoadBalancerAttributes",
          "elbv2:ModifyRule",
          "elbv2:ModifyTargetGroup",
          "elbv2:ModifyTargetGroupAttributes",
          "elbv2:RegisterTargets",
          "elbv2:DeregisterTargets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = [
          "arn:aws:ec2:*:*:vpc/*",
          "arn:aws:ec2:*:*:security-group/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, var.tags)
}

################################################################################
# EBS CSI Driver IAM Policy
################################################################################

resource "aws_iam_policy" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name        = "${local.name_prefix}-ebs-csi-driver"
  description = "Policy for EBS CSI Driver in ${local.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeCreateVolumePermissions",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DeleteTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, var.tags)
}

################################################################################
# EFS CSI Driver IAM Policy
################################################################################

resource "aws_iam_policy" "efs_csi_driver" {
  count = var.enable_efs_csi_driver ? 1 : 0

  name        = "${local.name_prefix}-efs-csi-driver"
  description = "Policy for EFS CSI Driver in ${local.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:TagResource"
        ]
        Resource = "arn:aws:elasticfilesystem:*:*:access-point/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DeleteAccessPoint"
        ]
        Resource = "arn:aws:elasticfilesystem:*:*:access-point/*"
      }
    ]
  })

  tags = merge(local.common_tags, var.tags)
}

################################################################################
# External Secrets Operator IAM Policy
################################################################################

resource "aws_iam_policy" "external_secrets_operator" {
  name        = "${local.name_prefix}-external-secrets-operator"
  description = "Policy for External Secrets Operator in ${local.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${local.account_id}:secret:${local.name_prefix}*"
      }
    ]
  })

  tags = merge(local.common_tags, var.tags)
}
