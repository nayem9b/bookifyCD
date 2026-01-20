.PHONY: help init validate plan apply destroy output configure clean fmt lint

# Variables
ENVIRONMENT ?= dev
TERRAFORM_DIR := $(PWD)
TF_VARS_FILE := environments/$(ENVIRONMENT).tfvars
TF_PLAN_FILE := .terraform/terraform-$(ENVIRONMENT).plan

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Display this help message
	@echo "$(BLUE)Bookify Terraform Makefile$(NC)"
	@echo "$(BLUE)============================$(NC)"
	@echo ""
	@echo "Usage: make [target] ENVIRONMENT=<dev|staging|prod>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make init ENVIRONMENT=dev"
	@echo "  make plan ENVIRONMENT=staging"
	@echo "  make apply ENVIRONMENT=prod"
	@echo ""

check-env: ## Check if required environment is valid
	@if [ "$(ENVIRONMENT)" != "dev" ] && [ "$(ENVIRONMENT)" != "staging" ] && [ "$(ENVIRONMENT)" != "prod" ]; then \
		echo "$(RED)Error: Invalid environment '$(ENVIRONMENT)'$(NC)"; \
		echo "Please use: ENVIRONMENT=dev|staging|prod"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Using environment: $(ENVIRONMENT)$(NC)"

check-prerequisites: ## Check if all prerequisites are installed
	@echo "$(BLUE)Checking prerequisites...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)✗ Terraform not found$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Terraform: $$(terraform version | head -n 1)$(NC)"
	@command -v aws >/dev/null 2>&1 || { echo "$(RED)✗ AWS CLI not found$(NC)"; exit 1; }
	@echo "$(GREEN)✓ AWS CLI: $$(aws --version)$(NC)"
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)✗ kubectl not found$(NC)"; exit 1; }
	@echo "$(GREEN)✓ kubectl: $$(kubectl version --client --short 2>/dev/null)$(NC)"
	@aws sts get-caller-identity >/dev/null 2>&1 || { echo "$(RED)✗ AWS credentials not configured$(NC)"; exit 1; }
	@echo "$(GREEN)✓ AWS credentials configured$(NC)"

init: check-env check-prerequisites ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform for $(ENVIRONMENT)...$(NC)"
	@terraform init
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

fmt: ## Format all Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive
	@echo "$(GREEN)✓ Terraform files formatted$(NC)"

validate: check-prerequisites ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	@terraform validate
	@echo "$(GREEN)✓ Terraform configuration is valid$(NC)"

lint: fmt validate ## Format and validate Terraform files

plan: check-env validate ## Plan Terraform deployment
	@echo "$(BLUE)Planning Terraform deployment for $(ENVIRONMENT)...$(NC)"
	@mkdir -p .terraform
	@terraform plan \
		-var-file="$(TF_VARS_FILE)" \
		-out="$(TF_PLAN_FILE)"
	@echo "$(GREEN)✓ Plan saved to $(TF_PLAN_FILE)$(NC)"

show-plan: ## Show the generated plan
	@echo "$(BLUE)Showing plan for $(ENVIRONMENT)...$(NC)"
	@terraform show "$(TF_PLAN_FILE)"

apply: check-env plan ## Apply Terraform deployment
	@echo "$(RED)WARNING: This will make infrastructure changes!$(NC)"
	@echo "$(YELLOW)Please review the plan above carefully.$(NC)"
	@read -p "Do you want to continue? [yes/no] " -r confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(BLUE)Applying Terraform configuration for $(ENVIRONMENT)...$(NC)"; \
		terraform apply "$(TF_PLAN_FILE)"; \
		echo "$(GREEN)✓ Terraform configuration applied$(NC)"; \
	else \
		echo "$(YELLOW)✗ Apply cancelled$(NC)"; \
		exit 1; \
	fi

apply-auto: check-env ## Apply Terraform deployment without plan review (USE WITH CAUTION)
	@echo "$(RED)WARNING: This will make infrastructure changes without plan review!$(NC)"
	@read -p "Type 'DANGER' to continue: " -r confirm; \
	if [ "$$confirm" = "DANGER" ]; then \
		echo "$(BLUE)Applying Terraform configuration for $(ENVIRONMENT)...$(NC)"; \
		terraform apply \
			-var-file="$(TF_VARS_FILE)" \
			-auto-approve; \
		echo "$(GREEN)✓ Terraform configuration applied$(NC)"; \
	else \
		echo "$(YELLOW)✗ Apply cancelled$(NC)"; \
		exit 1; \
	fi

destroy: check-env ## Destroy Terraform resources (DESTRUCTIVE)
	@echo "$(RED)WARNING: This will DESTROY all infrastructure in $(ENVIRONMENT)!$(NC)"
	@read -p "Type 'yes' to confirm destruction of $(ENVIRONMENT): " -r confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(BLUE)Destroying infrastructure for $(ENVIRONMENT)...$(NC)"; \
		terraform destroy \
			-var-file="$(TF_VARS_FILE)" \
			-auto-approve; \
		echo "$(GREEN)✓ Infrastructure destroyed$(NC)"; \
	else \
		echo "$(YELLOW)✗ Destruction cancelled$(NC)"; \
		exit 1; \
	fi

output: check-env ## Display Terraform outputs
	@echo "$(BLUE)Outputs for $(ENVIRONMENT):$(NC)"
	@terraform output

output-json: check-env ## Display Terraform outputs in JSON format
	@terraform output -json

get-cluster-endpoint: check-env ## Get the Kubernetes cluster endpoint
	@terraform output -raw cluster_endpoint 2>/dev/null || echo "$(RED)Cluster endpoint not available$(NC)"

get-cluster-name: check-env ## Get the Kubernetes cluster name
	@terraform output -raw cluster_name 2>/dev/null || echo "$(RED)Cluster name not available$(NC)"

configure-kubectl: check-env ## Configure kubectl for the cluster
	@echo "$(BLUE)Configuring kubectl for $(ENVIRONMENT)...$(NC)"
	@CLUSTER_NAME=$$(terraform output -raw cluster_name); \
	REGION=$$(terraform output -raw region); \
	echo "$(BLUE)Cluster: $$CLUSTER_NAME$(NC)"; \
	echo "$(BLUE)Region: $$REGION$(NC)"; \
	aws eks update-kubeconfig --name "$$CLUSTER_NAME" --region "$$REGION"; \
	kubectl cluster-info; \
	echo "$(GREEN)✓ kubectl configured$(NC)"; \
	echo "$(GREEN)✓ Verifying connection...$(NC)"; \
	kubectl get nodes

state: ## Show Terraform state
	@terraform state list

state-show: ## Show detailed Terraform state
	@terraform state show

state-pull: ## Pull remote state
	@terraform state pull > terraform.tfstate.backup
	@echo "$(GREEN)✓ State backed up to terraform.tfstate.backup$(NC)"

state-push: ## Push local state to remote (USE WITH CAUTION)
	@read -p "This will push local state to remote. Continue? [yes/no] " -r confirm; \
	if [ "$$confirm" = "yes" ]; then \
		terraform state push; \
		echo "$(GREEN)✓ State pushed$(NC)"; \
	else \
		echo "$(YELLOW)✗ Push cancelled$(NC)"; \
		exit 1; \
	fi

graph: ## Generate resource graph
	@echo "$(BLUE)Generating resource graph for $(ENVIRONMENT)...$(NC)"
	@terraform graph > graph-$(ENVIRONMENT).dot
	@echo "$(GREEN)✓ Graph saved to graph-$(ENVIRONMENT).dot$(NC)"
	@echo "$(YELLOW)To visualize: dot -Tsvg graph-$(ENVIRONMENT).dot -o graph-$(ENVIRONMENT).svg$(NC)"

clean: ## Clean up temporary files
	@echo "$(BLUE)Cleaning up temporary files...$(NC)"
	@rm -rf .terraform/terraform-*.plan
	@rm -f *.tfstate
	@rm -f *.tfstate.backup
	@rm -f crash.log
	@rm -f graph-*.dot
	@rm -f graph-*.svg
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

full-clean: clean ## Full cleanup including .terraform directory
	@echo "$(BLUE)Performing full cleanup...$(NC)"
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@echo "$(GREEN)✓ Full cleanup complete$(NC)"

refresh: check-env ## Refresh Terraform state
	@echo "$(BLUE)Refreshing Terraform state for $(ENVIRONMENT)...$(NC)"
	@terraform refresh -var-file="$(TF_VARS_FILE)"
	@echo "$(GREEN)✓ State refreshed$(NC)"

import: check-env ## Import existing AWS resources (USAGE: make import TARGET=aws_instance.example ID=i-1234567890abcdef0)
	@if [ -z "$(TARGET)" ] || [ -z "$(ID)" ]; then \
		echo "$(RED)Error: TARGET and ID are required$(NC)"; \
		echo "Usage: make import TARGET=aws_instance.example ID=i-1234567890abcdef0"; \
		exit 1; \
	fi
	@echo "$(BLUE)Importing $(TARGET) with ID $(ID)...$(NC)"
	@terraform import -var-file="$(TF_VARS_FILE)" "$(TARGET)" "$(ID)"
	@echo "$(GREEN)✓ Resource imported$(NC)"

upgrade-modules: ## Upgrade Terraform modules
	@echo "$(BLUE)Upgrading Terraform modules...$(NC)"
	@terraform init -upgrade
	@echo "$(GREEN)✓ Modules upgraded$(NC)"

lock: ## Write dependency lock file
	@echo "$(BLUE)Writing Terraform dependency lock file...$(NC)"
	@terraform lock
	@echo "$(GREEN)✓ Lock file written$(NC)"

version: ## Display Terraform and provider versions
	@echo "$(BLUE)Terraform version:$(NC)"
	@terraform version
	@echo ""
	@echo "$(BLUE)Provider versions:$(NC)"
	@terraform providers

cost-estimate: check-env ## Estimate infrastructure costs
	@echo "$(BLUE)Generating cost estimate for $(ENVIRONMENT)...$(NC)"
	@echo "$(YELLOW)Note: This requires terraform-cost-estimation tool$(NC)"
	@terraform plan -var-file="$(TF_VARS_FILE)" -json | jq '.' || echo "$(RED)JSON parsing failed$(NC)"

dev-init: ## Initialize dev environment
	@$(MAKE) init ENVIRONMENT=dev
	@$(MAKE) validate
	@$(MAKE) fmt

staging-init: ## Initialize staging environment
	@$(MAKE) init ENVIRONMENT=staging
	@$(MAKE) validate
	@$(MAKE) fmt

prod-init: ## Initialize prod environment
	@$(MAKE) init ENVIRONMENT=prod
	@$(MAKE) validate
	@$(MAKE) fmt

all-init: dev-init staging-init prod-init ## Initialize all environments

dev-plan: ## Plan dev environment
	@$(MAKE) plan ENVIRONMENT=dev

staging-plan: ## Plan staging environment
	@$(MAKE) plan ENVIRONMENT=staging

prod-plan: ## Plan prod environment
	@$(MAKE) plan ENVIRONMENT=prod

all-plan: dev-plan staging-plan prod-plan ## Plan all environments
