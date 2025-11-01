# Project Setup Guide

## Prerequisites Installation

Before setting up the Bookify DevSecOps platform, ensure your system meets the following prerequisites:

### System Requirements
- Operating System: Linux (Ubuntu 20.04 LTS or CentOS 7+), macOS 10.15+, or Windows 10/11 (with WSL2)
- RAM: Minimum 8GB (16GB recommended)
- Storage: Minimum 50GB available space
- CPU: Multi-core processor with virtualization support

### Required Tools
1. **Git**: Version control system
   - Ubuntu/Debian: `sudo apt-get install git`
   - CentOS/RHEL: `sudo yum install git`
   - macOS: `brew install git`
   - Windows: Download from https://git-scm.com/download/win

2. **Docker**: Containerization platform
   - Ubuntu: `curl -sSL https://get.docker.com | sh`
   - CentOS: `sudo yum install docker`
   - macOS: Download Docker Desktop
   - Windows: Download Docker Desktop

3. **kubectl**: Kubernetes command-line tool
   ```bash
   # Linux
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/

   # macOS
   brew install kubectl

   # Windows
   winget install Kubernetes.kubectl
   ```

4. **Helm**: Kubernetes package manager
   ```bash
   # Linux/macOS
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

   # Windows
   winget install Helm.Helm
   ```

5. **ArgoCD CLI**: GitOps tool command-line interface
   ```bash
   # Linux
   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
   sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

   # macOS
   brew install argocd

   # Windows (PowerShell)
   Invoke-WebRequest -Uri https://github.com/argoproj/argo-cd/releases/latest/download/argocd-windows-amd64.exe -OutFile argocd.exe
   ```

6. **Kustomize**: Kubernetes configuration management
   - Follow installation instructions at https://kubectl.docs.kubernetes.io/installation/kustomize/

## Environment Setup

### Local Development Environment
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd Bookify/DevSecOps
   ```

2. Set up Git configuration:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   git config --global core.autocrlf input  # For Linux/macOS
   git config --global core.autocrlf true   # For Windows
   ```

3. Set up Docker:
   - Start Docker service: `sudo systemctl start docker`
   - Add user to docker group: `sudo usermod -aG docker $USER`
   - Log out and back in for changes to take effect

### Kubernetes Cluster Setup
Choose one of the following options:

#### Option 1: Minikube (Local Development)
```bash
# Install Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube /usr/local/bin/

# Start Minikube
minikube start --cpus=4 --memory=8192 --disk-size=40g

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
```

#### Option 2: Kind (Kubernetes in Docker)
```bash
# Install Kind
go install sigs.k8s.io/kind@v0.11.1

# Create cluster
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

#### Option 3: Cloud Provider (Production)
- AWS EKS: https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html
- GCP GKE: https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster
- Azure AKS: https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough

## ArgoCD Installation

1. Install ArgoCD in your Kubernetes cluster:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. Configure external access:
```bash
# For LoadBalancer service
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Or for NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# For local development with port forwarding
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

3. Retrieve initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

4. Access ArgoCD UI at https://localhost:8080 (if using port-forward) or your cluster's external IP

## Application Deployment

1. Apply the main ArgoCD application:
```bash
kubectl apply -f Dev/argo-app.yaml
```

2. Deploy client and server components:
```bash
kubectl apply -f Dev/client/deployment.yaml
kubectl apply -f Dev/client/service.yaml
kubectl apply -f Dev/server/deployment.yaml
kubectl apply -f Dev/server/service.yaml
```

3. Apply monitoring configurations:
```bash
kubectl apply -f monitoring/argocd-service-monitors.yaml
```

## Verification

1. Verify all deployments are running:
```bash
kubectl get deployments
kubectl get pods
```

2. Check ArgoCD status:
```bash
argocd app list
argocd app sync <application-name>
argocd app get <application-name>
```

3. Verify monitoring components:
```bash
kubectl get servicemonitors
kubectl get prometheus
kubectl get grafana
```

## Post-Installation Configuration

1. Update image tags in deployment files to match your environment
2. Configure domain names for ingress if needed
3. Set up TLS certificates for HTTPS
4. Configure external database connections if applicable
5. Set up backup and disaster recovery procedures