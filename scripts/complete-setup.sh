#!/bin/bash

# Complete CI/CD Setup Script
# This script sets up the entire CI/CD pipeline end-to-end

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
log_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

log_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"
    
    if command -v gh &> /dev/null; then
        log_success "GitHub CLI installed"
    else
        log_error "GitHub CLI not installed. Install from: https://cli.github.com/"
        return 1
    fi
    
    if command -v git &> /dev/null; then
        log_success "Git installed"
    else
        log_error "Git not installed"
        return 1
    fi
    
    if command -v kubectl &> /dev/null; then
        log_success "kubectl installed"
    else
        log_error "kubectl not installed"
        return 1
    fi
    
    # Check if kubectl can connect
    if kubectl cluster-info &> /dev/null; then
        log_success "Kubernetes cluster accessible"
    else
        log_error "Cannot connect to Kubernetes cluster"
        return 1
    fi
    
    # Check ArgoCD namespace
    if kubectl get namespace argocd &> /dev/null; then
        log_success "ArgoCD namespace exists"
    else
        log_error "ArgoCD not installed. Please run install-argocd.sh first"
        return 1
    fi
}

# Step 1: Create GitOps Repository
create_gitops_repo() {
    log_section "Step 1: Creating GitOps Repository"
    
    log_info "You need to create a new GitHub repository: ptuddn-t3-argocd"
    echo ""
    echo "  1. Go to: https://github.com/new"
    echo "  2. Repository name: ptuddn-t3-argocd"
    echo "  3. Description: GitOps repository for ptuddn-t3"
    echo "  4. Set as PRIVATE (important for security)"
    echo "  5. Click 'Create repository'"
    echo ""
    
    read -p "Press Enter once you've created the repository..."
    
    GITOPS_REPO_URL="https://github.com/$(gh api user -q '.login')/ptuddn-t3-argocd.git"
    log_info "GitOps repo URL: $GITOPS_REPO_URL"
    
    # Verify repo exists
    if gh repo view "${GITOPS_REPO_URL%%.git}" --json url 2>/dev/null; then
        log_success "GitOps repository verified"
    else
        log_error "Could not verify GitOps repository. Make sure it's created and accessible."
        return 1
    fi
}

# Step 2: Clone and Setup GitOps Repository
setup_gitops_structure() {
    log_section "Step 2: Setting Up GitOps Repository Structure"
    
    TEMP_DIR="/tmp/ptuddn-t3-argocd-setup"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    cd "$TEMP_DIR"
    
    log_info "Cloning GitOps repository..."
    git clone "${GITOPS_REPO_URL}" . || {
        log_error "Failed to clone repository"
        return 1
    }
    
    log_info "Creating directory structure..."
    mkdir -p demo-app/{templates,envs/{dev,staging,production}}
    mkdir -p argocd-apps
    mkdir -p scripts
    
    # Create Chart.yaml
    log_info "Creating Helm Chart..."
    cat > demo-app/Chart.yaml <<'EOF'
apiVersion: v2
name: demo-app
description: A Helm chart for deploying ptuddn-t3 Spring Boot application
type: application
version: 1.0.0
appVersion: "1.0.0"
home: https://github.com/minhtran1015/ptuddn-t3
sources:
  - https://github.com/minhtran1015/ptuddn-t3
maintainers:
  - name: Demo User
    email: demo@example.com
EOF
    
    # Create values.yaml
    log_info "Creating Helm values..."
    cat > demo-app/values.yaml <<'EOF'
replicaCount: 3

image:
  repository: ghcr.io/minhtran1015/ptuddn-t3
  pullPolicy: Always
  tag: "main-latest"

imagePullSecrets:
  - name: registry-credentials

serviceAccount:
  create: true
  name: "demo-app"

service:
  type: ClusterIP
  port: 80
  targetPort: 8081

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

env:
  SPRING_PROFILES_ACTIVE: production
  APP_JWT_EXPIRATION: "86400000"

secrets:
  APP_JWT_SECRET: "your-secret-key-change-in-production"
  SPRING_DATASOURCE_USERNAME: demouser
  SPRING_DATASOURCE_PASSWORD: demopassword

database:
  enabled: true
  host: mysql
  port: 3306
  name: demoapp
EOF
    
    # Create ArgoCD Application
    log_info "Creating ArgoCD Application manifest..."
    cat > argocd-apps/demo-app-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${GITOPS_REPO_URL%%.git}
    targetRevision: main
    path: demo-app
    helm:
      releaseName: demo-app
      values: |
        replicaCount: 3
        image:
          repository: ghcr.io/minhtran1015/ptuddn-t3
          tag: main-latest
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
EOF
    
    # Create README
    cat > README.md <<'EOF'
# ptuddn-t3-argocd

GitOps repository for ptuddn-t3 Spring Boot application deployments using ArgoCD.

## Repository Structure

```
ptuddn-t3-argocd/
├── demo-app/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── argocd-apps/
│   └── demo-app-app.yaml
├── scripts/
└── README.md
```

## How It Works

1. Push code to ptuddn-t3 repository
2. GitHub Actions builds and pushes Docker image
3. CI/CD workflow updates image tag in values.yaml
4. ArgoCD detects changes and syncs automatically
5. Kubernetes applies new deployment

## Manual Operations

```bash
# View applications
kubectl get applications -n argocd

# Sync application
argocd app sync demo-app

# View deployment status
kubectl get all -n demo-app
```
EOF
    
    # Commit and push
    log_info "Committing initial setup..."
    git add .
    git commit -m "Initial GitOps repository setup"
    
    log_info "Pushing to GitHub..."
    git push origin main
    
    log_success "GitOps repository configured"
    
    cd - > /dev/null
}

# Step 3: Set GitHub Secrets
setup_github_secrets() {
    log_section "Step 3: Configuring GitHub Secrets"
    
    REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\).git/\1/')
    
    log_info "Repository: $REPO"
    
    # Get GitOps repo URL
    GITOPS_REPO_URL="https://github.com/$(gh api user -q '.login')/ptuddn-t3-argocd.git"
    
    # Set ARGOCD_REPO
    log_info "Setting ARGOCD_REPO secret..."
    echo "$GITOPS_REPO_URL" | gh secret set ARGOCD_REPO -R "$REPO"
    log_success "ARGOCD_REPO set"
    
    # Get GitHub token
    log_info "Getting current GitHub token..."
    GH_TOKEN=$(gh auth token)
    
    # Set ARGOCD_TOKEN
    log_info "Setting ARGOCD_TOKEN secret..."
    echo "$GH_TOKEN" | gh secret set ARGOCD_TOKEN -R "$REPO"
    log_success "ARGOCD_TOKEN set"
    
    log_info "GitHub secrets configured successfully!"
}

# Step 4: Create Kubernetes demo-app namespace
setup_k8s_namespace() {
    log_section "Step 4: Setting Up Kubernetes Namespace"
    
    log_info "Creating demo-app namespace..."
    kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f -
    log_success "Namespace created"
    
    # Create registry credentials (if needed)
    log_info "Creating image pull secret..."
    kubectl create secret docker-registry registry-credentials \
        --docker-server=ghcr.io \
        --docker-username=$(gh api user -q '.login') \
        --docker-password="$GH_TOKEN" \
        -n demo-app \
        --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
    
    log_success "Registry credentials configured"
}

# Step 5: Verify Setup
verify_setup() {
    log_section "Step 5: Verifying Setup"
    
    # Check GitHub secrets
    SECRETS=$(gh secret list | wc -l)
    if [ $SECRETS -ge 2 ]; then
        log_success "GitHub secrets configured ($SECRETS secrets found)"
    else
        log_warning "GitHub secrets may not be fully configured"
    fi
    
    # Check ArgoCD
    if kubectl get namespace argocd &> /dev/null; then
        log_success "ArgoCD namespace exists"
        
        ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers | wc -l)
        log_success "ArgoCD pods running: $ARGOCD_PODS"
    else
        log_error "ArgoCD not found"
    fi
    
    # Check demo-app namespace
    if kubectl get namespace demo-app &> /dev/null; then
        log_success "demo-app namespace exists"
    else
        log_warning "demo-app namespace not yet created"
    fi
}

# Step 6: Display Access Information
display_info() {
    log_section "Setup Complete! 🎉"
    
    echo ""
    echo -e "${GREEN}ArgoCD Access Information:${NC}"
    echo "  UI URL: https://localhost:8080"
    echo "  Username: admin"
    echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
    echo ""
    echo "  To access: kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo ""
    
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Set up port forwarding to ArgoCD"
    echo "  2. Access ArgoCD UI to verify it can see the demo-app application"
    echo "  3. Make a test commit to ptuddn-t3 to trigger CI/CD"
    echo "  4. Monitor the workflow at: https://github.com/$REPO/actions"
    echo ""
    
    echo -e "${GREEN}Useful Commands:${NC}"
    echo "  kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo "  kubectl get all -n demo-app"
    echo "  kubectl logs -f deployment/demo-app -n demo-app"
    echo "  argocd app list"
    echo ""
}

# Main execution
main() {
    log_section "🚀 CI/CD Pipeline Complete Setup"
    
    check_prerequisites || {
        log_error "Prerequisites check failed"
        return 1
    }
    
    create_gitops_repo || {
        log_error "Failed to create GitOps repository"
        return 1
    }
    
    setup_gitops_structure || {
        log_error "Failed to set up GitOps structure"
        return 1
    }
    
    setup_github_secrets || {
        log_error "Failed to set up GitHub secrets"
        return 1
    }
    
    setup_k8s_namespace || {
        log_warning "Failed to set up Kubernetes namespace"
    }
    
    verify_setup
    
    display_info
    
    log_success "✓ All setup steps completed!"
}

# Run main
main
