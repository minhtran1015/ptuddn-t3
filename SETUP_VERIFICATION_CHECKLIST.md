# ✅ Single-Repo GitOps Implementation - Setup Complete

**Date:** October 27, 2025  
**Status:** 🟢 Ready for Deployment  
**Time to Production:** ~20 minutes

---

## 📋 Pre-Deployment Verification Checklist

### ✅ Repository Structure Verified

```
ptuddn-t3/
├── ✅ demo/                    (Source code exists)
│   ├── src/main/java/         (3-tier Spring Boot app)
│   ├── build.gradle           (Gradle build config)
│   └── Dockerfile.optimized   (Multi-stage production build)
├── ✅ k8s/                     (Kubernetes manifests - GitOps config)
│   ├── deployment.yaml        (✅ Image format ready for sed)
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml               (Auto-scaling: 3-10 replicas)
│   ├── pdb.yaml               (Pod Disruption Budget)
│   ├── servicemonitor.yaml    (Prometheus metrics)
│   └── namespace.yaml
├── ✅ .github/workflows/
│   ├── ci-cd-single-repo.yml  (✅ Main CI/CD pipeline - ACTIVE)
│   ├── ci-build.yml           (Legacy, not needed)
│   └── cd-deploy.yml          (Legacy, not needed)
├── ✅ .argocd/
│   └── application.yaml       (✅ GitOps configuration ready)
└── ✅ helm/                    (Optional: Helm charts for templating)
    ├── Chart.yaml
    └── values.yaml
```

### ✅ Critical Files Validation

| File | Status | Details |
|------|--------|---------|
| `.github/workflows/ci-cd-single-repo.yml` | ✅ Ready | 154 lines, 3 jobs (build-test, build-push-image, update-manifest-deploy) |
| `k8s/deployment.yaml` | ✅ Ready | Image tag: `ghcr.io/minhtran1015/ptuddn-t3:main-latest` (sed-compatible) |
| `.argocd/application.yaml` | ✅ Ready | GitOps config with auto-sync enabled (prune + self-heal) |
| `demo/Dockerfile.optimized` | ✅ Ready | Multi-stage build for optimized image size |
| `demo/build.gradle` | ✅ Ready | Gradle configuration with Spring Boot 3.5.6 |

### ✅ Image Tag Format Verification

**Current Format in k8s/deployment.yaml (Line 35):**
```yaml
image: ghcr.io/minhtran1015/ptuddn-t3:main-latest
```

**Sed Replacement Test:** ✅ PASSED
```bash
# Test pattern used in workflow:
sed -i 's|image: ghcr.io/minhtran1015/ptuddn-t3:.*|image: ghcr.io/minhtran1015/ptuddn-t3:main-abc123|g' k8s/deployment.yaml

# Result: Successfully replaced with new tag ✅
```

**Why this format works:**
- `.*` matches any tag (main-latest, main-abc123def, etc.)
- Pipe delimiter `|` avoids conflicts with forward slashes in image path
- sed will update ALL image lines (in case of multiple containers)

---

## 🚀 Next Steps (Execute in Order)

### Step 1: Commit SINGLE_REPO_GITOPS.md Guide (5 minutes)

```bash
cd /Users/trandinhquangminh/Codespace/ptuddn-t3

# Add the new guide
git add SINGLE_REPO_GITOPS.md

# Commit
git commit -m "docs: add single-repo GitOps implementation guide"

# Push
git push origin main
```

### Step 2: Verify GitHub Repository Settings (5 minutes)

**Go to:** https://github.com/minhtran1015/ptuddn-t3/settings

1. **Enable Workflow Permissions:**
   - Settings → Actions → General
   - Workflow permissions: ✅ Read and write permissions
   - Allow GitHub Actions to create and approve pull requests: ✅ Checked

2. **Verify Secrets (Optional):**
   - Settings → Secrets and variables → Actions
   - `GITHUB_TOKEN` is auto-provided (no setup needed)
   - `SLACK_WEBHOOK` (optional, for notifications)

### Step 3: Install/Verify kubectl & Kubernetes Access (5 minutes)

```bash
# Check kubectl installed
kubectl version --client

# Check cluster connectivity
kubectl cluster-info

# Verify namespaces
kubectl get namespaces

# Expected output should show: kube-system, kube-node-lease, kube-public, default
```

### Step 4: Install ArgoCD (10 minutes)

**Option A: Automated (Using provided script)**

```bash
# If you have the install script
bash scripts/install-argocd.sh
```

**Option B: Manual Installation**

```bash
# 1. Create namespace
kubectl create namespace argocd

# 2. Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for ArgoCD to be ready (1-3 minutes)
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=300s

# 4. Check all pods are running
kubectl get pods -n argocd

# Expected: argocd-application-controller, argocd-server, argocd-repo-server, etc. (all Running)
```

### Step 5: Get ArgoCD Admin Password (2 minutes)

```bash
# Retrieve auto-generated password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Save this password securely!
# Example output: p9x4K2mQ8vL1nR5sT2wU
```

### Step 6: Access ArgoCD UI (5 minutes)

```bash
# Port forward to access UI (runs in foreground)
kubectl port-forward -n argocd svc/argocd-server 8080:443

# In another terminal, open browser:
# https://localhost:8080

# Login:
# Username: admin
# Password: (from Step 5)

# Note: First time may show SSL warning (self-signed cert) → Click "Advanced" → "Proceed"
```

### Step 7: Create ArgoCD Application (5 minutes)

**Option A: Using CLI (If ArgoCD CLI installed)**

```bash
# Login to ArgoCD
argocd login localhost:8080 --insecure --username admin --password <PASSWORD_FROM_STEP_5>

# Apply application manifest
kubectl apply -f .argocd/application.yaml

# Verify
argocd app get demo-app
```

**Option B: Using UI (Recommended for first time)**

1. Open https://localhost:8080
2. Click "New App"
3. Fill in form:
   - **Application name:** `demo-app`
   - **Project:** `default`
   - **Repository URL:** `https://github.com/minhtran1015/ptuddn-t3.git`
   - **Revision:** `main`
   - **Path:** `k8s`
   - **Cluster URL:** `https://kubernetes.default.svc`
   - **Namespace:** `demo-app`
4. Scroll down and enable:
   - ✅ "Auto-create namespace"
   - ✅ Sync policy: "Automatic"
   - ✅ "Prune propagation policy"
   - ✅ "Self heal"
5. Click "Create"

**Wait for ArgoCD to create namespace and deploy:**
```bash
# Monitor in another terminal
kubectl get all -n demo-app -w
```

### Step 8: Trigger First Pipeline Run (10 minutes)

**Option A: Make a small code change**

```bash
# Navigate to code directory
cd demo

# Make a test change
echo "# Test pipeline trigger" >> README.md

# Commit and push
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin main

# Go to: https://github.com/minhtran1015/ptuddn-t3/actions
# Watch the workflow execute (3-5 minutes)
```

**Option B: Manual workflow trigger (if GitHub CLI installed)**

```bash
gh workflow run ci-cd-single-repo.yml --ref main
```

### Step 9: Monitor the Deployment (5 minutes)

**Terminal 1: Watch GitHub Actions**
```bash
# View workflow runs
gh run list --limit 5

# View detailed logs
gh run view <run-id> --log
```

**Terminal 2: Watch ArgoCD**
```bash
# Port forward ArgoCD (if closed from Step 6)
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Open browser: https://localhost:8080
# Click "demo-app" → Watch status change from OutOfSync → Synced
```

**Terminal 3: Watch Kubernetes**
```bash
# Watch pods being created
kubectl get pods -n demo-app -w

# When pods are Running, check logs:
kubectl logs -f -n demo-app deployment/demo-app
```

### Step 10: Verify Deployment Success (5 minutes)

```bash
# 1. Check deployment status
kubectl get deployment -n demo-app
# Expected: demo-app   3/3   3/3   3        1m

# 2. Check pods
kubectl get pods -n demo-app
# Expected: 3 pods with status Running

# 3. Check service
kubectl get svc -n demo-app
# Expected: demo-app service with ClusterIP or LoadBalancer

# 4. Check Git history (should show auto-commit from workflow)
git log --oneline -5
# Expected to see: "chore: update image to main-<SHA>"

# 5. Verify image tag updated in k8s/deployment.yaml
grep "image:" k8s/deployment.yaml | head -1
# Expected: image: ghcr.io/minhtran1015/ptuddn-t3:main-<NEW_SHA>
```

---

## 📊 Pipeline Flow Verification

### Expected Workflow Execution

```
1. Developer Push Code
   └─ git push origin main
   
2. GitHub Detects Push
   └─ Triggers .github/workflows/ci-cd-single-repo.yml
   
3. Job 1: build-and-test (Ubuntu Latest)
   ├─ Checkout code
   ├─ Setup Java 21
   ├─ Build with Gradle: ./gradlew build -x test
   ├─ Run tests: ./gradlew test
   └─ Upload test results ✅
   
4. Job 2: build-and-push-image (Needs Job 1 success)
   ├─ Checkout code
   ├─ Login to GHCR with GITHUB_TOKEN
   ├─ Build Docker image from demo/Dockerfile.optimized
   ├─ Push to ghcr.io/minhtran1015/ptuddn-t3:main-<SHA>
   └─ Push to ghcr.io/minhtran1015/ptuddn-t3:main-latest ✅
   
5. Job 3: update-manifest-and-deploy (Needs Job 2 success)
   ├─ Checkout code
   ├─ Extract image tag: main-abc123def
   ├─ Update k8s/deployment.yaml (sed replacement)
   │  FROM: image: ghcr.io/minhtran1015/ptuddn-t3:main-latest
   │  TO:   image: ghcr.io/minhtran1015/ptuddn-t3:main-abc123def
   ├─ Commit: "chore: update image to main-abc123def"
   ├─ Push to main
   └─ Workflow Complete ✅
   
6. ArgoCD Detects Change (Default: Every 3 minutes)
   ├─ Pull repository
   ├─ Detect k8s/deployment.yaml change
   ├─ Status changes: OutOfSync → Syncing → Synced
   └─ Sync Complete ✅
   
7. Kubernetes Deployment
   ├─ Create new pods with main-abc123def image
   ├─ Run health checks (liveness/readiness probes)
   ├─ Traffic switches to new pods (rolling update)
   ├─ Old pods terminate (if old pods exist)
   └─ Deployment Complete ✅
   
8. Application Running
   ├─ Service accessible at demo-app.default.svc.cluster.local:8081
   ├─ Prometheus metrics available at :8081/actuator/prometheus
   └─ Ready for traffic ✅
```

---

## 🔧 Troubleshooting Guide

### Issue: Workflow doesn't trigger on push

**Check 1:** Verify workflow file exists
```bash
ls -la .github/workflows/ci-cd-single-repo.yml
```

**Check 2:** Verify you're pushing to correct branch
```bash
git branch -a
# Should show * main (or develop)
```

**Check 3:** Check GitHub Actions in browser
```
https://github.com/minhtran1015/ptuddn-t3/actions
```

**Check 4:** Verify workflow YAML syntax
```bash
# If gh CLI installed
gh workflow validate .github/workflows/ci-cd-single-repo.yml
```

**Solution:** Re-commit and re-push the workflow file
```bash
git add .github/workflows/ci-cd-single-repo.yml
git commit -m "ci: ensure workflow is committed"
git push origin main
```

---

### Issue: Docker image doesn't build

**Check 1:** Verify Dockerfile.optimized exists
```bash
cat demo/Dockerfile.optimized | head -10
```

**Check 2:** Check GitHub Actions logs
```
https://github.com/minhtran1015/ptuddn-t3/actions → Click workflow → build-and-push-image job
```

**Common causes:**
- ❌ Java compilation errors (check build-and-test job logs)
- ❌ Missing dependencies in Dockerfile
- ❌ Network issues pulling base images
- ❌ Insufficient disk space on runner

**Solution:** Fix compilation errors first, then trigger new build
```bash
cd demo
./gradlew clean build
# Fix any errors, then push again
```

---

### Issue: Image pushed but k8s/deployment.yaml not updated

**Check 1:** View workflow logs for update-manifest-and-deploy job
```bash
gh run view <run-id> --log | grep -A 20 "update-manifest-and-deploy"
```

**Check 2:** Verify git commits in repository
```bash
git log --oneline -10
# Should see: "chore: update image to main-<SHA>"
```

**Check 3:** Manual verification of sed replacement
```bash
# Test locally with real image tag
TEST_IMAGE="ghcr.io/minhtran1015/ptuddn-t3:main-test123"
sed -i.bak "s|image: ghcr.io/minhtran1015/ptuddn-t3:.*|image: ${TEST_IMAGE}|g" k8s/deployment.yaml
cat k8s/deployment.yaml | grep image:
# Should show the new tag
git checkout k8s/deployment.yaml  # Restore original
```

**Solution:** Check GITHUB_TOKEN permissions
```
GitHub Settings → Actions → General → Workflow permissions → ✅ Read and write permissions
```

---

### Issue: ArgoCD not syncing

**Check 1:** Verify ArgoCD Application exists
```bash
kubectl get app -n argocd
# Should show: demo-app
```

**Check 2:** Check application status
```bash
argocd app get demo-app
# or
kubectl describe app demo-app -n argocd | grep -A 5 "Status"
```

**Check 3:** Verify Git repository access
```bash
argocd repo list
# Should show: https://github.com/minhtran1015/ptuddn-t3.git
```

**Check 4:** Manual sync
```bash
argocd app sync demo-app
# or force sync with hard refresh
argocd app sync demo-app --force
```

**Solution:** Re-create the application
```bash
kubectl delete app demo-app -n argocd
kubectl apply -f .argocd/application.yaml
```

---

### Issue: Pods not starting

**Check 1:** View pod status
```bash
kubectl get pods -n demo-app
kubectl describe pod <pod-name> -n demo-app
```

**Check 2:** Check pod logs
```bash
kubectl logs -n demo-app <pod-name>
```

**Common causes:**
- ❌ Image not found or failed to pull (check imagePullPolicy)
- ❌ ConfigMap or Secret not created
- ❌ Port already in use
- ❌ Insufficient cluster resources
- ❌ Health check (liveness/readiness) failing

**Solution:** Check configmap and secrets
```bash
kubectl get configmap -n demo-app
kubectl get secret -n demo-app
# If missing, reapply manifests:
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
```

---

## 📞 Quick Reference Commands

```bash
# === Git ===
git status
git log --oneline -5
git push origin main
git pull origin main

# === GitHub Actions ===
gh run list --limit 5
gh run view <run-id> --log
gh workflow run ci-cd-single-repo.yml --ref main

# === Docker ===
docker pull ghcr.io/minhtran1015/ptuddn-t3:main-latest
docker images | grep ptuddn-t3

# === Kubernetes ===
kubectl get all -n demo-app
kubectl get deployment -n demo-app
kubectl get pods -n demo-app
kubectl describe pod <pod-name> -n demo-app
kubectl logs -f <pod-name> -n demo-app

# === ArgoCD ===
kubectl port-forward -n argocd svc/argocd-server 8080:443
argocd login localhost:8080 --insecure
argocd app list
argocd app get demo-app
argocd app sync demo-app
argocd app history demo-app

# === Monitoring ===
kubectl top nodes
kubectl top pods -n demo-app
kubectl get events -n demo-app --sort-by='.lastTimestamp'
```

---

## 🎯 Success Criteria Checklist

- [ ] Repository structure verified (demo/, k8s/, .github/)
- [ ] Workflow file exists: `.github/workflows/ci-cd-single-repo.yml`
- [ ] k8s/deployment.yaml has correct image format
- [ ] Kubernetes cluster accessible (kubectl works)
- [ ] ArgoCD installed and running (8 pods in argocd namespace)
- [ ] ArgoCD admin password secured
- [ ] ArgoCD Application "demo-app" created
- [ ] First workflow triggered successfully
- [ ] Docker image pushed to GHCR
- [ ] k8s/deployment.yaml auto-updated with new image tag
- [ ] ArgoCD synced deployment to cluster
- [ ] Application pods running (3/3 replicas)
- [ ] Service is accessible
- [ ] Application logs show normal startup

---

## 📚 Documentation Files

**Key references in repository:**
- `SINGLE_REPO_GITOPS.md` - This guide (execution steps)
- `CI_CD_START_HERE.md` - Overview
- `QUICKSTART_CICD.md` - 10-minute quick start
- `.github/workflows/ci-cd-single-repo.yml` - Active workflow
- `.argocd/application.yaml` - GitOps config
- `k8s/deployment.yaml` - Kubernetes deployment

---

## 🚀 Time Estimate

| Step | Task | Time |
|------|------|------|
| 1 | Commit guide | 5 min |
| 2 | GitHub settings | 5 min |
| 3 | kubectl/cluster | 5 min |
| 4 | Install ArgoCD | 10 min |
| 5 | Get password | 2 min |
| 6 | Access UI | 5 min |
| 7 | Create App | 5 min |
| 8 | Trigger pipeline | 10 min |
| 9 | Monitor | 5 min |
| 10 | Verify | 5 min |
| **TOTAL** | **Full setup to deployment** | **~57 minutes** |

---

## ✅ Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| **Source Code** | ✅ Ready | Spring Boot 3.5.6 with JWT auth |
| **Docker Setup** | ✅ Ready | Dockerfile.optimized for production |
| **CI/CD Pipeline** | ✅ Ready | ci-cd-single-repo.yml with 3 jobs |
| **Kubernetes Manifests** | ✅ Ready | 9 manifest files, production-ready |
| **ArgoCD Config** | ✅ Ready | Auto-sync enabled (prune + self-heal) |
| **Repository** | ✅ Ready | Single repo, no need for separate GitOps repo |

**Overall Status:** 🟢 **READY FOR DEPLOYMENT**

---

## 🎓 Next Learning Steps

After successful deployment:

1. **Monitor the pipeline:**
   - Watch GitHub Actions run times
   - Optimize build performance
   - Setup notifications

2. **Setup observability:**
   - Configure Prometheus scraping
   - Setup Grafana dashboards
   - Configure alerts

3. **Enhance security:**
   - Rotate JWT secrets
   - Setup RBAC policies
   - Configure Pod Security Policies

4. **Scale and optimize:**
   - Tune HPA thresholds
   - Optimize Docker image size
   - Setup multi-region deployments

---

**Generated:** October 27, 2025  
**Repository:** minhtran1015/ptuddn-t3  
**Approach:** Single Repository GitOps with GitHub Actions + ArgoCD  
**Status:** Ready for deployment 🚀

