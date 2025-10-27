#!/bin/bash

# Kubernetes Deployment Script
# Deploy application to Kubernetes cluster

set -e

NAMESPACE="demo-app"
ENVIRONMENT="${1:-production}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        log_warn "helm is not installed"
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Create namespace
create_namespace() {
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
}

# Create registry credentials
create_registry_credentials() {
    log_info "Creating Docker registry credentials..."
    
    REGISTRY_USER=${REGISTRY_USER:-$GITHUB_ACTOR}
    
    read -sp "Enter GitHub token or Docker registry password: " REGISTRY_PASSWORD
    echo ""
    
    kubectl create secret docker-registry registry-credentials \
        --docker-server=ghcr.io \
        --docker-username=$REGISTRY_USER \
        --docker-password=$REGISTRY_PASSWORD \
        --docker-email=user@example.com \
        -n $NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_info "Registry credentials created"
}

# Deploy using kubectl
deploy_with_kubectl() {
    log_info "Deploying with kubectl..."
    
    # Create namespace and resources
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmap.yaml -n $NAMESPACE
    kubectl apply -f k8s/secret.yaml -n $NAMESPACE
    kubectl apply -f k8s/deployment.yaml -n $NAMESPACE
    kubectl apply -f k8s/service.yaml -n $NAMESPACE
    kubectl apply -f k8s/ingress.yaml -n $NAMESPACE
    kubectl apply -f k8s/hpa.yaml -n $NAMESPACE
    kubectl apply -f k8s/pdb.yaml -n $NAMESPACE
    kubectl apply -f k8s/servicemonitor.yaml -n $NAMESPACE 2>/dev/null || log_warn "ServiceMonitor not applied (Prometheus not installed?)"
    
    log_info "Deployment completed"
}

# Deploy using Helm
deploy_with_helm() {
    log_info "Deploying with Helm..."
    
    helm upgrade --install demo-app ./helm \
        -n $NAMESPACE \
        --create-namespace \
        --values helm/values.yaml
    
    log_info "Helm deployment completed"
}

# Wait for deployment
wait_for_deployment() {
    log_info "Waiting for deployment to be ready..."
    
    kubectl wait -n $NAMESPACE \
        --for=condition=available \
        --timeout=300s \
        deployment/demo-app
    
    log_info "Deployment is ready"
}

# Verify deployment
verify_deployment() {
    log_info "================================================"
    log_info "Deployment Verification"
    log_info "================================================"
    echo ""
    
    echo "Namespace:"
    kubectl get namespace $NAMESPACE
    echo ""
    
    echo "Deployments:"
    kubectl get deployments -n $NAMESPACE
    echo ""
    
    echo "Pods:"
    kubectl get pods -n $NAMESPACE
    echo ""
    
    echo "Services:"
    kubectl get svc -n $NAMESPACE
    echo ""
    
    echo "Ingress:"
    kubectl get ingress -n $NAMESPACE
    echo ""
    
    echo "HPA Status:"
    kubectl get hpa -n $NAMESPACE
    echo ""
    
    # Get pod details
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=demo-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$POD_NAME" ]; then
        echo "Pod Status:"
        kubectl describe pod $POD_NAME -n $NAMESPACE
    fi
}

# Display access information
display_access_info() {
    log_info "================================================"
    log_info "Application Access Information"
    log_info "================================================"
    echo ""
    
    SERVICE_IP=$(kubectl get svc demo-app -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    INGRESS_HOST=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "")
    
    echo "Service Type: ClusterIP"
    echo ""
    
    if [ -n "$INGRESS_HOST" ]; then
        echo "Ingress Host: $INGRESS_HOST"
        echo "Access URL: https://$INGRESS_HOST"
    fi
    
    echo ""
    echo "To access application locally:"
    echo "  kubectl port-forward -n $NAMESPACE svc/demo-app 8081:80"
    echo "  Open: http://localhost:8081"
    echo ""
    
    echo "To view logs:"
    echo "  kubectl logs -f -n $NAMESPACE deployment/demo-app"
}

# Main execution
main() {
    log_info "================================================"
    log_info "Kubernetes Deployment Script"
    log_info "Environment: $ENVIRONMENT"
    log_info "================================================"
    echo ""
    
    check_prerequisites
    
    read -p "Choose deployment method (1: kubectl, 2: helm): " deploy_method
    
    if [ "$deploy_method" = "2" ]; then
        deploy_with_helm
    else
        create_namespace
        create_registry_credentials
        deploy_with_kubectl
    fi
    
    wait_for_deployment
    verify_deployment
    display_access_info
    
    log_info "Deployment completed successfully!"
}

main
