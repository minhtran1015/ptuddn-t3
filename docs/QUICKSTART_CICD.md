# CI/CD Pipeline - Quick Start Guide

## Overview

This guide provides step-by-step instructions to set up and run the complete CI/CD pipeline using GitHub Actions and ArgoCD.

## Prerequisites

- GitHub account with repository access
- Kubernetes cluster (v1.24+) or minikube for testing
- `kubectl` installed and configured
- `helm` 3.0+ installed
- `git` installed
- `gh` CLI installed (optional but recommended)

## 10-Minute Quick Start

### Step 1: Fork and Clone Repository

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ptuddn-t3.git
cd ptuddn-t3

# Add upstream remote
git remote add upstream https://github.com/minhtran1015/ptuddn-t3.git
```

### Step 2: Create GitHub Personal Access Token

1. Go to GitHub: Settings > Developer settings > Personal access tokens
2. Click "Tokens (classic)"
3. Click "Generate new token (classic)"
4. Add scopes: `repo`, `workflow`, `read:packages`, `write:packages`
5. Copy the token (save it somewhere safe)

### Step 3: Create ArgoCD GitOps Repository

1. Create new repository: `ptuddn-t3-argocd`
2. Copy structure from guide (see ARGOCD_REPO_SETUP.md)
3. Push to GitHub

### Step 4: Configure GitHub Secrets

```bash
# Make script executable
chmod +x scripts/setup-github-secrets.sh

# Run setup script
./scripts/setup-github-secrets.sh

# It will prompt for:
# - ARGOCD_REPO: https://github.com/YOUR_USERNAME/ptuddn-t3-argocd
# - ARGOCD_TOKEN: Your personal access token
# - SLACK_WEBHOOK: (optional) Your Slack webhook
```

**Or manually set secrets:**

1. Go to repository: Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Add each secret:

```
Name: ARGOCD_REPO
Value: https://github.com/YOUR_USERNAME/ptuddn-t3-argocd

Name: ARGOCD_TOKEN
Value: Your GitHub Personal Access Token

Name: SLACK_WEBHOOK (optional)
Value: Your Slack webhook URL
```

### Step 5: Install ArgoCD

```bash
# Make script executable
chmod +x scripts/install-argocd.sh

# Run installation
./scripts/install-argocd.sh

# This will output:
# - ArgoCD UI URL: https://localhost:8080
# - Admin username: admin
# - Admin password: (displayed in output)
```

**Or manual installation:**

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.0/manifests/install.yaml

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Access: https://localhost:8080
```

### Step 6: Configure ArgoCD Application

1. Access ArgoCD UI: https://localhost:8080
2. Login with admin credentials
3. Click "New Application" or apply manifest:

```bash
kubectl apply -f .argocd/application.yaml
```

### Step 7: Deploy Application to Kubernetes

```bash
# Make script executable
chmod +x scripts/deploy-to-k8s.sh

# Run deployment
./scripts/deploy-to-k8s.sh production

# Choose deployment method:
# 1: kubectl (uses raw manifests)
# 2: helm (uses Helm charts)

# Wait for deployment to complete
```

### Step 8: Test the Pipeline

**Trigger CI/CD pipeline:**

```bash
# Make a small change
echo "# Updated" >> README.md

# Push to main branch
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

**Monitor pipeline:**

1. Go to GitHub repository > Actions tab
2. View the running workflow
3. Wait for CI build to complete
4. Check if Docker image was pushed to GHCR
5. Monitor ArgoCD sync in ArgoCD UI
6. Verify pod is running:

```bash
kubectl get pods -n demo-app -w
```

## Common Tasks

### Check Application Status

```bash
# Deployment status
kubectl get deployment -n demo-app

# Pod status
kubectl get pods -n demo-app

# Service status
kubectl get svc -n demo-app

# View logs
kubectl logs -f -n demo-app deployment/demo-app
```

### Access Application

```bash
# Port forward
kubectl port-forward -n demo-app svc/demo-app 8081:80

# Access locally
curl http://localhost:8081/actuator/health
```

### Check ArgoCD Sync

```bash
# Get application status
argocd app get demo-app

# Sync manually
argocd app sync demo-app

# View sync history
argocd app history demo-app
```

### View Docker Image

```bash
# Pull image
docker pull ghcr.io/minhtran1015/ptuddn-t3:main-latest

# View available tags
curl https://api.github.com/repos/minhtran1015/ptuddn-t3/packages/container/ptuddn-t3/versions
```

## Troubleshooting

### GitHub Actions Workflow Fails

1. Go to Actions tab > Failed workflow
2. Click the failed job
3. Expand steps to see detailed logs
4. Common issues:
   - Missing secrets: Check GitHub > Settings > Secrets
   - Build errors: Check test results in artifacts
   - Docker push errors: Check registry credentials

### ArgoCD Sync Fails

```bash
# Check app status
argocd app get demo-app

# View sync details
argocd app wait demo-app --timeout 5s

# Check resource status
kubectl describe app demo-app -n argocd

# View events
kubectl get events -n demo-app --sort-by='.lastTimestamp'
```

### Kubernetes Deployment Issues

```bash
# Check pod logs
kubectl logs -n demo-app <pod-name>

# Check pod events
kubectl describe pod -n demo-app <pod-name>

# Check deployment events
kubectl describe deployment -n demo-app demo-app

# Check resource usage
kubectl top pod -n demo-app
```

### Cannot Connect to Kubernetes

```bash
# Verify cluster connection
kubectl cluster-info

# Check kubeconfig
cat ~/.kube/config

# Update kubeconfig
# For minikube: minikube update-context
# For cloud: Follow cloud provider's kubectl setup
```

## Next Steps

1. **Configure monitoring:**
   - Install Prometheus and Grafana
   - Enable ServiceMonitor in deployment
   - Set up alerting rules

2. **Set up logging:**
   - Install ELK Stack or Loki
   - Configure log aggregation
   - Set up log analysis dashboards

3. **Implement security:**
   - Enable NetworkPolicies
   - Set up Pod Security Policies
   - Configure RBAC roles
   - Enable admission webhooks

4. **Setup database:**
   - Deploy MySQL in production
   - Configure persistent volumes
   - Set up automated backups
   - Configure replication

5. **Advanced deployments:**
   - Setup multi-environment deployments
   - Configure feature flags
   - Implement blue-green deployments
   - Setup canary deployments

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-kubernetes/)

## Support

For issues or questions:
1. Check CI_CD_PIPELINE.md for detailed documentation
2. Review troubleshooting section above
3. Check logs: `kubectl logs -n demo-app deployment/demo-app`
4. Create GitHub issue with detailed description

---

Happy deploying! 🚀
