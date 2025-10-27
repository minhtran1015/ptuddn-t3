#!/bin/bash

# CI/CD Pipeline Status Checker
# This script checks the current status of the CI/CD pipeline setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

# Logging functions
log_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARN++))
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

# 1. Check GitHub Actions Files
log_section "1. GitHub Actions Workflows"

if [ -f ".github/workflows/ci-build.yml" ]; then
    log_pass "CI Build workflow exists"
else
    log_fail "CI Build workflow missing"
fi

if [ -f ".github/workflows/cd-deploy.yml" ]; then
    log_pass "CD Deploy workflow exists"
else
    log_fail "CD Deploy workflow missing"
fi

if [ -f ".github/workflows/manual-deploy.yml" ]; then
    log_pass "Manual Deploy workflow exists"
else
    log_fail "Manual Deploy workflow missing"
fi

# 2. Check Kubernetes Manifests
log_section "2. Kubernetes Manifests"

k8s_files=("namespace.yaml" "deployment.yaml" "service.yaml" "configmap.yaml" "secret.yaml" "ingress.yaml" "hpa.yaml" "pdb.yaml" "servicemonitor.yaml")

for file in "${k8s_files[@]}"; do
    if [ -f "k8s/$file" ]; then
        log_pass "k8s/$file exists"
    else
        log_fail "k8s/$file missing"
    fi
done

# 3. Check Helm Chart
log_section "3. Helm Chart"

if [ -f "helm/Chart.yaml" ]; then
    log_pass "Helm Chart.yaml exists"
else
    log_fail "Helm Chart.yaml missing"
fi

if [ -f "helm/values.yaml" ]; then
    log_pass "Helm values.yaml exists"
else
    log_fail "Helm values.yaml missing"
fi

# 4. Check ArgoCD Configuration
log_section "4. ArgoCD Configuration"

if [ -f ".argocd/application.yaml" ]; then
    log_pass "ArgoCD application.yaml exists"
    # Check if repository URL is set
    if grep -q "ptuddn-t3-argocd" ".argocd/application.yaml"; then
        log_pass "ArgoCD repository URL appears to be set"
    else
        log_warn "ArgoCD repository URL may not be configured"
    fi
else
    log_fail "ArgoCD application.yaml missing"
fi

# 5. Check Helper Scripts
log_section "5. Helper Scripts"

scripts=("install-argocd.sh" "setup-github-secrets.sh" "deploy-to-k8s.sh")

for script in "${scripts[@]}"; do
    if [ -f "scripts/$script" ]; then
        if [ -x "scripts/$script" ]; then
            log_pass "scripts/$script is executable"
        else
            log_warn "scripts/$script exists but is not executable"
        fi
    else
        log_fail "scripts/$script missing"
    fi
done

# 6. Check CLI Tools
log_section "6. Required CLI Tools"

if command -v kubectl &> /dev/null; then
    log_pass "kubectl installed"
    # Try to get cluster info
    if kubectl cluster-info &> /dev/null; then
        log_pass "kubectl can connect to cluster"
        CLUSTER_AVAILABLE=1
    else
        log_warn "kubectl installed but cannot connect to cluster"
        CLUSTER_AVAILABLE=0
    fi
else
    log_fail "kubectl not installed"
    CLUSTER_AVAILABLE=0
fi

if command -v helm &> /dev/null; then
    log_pass "helm installed"
else
    log_warn "helm not installed (optional but recommended)"
fi

if command -v docker &> /dev/null; then
    log_pass "docker installed"
else
    log_fail "docker not installed"
fi

if command -v git &> /dev/null; then
    log_pass "git installed"
else
    log_fail "git not installed"
fi

if command -v gh &> /dev/null; then
    log_pass "GitHub CLI installed"
else
    log_warn "GitHub CLI not installed (optional)"
fi

# 7. Check Kubernetes Cluster (if available)
if [ $CLUSTER_AVAILABLE -eq 1 ]; then
    log_section "7. Kubernetes Cluster Status"
    
    if kubectl get namespace argocd &> /dev/null; then
        log_pass "ArgoCD namespace exists"
        
        # Check ArgoCD pods
        running_pods=$(kubectl get pods -n argocd -q 2>/dev/null | wc -l)
        if [ $running_pods -gt 0 ]; then
            log_pass "ArgoCD pods are present ($running_pods pods)"
        else
            log_warn "ArgoCD namespace exists but no pods running"
        fi
    else
        log_fail "ArgoCD namespace not found (ArgoCD not installed)"
    fi
    
    if kubectl get namespace demo-app &> /dev/null; then
        log_pass "demo-app namespace exists"
    else
        log_warn "demo-app namespace not found"
    fi
fi

# 8. Check Documentation
log_section "8. Documentation"

docs=("CI_CD_PIPELINE.md" "QUICKSTART_CICD.md" "IMPLEMENTATION_CHECKLIST.md" "ARGOCD_REPO_SETUP.md" "CICD_IMPLEMENTATION_SUMMARY.md")

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        log_pass "$doc exists"
    else
        log_fail "$doc missing"
    fi
done

# 9. GitHub Secrets Check
log_section "9. GitHub Secrets Configuration"

if command -v gh &> /dev/null; then
    # Try to get repository info
    REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\).git/\1/' 2>/dev/null)
    
    if [ ! -z "$REPO" ]; then
        log_info "Repository: $REPO"
        
        # Check secrets
        if gh secret list -R "$REPO" &> /dev/null; then
            secrets=$(gh secret list -R "$REPO" 2>/dev/null | wc -l)
            if [ $secrets -gt 0 ]; then
                log_pass "GitHub secrets configured ($secrets secret(s) found)"
            else
                log_warn "No GitHub secrets configured"
            fi
        else
            log_warn "Cannot access GitHub repository secrets (may need authentication)"
        fi
    else
        log_warn "Cannot determine GitHub repository from git remote"
    fi
else
    log_warn "GitHub CLI not installed - cannot check secrets"
fi

# 10. Summary
log_section "SUMMARY"

echo ""
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo -e "${YELLOW}Warnings: $WARN${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    log_info "✓ All critical checks passed!"
    echo ""
    echo "Next steps:"
    echo "1. If ArgoCD is not installed, run: ./scripts/install-argocd.sh"
    echo "2. If GitHub secrets not set, run: ./scripts/setup-github-secrets.sh"
    echo "3. Create GitOps repository: ptuddn-t3-argocd"
    echo "4. Test the pipeline by pushing a change"
else
    log_warn "⚠ Some critical components are missing"
    echo ""
    echo "Next steps:"
    echo "1. Review the failures above"
    echo "2. Run the setup scripts to install missing components"
    echo "3. Re-run this script to verify"
fi

echo ""
