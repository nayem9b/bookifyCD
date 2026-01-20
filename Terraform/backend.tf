################################################################################
# Terraform Backend Configuration
# Uncomment to enable remote state management
################################################################################

# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.name_prefix}-terraform-state-${local.account_id}"

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-terraform-state"
    }
  )
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "${local.name_prefix}-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${local.name_prefix}-terraform-locks"
    }
  )
}

################################################################################
# Backend Usage
################################################################################

# To use the S3 backend, update the terraform block in provider.tf:
# 
# backend "s3" {
#   bucket         = "bookify-dev-terraform-state-123456789012"
#   key            = "eks/terraform.tfstate"
#   region         = "ap-south-1"
#   encrypt        = true
#   dynamodb_table = "bookify-dev-terraform-locks"
# }
