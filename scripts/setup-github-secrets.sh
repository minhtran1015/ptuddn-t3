#!/bin/bash

# Setup GitHub Actions Secrets
# This script helps configure required GitHub secrets for CI/CD pipeline

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed"
    log_info "Install from: https://cli.github.com/"
    exit 1
fi

# Get repository
REPO="minhtran1015/ptuddn-t3"
read -p "Enter GitHub repository (default: $REPO): " input_repo
REPO="${input_repo:-$REPO}"

log_info "Configuring secrets for repository: $REPO"

# Function to set secret
set_secret() {
    local secret_name=$1
    local prompt=$2
    local is_sensitive=${3:-false}
    
    read -p "$prompt: " -s secret_value
    echo ""
    
    if [ -z "$secret_value" ]; then
        log_warn "Skipping $secret_name"
        return 1
    fi
    
    echo "$secret_value" | gh secret set $secret_name -R $REPO
    log_info "✓ $secret_name configured"
}

echo ""
log_info "================================================"
log_info "Setting up GitHub Actions Secrets"
log_info "================================================"
echo ""

# Docker Registry - Usually auto-managed
log_info "Note: GITHUB_TOKEN is automatically provided by GitHub Actions"

# ArgoCD Configuration
echo ""
log_info "ArgoCD Configuration:"
set_secret "ARGOCD_REPO" "Enter ArgoCD GitOps repository URL (e.g., https://github.com/user/ptuddn-t3-argocd)"

set_secret "ARGOCD_TOKEN" "Enter GitHub Personal Access Token (for ArgoCD repo access)"

# SonarQube Configuration (Optional)
echo ""
log_info "SonarQube Configuration (Optional):"
read -p "Do you want to set up SonarQube? (y/n): " setup_sonar

if [[ $setup_sonar == "y" ]]; then
    set_secret "SONAR_HOST_URL" "Enter SonarQube host URL (e.g., https://sonarqube.example.com)"
    set_secret "SONAR_TOKEN" "Enter SonarQube project token"
fi

# Slack Integration (Optional)
echo ""
log_info "Slack Integration (Optional):"
read -p "Do you want to set up Slack notifications? (y/n): " setup_slack

if [[ $setup_slack == "y" ]]; then
    set_secret "SLACK_WEBHOOK" "Enter Slack webhook URL"
fi

# Verify secrets
echo ""
log_info "================================================"
log_info "Verifying Secrets"
log_info "================================================"
echo ""

gh secret list -R $REPO

echo ""
log_info "✓ GitHub Actions secrets configured successfully!"
log_info "You can now run the CI/CD workflows"
