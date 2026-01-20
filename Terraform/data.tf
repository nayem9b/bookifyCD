################################################################################
# Data Sources
################################################################################

# Get available AWS regions
data "aws_regions" "available" {}

# Get availability zones in the selected region
data "aws_availability_zones" "available_azs" {
  state = "available"
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current AWS account details
data "aws_account" "current" {}
