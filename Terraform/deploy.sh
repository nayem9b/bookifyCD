#!/bin/bash

# Terraform Deployment Script
# This script automates the Terraform deployment process with proper validation and safety checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    print_success "Terraform is installed: $(terraform version | head -n 1)"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    print_success "AWS CLI is installed"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl is installed: $(kubectl version --client --short)"
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured"
        exit 1
    fi
    print_success "AWS credentials are configured"
}

# Initialize Terraform
init_terraform() {
    local environment=$1
    
    print_header "Initializing Terraform for $environment"
    
    terraform init
    
    print_success "Terraform initialized"
}

# Validate Terraform configuration
validate_terraform() {
    print_header "Validating Terraform Configuration"
    
    terraform validate
    
    print_success "Terraform configuration is valid"
}

# Format Terraform files
format_terraform() {
    print_header "Formatting Terraform Files"
    
    terraform fmt -recursive
    
    print_success "Terraform files formatted"
}

# Plan Terraform deployment
plan_terraform() {
    local environment=$1
    local plan_file="terraform-${environment}.plan"
    
    print_header "Planning Terraform Deployment for $environment"
    
    terraform plan \
        -var-file="environments/${environment}.tfvars" \
        -out="${plan_file}"
    
    print_success "Plan saved to ${plan_file}"
    echo "${plan_file}"
}

# Apply Terraform deployment
apply_terraform() {
    local environment=$1
    local plan_file=$2
    
    print_header "Applying Terraform Configuration for $environment"
    
    if [ -z "$plan_file" ]; then
        print_warning "No plan file provided, using fresh plan..."
        terraform apply \
            -var-file="environments/${environment}.tfvars" \
            -auto-approve
    else
        terraform apply "${plan_file}"
    fi
    
    print_success "Terraform configuration applied"
}

# Destroy Terraform resources
destroy_terraform() {
    local environment=$1
    
    print_header "Destroying Terraform Resources for $environment"
    print_warning "This will DELETE all infrastructure in $environment!"
    
    read -p "Are you sure? Type 'yes' to confirm: " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_info "Destruction cancelled"
        return 0
    fi
    
    terraform destroy \
        -var-file="environments/${environment}.tfvars" \
        -auto-approve
    
    print_success "Infrastructure destroyed"
}

# Get outputs
get_outputs() {
    local environment=$1
    
    print_header "Terraform Outputs for $environment"
    
    terraform output
}

# Configure kubectl
configure_kubectl() {
    local environment=$1
    local cluster_name=$(terraform output -raw cluster_name 2>/dev/null)
    local region=$(terraform output -raw region 2>/dev/null)
    
    print_header "Configuring kubectl for $environment"
    
    if [ -z "$cluster_name" ] || [ -z "$region" ]; then
        print_error "Could not retrieve cluster name or region"
        return 1
    fi
    
    print_info "Cluster: $cluster_name"
    print_info "Region: $region"
    
    aws eks update-kubeconfig --name "$cluster_name" --region "$region"
    
    print_success "kubectl configured"
    
    # Verify connection
    if kubectl cluster-info &> /dev/null; then
        print_success "Connected to cluster successfully"
        kubectl get nodes
    else
        print_error "Failed to connect to cluster"
        return 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 <command> [environment]

Commands:
    init <env>          Initialize Terraform for the specified environment
    validate            Validate Terraform configuration
    format              Format all Terraform files
    plan <env>          Plan deployment for the specified environment
    apply <env>         Apply deployment for the specified environment
    destroy <env>       Destroy resources for the specified environment
    output <env>        Show outputs for the specified environment
    configure <env>     Configure kubectl for the specified environment
    full-deploy <env>   Full deployment: init -> validate -> plan -> apply

Environments:
    dev                 Development environment
    staging             Staging environment
    prod                Production environment

Examples:
    $0 init dev
    $0 plan staging
    $0 full-deploy prod
    $0 configure dev

EOF
}

# Main logic
main() {
    local command=$1
    local environment=$2
    
    if [ -z "$command" ]; then
        show_usage
        exit 1
    fi
    
    # Check if environment is required and provided
    case $command in
        validate|format|output|help)
            # These commands don't need an environment
            ;;
        *)
            if [ -z "$environment" ] || ! [[ "$environment" =~ ^(dev|staging|prod)$ ]]; then
                print_error "Please specify a valid environment: dev, staging, or prod"
                show_usage
                exit 1
            fi
            ;;
    esac
    
    check_prerequisites
    
    case $command in
        init)
            init_terraform "$environment"
            ;;
        validate)
            validate_terraform
            ;;
        format)
            format_terraform
            ;;
        plan)
            plan_terraform "$environment"
            ;;
        apply)
            plan_file=$(plan_terraform "$environment")
            apply_terraform "$environment" "$plan_file"
            ;;
        destroy)
            destroy_terraform "$environment"
            ;;
        output)
            get_outputs "$environment"
            ;;
        configure)
            configure_kubectl "$environment"
            ;;
        full-deploy)
            init_terraform "$environment"
            validate_terraform
            format_terraform
            plan_file=$(plan_terraform "$environment")
            apply_terraform "$environment" "$plan_file"
            configure_kubectl "$environment"
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
