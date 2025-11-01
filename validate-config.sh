#!/bin/bash

# Configuration validation script for Bookify DevSecOps platform
# Validates Kubernetes manifests and configuration files

set -e

# Configuration
KUBECONFORM_VERSION=${KUBECONFORM_VERSION:-"v0.6.1"}
SCHEMA_LOCATION=${SCHEMA_LOCATION:-"https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    case $1 in
        "OK")
            echo -e "${GREEN}[OK]${NC} $2"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $2"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $2"
            ;;
        *)
            echo "[INFO] $2"
            ;;
    esac
}

# Function to validate Kubernetes manifests
validate_k8s_manifests() {
    print_status "" "Validating Kubernetes manifests..."

    # Find all YAML files in the project
    yaml_files=$(find . -name "*.yaml" -o -name "*.yml" | grep -v ".git/" | grep -v "node_modules/" | grep -v ".terraform/")

    if [ -z "$yaml_files" ]; then
        print_status "WARNING" "No YAML files found to validate"
        return
    fi

    # Use kubeconform if available, otherwise basic validation
    if command -v kubeconform &> /dev/null; then
        print_status "INFO" "Using kubeconform for validation"
        echo "$yaml_files" | xargs kubeconform -strict -schema-location "$SCHEMA_LOCATION"
    else
        print_status "INFO" "Validating YAML syntax and basic Kubernetes structure"
        for file in $yaml_files; do
            print_status "INFO" "Validating $file"
            
            # Check if it's valid YAML
            if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                print_status "ERROR" "Invalid YAML syntax in $file"
                continue
            fi
            
            # If it looks like a Kubernetes manifest, validate basic structure
            if grep -q "apiVersion:" "$file" && grep -q "kind:" "$file"; then
                api_version=$(grep "apiVersion:" "$file" | head -1 | cut -d: -f2 | xargs)
                kind=$(grep "kind:" "$file" | head -1 | cut -d: -f2 | xargs)
                
                if [ -z "$api_version" ] || [ -z "$kind" ]; then
                    print_status "WARNING" "Missing apiVersion or kind in $file"
                else
                    print_status "OK" "Kubernetes manifest $file (apiVersion: $api_version, kind: $kind) appears valid"
                fi
            fi
        done
    fi
}

# Function to validate ArgoCD configurations
validate_argocd_configs() {
    print_status "" "Validating ArgoCD configurations..."

    argocd_files=$(find . -name "*argo*.yaml" -o -name "*argocd*.yaml" | grep -v ".git/" | xargs)
    
    if [ -z "$argocd_files" ]; then
        print_status "INFO" "No ArgoCD configuration files found"
        return
    fi

    for file in $argocd_files; do
        print_status "INFO" "Checking ArgoCD config in $file"
        
        # Check for required ArgoCD fields
        has_application=$(grep -c "kind: Application" "$file" 2>/dev/null || echo 0)
        has_project=$(grep -c "kind: AppProject\|kind: ApplicationSet" "$file" 2>/dev/null || echo 0)
        
        if [ "$has_application" -gt 0 ] || [ "$has_project" -gt 0 ]; then
            if grep -q "spec:" "$file" && grep -q "destination:" "$file"; then
                print_status "OK" "ArgoCD Application/Project in $file has required fields"
            else
                print_status "WARNING" "ArgoCD config in $file may be missing required fields"
            fi
        fi
    done
}

# Function to validate environment configurations
validate_env_configs() {
    print_status "" "Validating environment configurations..."

    if [ -f ".env" ]; then
        print_status "INFO" "Validating .env file"
        # Check for common required environment variables
        required_vars=("ENVIRONMENT" "REGISTRY_URL" "PROJECT_NAME")
        
        for var in "${required_vars[@]}"; do
            if grep -q "^${var}=" .env; then
                print_status "OK" "Environment variable $var found in .env"
            else
                print_status "WARNING" "Environment variable $var not found in .env"
            fi
        done
    else
        print_status "INFO" ".env file not found"
    fi
    
    # Check for environment-specific files
    for env in "dev.env" "staging.env" "prod.env"; do
        if [ -f "$env" ]; then
            print_status "OK" "Environment file $env found"
        else
            print_status "WARNING" "Environment file $env not found"
        fi
    done
}

# Function to validate Dockerfile
validate_dockerfile() {
    print_status "" "Validating Dockerfile..."

    if [ -f "Dockerfile" ]; then
        # Check for common security practices
        has_user=$(grep -i "USER\|user" Dockerfile | grep -v "#")
        has_healthcheck=$(grep -i "HEALTHCHECK" Dockerfile | grep -v "#")
        has_non_root=$(grep -i "RUN adduser\|RUN addgroup" Dockerfile | grep -v "#")
        
        print_status "OK" "Dockerfile found"
        
        if [ -n "$has_user" ] && [ -n "$has_non_root" ]; then
            print_status "OK" "Dockerfile follows non-root user security practice"
        else
            print_status "WARNING" "Dockerfile may not follow non-root user security practice"
        fi
        
        if [ -n "$has_healthcheck" ]; then
            print_status "OK" "Dockerfile includes HEALTHCHECK instruction"
        else
            print_status "WARNING" "Dockerfile does not include HEALTHCHECK instruction"
        fi
    else
        print_status "INFO" "Dockerfile not found"
    fi
}

# Function to run all validations
run_validations() {
    print_status "" "Starting configuration validation for Bookify DevSecOps platform..."
    echo ""
    
    validate_k8s_manifests
    echo ""
    
    validate_argocd_configs
    echo ""
    
    validate_env_configs
    echo ""
    
    validate_dockerfile
    echo ""
    
    print_status "" "Configuration validation completed."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Configuration validation script for Bookify DevSecOps platform"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -h, --help                 Show this help message"
            exit 0
            ;;
        *)
            print_status "ERROR" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run the validations
run_validations