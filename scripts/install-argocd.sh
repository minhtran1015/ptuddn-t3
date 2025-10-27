#!/bin/bash

# ArgoCD Installation Script
# This script automates the installation and basic configuration of ArgoCD

set -e

NAMESPACE="argocd"
VERSION="v2.10.0"
REPO_URL="https://github.com/minhtran1015/ptuddn-t3-argocd"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        log_warn "helm is not installed, but it's optional"
    fi
    
    log_info "Prerequisites check passed"
}

# Create namespace
create_namespace() {
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    log_info "Namespace created successfully"
}

# Install ArgoCD
install_argocd() {
    log_info "Installing ArgoCD version: $VERSION"
    
    kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$VERSION/manifests/install.yaml
    
    log_info "Waiting for ArgoCD to be ready..."
    kubectl wait -n $NAMESPACE --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=300s
    
    log_info "ArgoCD installed successfully"
}

# Get admin password
get_admin_password() {
    log_info "Retrieving ArgoCD admin password..."
    
    # Wait for secret to be created
    sleep 5
    
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "")
    
    if [ -z "$ARGOCD_PASSWORD" ]; then
        log_warn "Admin password not yet available, please retrieve it manually"
        return 1
    fi
    
    echo $ARGOCD_PASSWORD
}

# Configure ArgoCD
configure_argocd() {
    log_info "Configuring ArgoCD..."
    
    # Port forward ArgoCD
    log_info "Starting port forward on localhost:8080"
    kubectl port-forward -n $NAMESPACE svc/argocd-server 8080:443 &
    PORT_FORWARD_PID=$!
    
    sleep 3
    
    # Install ArgoCD CLI if not present
    if ! command -v argocd &> /dev/null; then
        log_info "Installing ArgoCD CLI..."
        curl -sSL -o /tmp/argocd-install.sh https://raw.githubusercontent.com/argoproj/argo-cd/$VERSION/manifests/install.sh
        chmod +x /tmp/argocd-install.sh
        /tmp/argocd-install.sh
    fi
    
    # Get password
    ARGOCD_PASSWORD=$(get_admin_password)
    if [ -z "$ARGOCD_PASSWORD" ]; then
        log_error "Failed to retrieve admin password"
        kill $PORT_FORWARD_PID
        return 1
    fi
    
    # Login
    log_info "Logging into ArgoCD..."
    argocd login localhost:8080 \
        --username admin \
        --password $ARGOCD_PASSWORD \
        --insecure \
        || log_warn "ArgoCD login may have issues, continue..."
    
    # Kill port forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    log_info "ArgoCD configuration completed"
}

# Display access information
display_info() {
    log_info "============================================"
    log_info "ArgoCD Installation Completed!"
    log_info "============================================"
    echo ""
    echo "To access ArgoCD UI:"
    echo "  kubectl port-forward -n $NAMESPACE svc/argocd-server 8080:443"
    echo "  Open: https://localhost:8080"
    echo ""
    echo "Default credentials:"
    echo "  Username: admin"
    echo "  Password: $(get_admin_password)"
    echo ""
    echo "To access with ArgoCD CLI:"
    echo "  argocd login <ARGOCD_SERVER>"
    echo ""
}

# Main execution
main() {
    log_info "Starting ArgoCD installation..."
    
    check_prerequisites
    create_namespace
    install_argocd
    configure_argocd
    display_info
    
    log_info "Installation completed successfully!"
}

# Run main
main
