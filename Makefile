# Bookify DevSecOps Makefile
# Provides common commands for managing the DevSecOps platform

.PHONY: help setup deploy undeploy validate test clean

# Default target
help: ## Show this help message
	@echo "Bookify DevSecOps Platform"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_0-9%-]+:.*?## .*$$' $(word 1,$(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'

setup: ## Set up the local development environment
	@echo "Setting up local development environment..."
	@echo "1. Verify prerequisites..."
	@kubectl version --client
	@helm version
	@argocd version --client
	@echo "2. Create required namespaces..."
	@kubectl create namespace bookify-dev --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create namespace bookify-staging --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create namespace bookify-prod --dry-run=client -o yaml | kubectl apply -f -
	@echo "3. Setup completed successfully."

deploy: ## Deploy the application to Kubernetes
	@echo "Deploying Bookify application..."
	@kubectl apply -f Dev/argo-app.yaml
	@kubectl apply -f Dev/client/deployment.yaml
	@kubectl apply -f Dev/client/service.yaml
	@kubectl apply -f Dev/server/deployment.yaml
	@kubectl apply -f Dev/server/service.yaml
	@kubectl apply -f monitoring/argocd-service-monitors.yaml
	@echo "Deployment completed. Verify with 'kubectl get pods'."

undeploy: ## Remove the application from Kubernetes
	@echo "Removing Bookify application..."
	@kubectl delete -f monitoring/argocd-service-monitors.yaml
	@kubectl delete -f Dev/server/service.yaml
	@kubectl delete -f Dev/server/deployment.yaml
	@kubectl delete -f Dev/client/service.yaml
	@kubectl delete -f Dev/client/deployment.yaml
	@kubectl delete -f Dev/argo-app.yaml
	@echo "Undeployment completed."

validate: ## Validate Kubernetes manifests
	@echo "Validating Kubernetes manifests..."
	@for file in Dev/*.yaml Dev/client/*.yaml Dev/server/*.yaml monitoring/*.yaml; do \
		if [ -f "$$file" ]; then \
			echo "Validating $$file"; \
			kubectl apply --dry-run=client -f $$file; \
		fi \
	done
	@echo "Validation completed."

test: ## Run tests
	@echo "Running tests..."
	@echo "1. Validating manifests..."
	@make validate
	@echo "2. Checking cluster connectivity..."
	@kubectl cluster-info
	@echo "3. Running integration tests..."
	@# Add integration tests here
	@echo "Tests completed."

argo-status: ## Check ArgoCD application status
	@echo "Checking ArgoCD application status..."
	@argocd app list
	@echo "To see details of a specific application, run: argocd app get <app-name>"

argo-sync: ## Sync ArgoCD applications
	@echo "Syncing ArgoCD applications..."
	@argocd app sync --all

monitoring-status: ## Check monitoring components
	@echo "Checking monitoring components..."
	@kubectl get prometheus,prometheusrules,servicemonitors,alertmanager,grafana -A

logs: ## View application logs
	@echo "Viewing application logs..."
	@kubectl get pods -A | grep -E "(bookify|argocd)" | while read -r pod; do \
		namespace=$$(echo "$$pod" | awk '{print $$1}'); \
		pod_name=$$(echo "$$pod" | awk '{print $$2}'); \
		echo "Logs for $$pod_name in $$namespace:"; \
		kubectl logs -n $$namespace $$pod_name --tail=50; \
		echo "---"; \
	done

clean: ## Clean up temporary files
	@echo "Cleaning up temporary files..."
	@rm -f *.tmp *.temp
	@find . -type f -name "*.tmp" -delete
	@find . -type f -name "*.temp" -delete
	@echo "Cleanup completed."

security-scan: ## Run security scan on images
	@echo "Running security scan..."
	@echo "Please ensure Trivy or similar security scanner is installed"
	@which trivy || echo "Trivy not found. Install it from https://github.com/aquasecurity/trivy"
	@# Add security scanning commands here

update-deps: ## Update dependencies
	@echo "Please update dependencies in your application code accordingly"
	@echo "This target would update dependencies based on your application type"

backup: ## Create backup of cluster resources
	@echo "Creating backup of cluster resources..."
	@mkdir -p backups
	@timestamp=$$(date +%Y%m%d_%H%M%S); \
	kubectl get all,configmaps,secrets,pvc,storageclasses,ingresses -A -o yaml > backups/cluster-backup-$$timestamp.yaml
	@echo "Backup created in backups/cluster-backup-$$timestamp.yaml"

restore: ## Restore cluster resources from backup
	@echo "Restoring from backup. Please specify backup file:"
	@echo "make restore BACKUP_FILE=backups/cluster-backup-timestamp.yaml"
ifdef BACKUP_FILE
	@echo "Restoring from $(BACKUP_FILE)..."
	@kubectl apply -f $(BACKUP_FILE)
	@echo "Restore completed."
else
	@echo "Please specify backup file: make restore BACKUP_FILE=path/to/backup.yaml"
endif