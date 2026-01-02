#!/bin/bash

# Health check script for Bookify application
# This script checks the health of various components in the DevSecOps platform

set -e

# Configuration
TIMEOUT=10
NAMESPACE=${NAMESPACE:-"default"}
HEALTH_CHECK_TYPE=${HEALTH_CHECK_TYPE:-"all"}

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

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_status "ERROR" "kubectl is not installed or not in PATH"
        exit 1
    fi
    print_status "OK" "kubectl is available"
}

# Function to check Kubernetes cluster connectivity
check_cluster_connectivity() {
    if kubectl cluster-info &> /dev/null; then
        print_status "OK" "Kubernetes cluster is accessible"
    else
        print_status "ERROR" "Cannot connect to Kubernetes cluster"
        exit 1
    fi
}

# Function to check if ArgoCD is running
check_argocd() {
    if kubectl get pods -n argocd &> /dev/null; then
        argocd_pods=$(kubectl get pods -n argocd --field-selector=status.phase=Running --no-headers | wc -l)
        if [ "$argocd_pods" -gt 0 ]; then
            print_status "OK" "ArgoCD is running ($argocd_pods pods running)"
        else
            print_status "WARNING" "ArgoCD is not running properly"
        fi
    else
        print_status "ERROR" "Cannot access ArgoCD namespace"
    fi
}

# Function to check application deployments
check_deployments() {
    deployments=$(kubectl get deployments -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    if [ "$deployments" -gt 0 ]; then
        running_deployments=$(kubectl get deployments -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "1/1\|2/2\|3/3")
        print_status "OK" "Found $deployments deployments ($running_deployments running) in namespace $NAMESPACE"
    else
        print_status "WARNING" "No deployments found in namespace $NAMESPACE"
    fi
}

# Function to check services
check_services() {
    services=$(kubectl get services -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    if [ "$services" -gt 0 ]; then
        print_status "OK" "Found $services services in namespace $NAMESPACE"
    else
        print_status "WARNING" "No services found in namespace $NAMESPACE"
    fi
}

# Function to check pods
check_pods() {
    pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    if [ "$pods" -gt 0 ]; then
        running_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "Running")
        failed_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -c "Error\|CrashLoopBackOff\|ImagePullBackOff")
        
        if [ "$failed_pods" -gt 0 ]; then
            print_status "ERROR" "$failed_pods pods are in error state in namespace $NAMESPACE"
        else
            print_status "OK" "All $running_pods pods are running in namespace $NAMESPACE"
        fi
    else
        print_status "WARNING" "No pods found in namespace $NAMESPACE"
    fi
}

# Function to check monitoring components
check_monitoring() {
    if kubectl get pods -n monitoring &> /dev/null; then
        monitoring_pods=$(kubectl get pods -n monitoring --field-selector=status.phase=Running --no-headers | wc -l)
        if [ "$monitoring_pods" -gt 0 ]; then
            print_status "OK" "Monitoring stack is running ($monitoring_pods pods running)"
        else
            print_status "WARNING" "Monitoring stack is not running properly"
        fi
    else
        print_status "WARNING" "Monitoring namespace not found or not accessible"
    fi
}

# Main health check function
perform_health_check() {
    print_status "" "Starting health check for Bookify DevSecOps platform..."
    echo ""
    
    check_kubectl
    check_cluster_connectivity
    
    case $HEALTH_CHECK_TYPE in
        "all")
            check_argocd
            check_deployments
            check_services
            check_pods
            check_monitoring
            ;;
        "argocd")
            check_argocd
            ;;
        "application")
            check_deployments
            check_services
            check_pods
            ;;
        "monitoring")
            check_monitoring
            ;;
        *)
            print_status "INFO" "Unknown health check type: $HEALTH_CHECK_TYPE"
            ;;
    esac
    
    echo ""
    print_status "" "Health check completed."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -t|--type)
            HEALTH_CHECK_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Health check script for Bookify DevSecOps platform"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -n, --namespace NAMESPACE    Namespace to check (default: default)"
            echo "  -t, --type TYPE             Type of check (all, argocd, application, monitoring)"
            echo "  -h, --help                 Show this help message"
            exit 0
            ;;
        *)
            print_status "ERROR" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run the health check
perform_health_check