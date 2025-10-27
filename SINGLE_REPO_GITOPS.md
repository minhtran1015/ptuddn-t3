# CI/CD Pipeline với 1 Repository - Single Repo GitOps

## 📋 Tổng Quan - Tại Sao 1 Repository?

**Lợi ích của Single Repository:**
- ✅ Đơn giản hơn - không cần quản lý 2 repos
- ✅ Tất cả code và config trong một nơi
- ✅ Dễ review và hiểu workflow
- ✅ Ít công việc setup hơn
- ✅ Vẫn tuân theo nguyên tắc GitOps

**Cấu trúc:**
```
ptuddn-t3/
├── demo/                          # Source code
│   ├── src/
│   ├── build.gradle
│   └── Dockerfile.optimized
├── k8s/                           # Kubernetes manifests (GitOps config)
│   ├── deployment.yaml            # ← GitHub Actions sẽ cập nhật image tag ở đây
│   ├── service.yaml
│   ├── configmap.yaml
│   └── ...
└── .github/
    └── workflows/
        └── ci-cd-single-repo.yml  # CI/CD pipeline
```

## 🚀 Quy Trình Hoạt Động

```
1. Developer push code → ptuddn-t3 (branch: main)
            ↓
2. GitHub Actions CI/CD triggers (.github/workflows/ci-cd-single-repo.yml)
   ├─ Build & Test
   ├─ Build Docker image
   ├─ Push to GHCR
   └─ Update image tag in k8s/deployment.yaml
            ↓
3. GitHub Actions commits change → ptuddn-t3 (k8s/deployment.yaml)
            ↓
4. ArgoCD detects change in Git
   ├─ Pull k8s/deployment.yaml
   └─ Apply to Kubernetes cluster
            ↓
5. Kubernetes deploys new version
   └─ Application running ✅
```

## 🔧 Thiết Lập

### Bước 1: Kiểm Tra Cấu Trúc Repository

```bash
# Verify ptuddn-t3 repository structure
ls -la
# Expected:
# demo/                    ← Source code
# k8s/                     ← Kubernetes manifests
# .github/workflows/       ← GitHub Actions

# Check k8s folder
ls -la k8s/
# Expected:
# deployment.yaml
# service.yaml
# configmap.yaml
# ...
```

### Bước 2: Cấu Hình GitHub Secrets

Repository Settings → Secrets and variables → Actions → New repository secret

**Cần thiết:**
```
GITHUB_TOKEN          → Auto-provided by GitHub (no action needed)
SLACK_WEBHOOK         → (Optional) Slack notifications
```

**Lưu ý:** `GITHUB_TOKEN` được GitHub tự động cung cấp, không cần setup thêm

### Bước 3: Cài Đặt ArgoCD

```bash
# 1. Tạo namespace
kubectl create namespace argocd

# 2. Cài đặt ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Chờ ArgoCD ready
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=300s

# 4. Lấy admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### Bước 4: Truy Cập ArgoCD UI

```bash
# Port forward
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Mở browser: https://localhost:8080
# Username: admin
# Password: (từ bước 3)
```

### Bước 5: Tạo ArgoCD Application

**Option A: Dùng CLI**

```bash
# Apply manifest
kubectl apply -f .argocd/application.yaml
```

**Option B: Dùng ArgoCD UI**

1. Click "New App"
2. Điền thông tin:
   - **Application name**: `demo-app`
   - **Project**: `default`
   - **Repository URL**: `https://github.com/minhtran1015/ptuddn-t3.git`
   - **Revision**: `main`
   - **Path**: `k8s`
   - **Cluster**: `https://kubernetes.default.svc`
   - **Namespace**: `demo-app`
3. Enable Auto-sync:
   - ✅ Prune
   - ✅ Self Heal
4. Click "Create"

## ✅ Kiểm Tra Pipeline

### Kiểm tra CI/CD Workflow

```bash
# Xem workflow file
cat .github/workflows/ci-cd-single-repo.yml

# Verify syntax
gh workflow validate .github/workflows/ci-cd-single-repo.yml
```

### Test Pipeline

**Option 1: Push code change**

```bash
# Tạo change nhỏ
echo "# Test" >> README.md

# Commit
git add README.md
git commit -m "Test CI/CD pipeline"

# Push to main
git push origin main

# Monitor GitHub Actions
# Vào: https://github.com/minhtran1015/ptuddn-t3/actions
```

**Option 2: Manual trigger**

```bash
# Dùng GitHub CLI
gh workflow run ci-cd-single-repo.yml --ref main
```

### Monitor Deployment

```bash
# 1. Watch GitHub Actions
gh run list --limit 1

# 2. Check Docker image pushed
docker pull ghcr.io/minhtran1015/ptuddn-t3:main-<SHA>

# 3. Verify k8s manifest updated
git log --oneline -5
# Should see: "chore: update image to main-<SHA>"

# 4. Check ArgoCD sync status
argocd app get demo-app

# 5. Verify Kubernetes deployment
kubectl get pods -n demo-app -w
kubectl get deployment -n demo-app

# 6. Check logs
kubectl logs -n demo-app deployment/demo-app -f
```

## 🔄 Workflow Chi Tiết

### Khi nào pipeline trigger?

```yaml
# .github/workflows/ci-cd-single-repo.yml

on:
  push:
    branches:
      - main      ← Trigger on main branch push
      - develop   ← Trigger on develop branch push
  pull_request:
    branches:
      - main      ← Trigger on PR to main
```

### 3 Jobs trong Pipeline

#### Job 1: build-and-test
- Compile Java code với Gradle
- Run unit tests
- Upload test results

#### Job 2: build-and-push-image
- Build Docker image (từ Dockerfile.optimized)
- Push to GitHub Container Registry (GHCR)
- Tags:
  - `main-latest` (latest on main branch)
  - `main-<commit-sha>` (specific commit)

#### Job 3: update-manifest-and-deploy
- Extract image tag (e.g., `main-abc123`)
- Update k8s/deployment.yaml với image tag mới:
  ```yaml
  image: ghcr.io/minhtran1015/ptuddn-t3:main-abc123
  ```
- Commit changes tự động
- Push back to repo
- ArgoCD auto-detect và deploy

## 📝 Cách Hoạt Động Chi Tiết

### 1. GitHub Actions Update Manifest

```bash
# Workflow trích xuất image tag
BRANCH="main"
SHA_SHORT="abc123def"
IMAGE_TAG="${BRANCH}-${SHA_SHORT}"
# Result: main-abc123def

# Update file k8s/deployment.yaml
sed -i 's|image: ghcr.io/minhtran1015/ptuddn-t3:.*|image: ghcr.io/minhtran1015/ptuddn-t3:main-abc123def|g' k8s/deployment.yaml

# Commit and push
git commit -m "chore: update image to main-abc123def"
git push origin main
```

### 2. ArgoCD Detect Changes

```bash
# ArgoCD watches Git repository (default interval: 3 minutes)
# Khi phát hiện k8s/deployment.yaml thay đổi:

argocd app get demo-app
# Status: OutOfSync (vì manifest trong Git khác với cluster)

argocd app sync demo-app
# Tự động apply manifest mới
```

### 3. Kubernetes Deploy

```bash
# Kubernetes rolling update
kubectl rollout status deployment/demo-app -n demo-app

# Pods terminate old version, start new version
# Health checks validate new pods
# Service routes traffic to new pods
```

## 🛠️ Troubleshooting

### Problem: Workflow không trigger

**Solution:**
1. Verify workflow file: `.github/workflows/ci-cd-single-repo.yml` tồn tại
2. Check branch: push phải vào `main` hoặc `develop`
3. Check syntax: `gh workflow validate .github/workflows/ci-cd-single-repo.yml`
4. Check logs: GitHub repo → Actions → view workflow runs

### Problem: Image không push

**Solution:**
```bash
# GITHUB_TOKEN được auto-provide, nhưng kiểm tra:
# Workflow permissions: Settings → Actions → General → Workflow permissions
# → ✅ Read and write permissions
```

### Problem: ArgoCD không sync

**Solution:**
```bash
# Check ArgoCD Application config
kubectl describe app demo-app -n argocd

# Check Git repo access
argocd repo list

# Manual sync
argocd app sync demo-app --force

# View sync logs
argocd app get demo-app --refresh
```

### Problem: Manifest không update

**Solution:**
```bash
# Check if sed command work correctly
sed -i 's|image: ghcr.io/minhtran1015/ptuddn-t3:.*|image: ghcr.io/minhtran1015/ptuddn-t3:test-tag|g' k8s/deployment.yaml
cat k8s/deployment.yaml | grep image:

# Verify k8s/deployment.yaml format
kubectl apply -f k8s/deployment.yaml --dry-run=client
```

## 📊 Monitoring

### Xem deployment status

```bash
# GitHub Actions
gh run list --limit 5
gh run view <run-id> --log

# ArgoCD
argocd app list
argocd app get demo-app
argocd app history demo-app

# Kubernetes
kubectl get deployment -n demo-app
kubectl get pods -n demo-app
kubectl get events -n demo-app --sort-by='.lastTimestamp'
```

### View logs

```bash
# Application logs
kubectl logs -f -n demo-app deployment/demo-app

# Previous pod logs (if crashed)
kubectl logs -n demo-app <pod-name> --previous

# ArgoCD controller logs
kubectl logs -f -n argocd deployment/argocd-application-controller

# GitHub workflow logs
# GitHub UI → Actions → <workflow> → <run> → <job>
```

## 🔄 Deployment Workflow Hàng Ngày

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes
vim demo/src/main/java/com/example/demo/SomeFile.java

# 3. Test locally
cd demo && ./gradlew test

# 4. Commit
git add .
git commit -m "Add new feature"

# 5. Push
git push origin feature/new-feature

# 6. Create Pull Request
# GitHub UI → New Pull Request

# 7. Review & Merge
# After review → Merge to main

# 8. Pipeline automatically:
#    ├─ Build & test
#    ├─ Build Docker image
#    ├─ Push to GHCR
#    ├─ Update k8s/deployment.yaml
#    ├─ Commit manifest change
#    ├─ ArgoCD detects change
#    └─ Deploy to cluster ✅

# 9. Verify deployment
kubectl get pods -n demo-app -w
```

## 🔄 Rollback

### Using ArgoCD

```bash
# See revision history
argocd app history demo-app

# Rollback to previous revision
argocd app rollback demo-app <REVISION_ID>

# Example: rollback 1 revision
argocd app rollback demo-app 1
```

### Manual Rollback

```bash
# Find previous commit
git log --oneline -10

# Revert to previous commit
git revert <commit-sha>
git push origin main

# ArgoCD will auto-sync and rollback
```

## 📚 Useful Commands

```bash
# GitHub
gh run list
gh run view <run-id> --log
gh workflow run ci-cd-single-repo.yml --ref main

# kubectl
kubectl get deployment -n demo-app
kubectl describe deployment demo-app -n demo-app
kubectl logs -f -n demo-app deployment/demo-app
kubectl get events -n demo-app --sort-by='.lastTimestamp'

# ArgoCD
argocd login localhost:8080 --insecure
argocd app list
argocd app get demo-app
argocd app sync demo-app
argocd app history demo-app
argocd app rollback demo-app <revision>

# Git
git log --oneline
git show <commit-sha>
git diff main develop
```

## ✨ Best Practices

1. **Git Workflow**
   - Use feature branches
   - Require PR reviews before merge
   - Automated tests before merge

2. **Manifest Management**
   - Keep k8s/ folder clean
   - One file per resource type
   - Use namespaces for isolation

3. **Image Tags**
   - Always tag images (never use `:latest` only)
   - Use semantic versioning for releases
   - Include commit SHA for traceability

4. **Monitoring**
   - Monitor ArgoCD sync status
   - Setup alerts for failed deployments
   - Regular log reviews

5. **Security**
   - Rotate secrets regularly
   - Use GitHub secrets for sensitive data
   - Limit permissions in RBAC

## 🎯 Success Criteria

Pipeline is working when:
- ✅ GitHub Actions workflow runs successfully
- ✅ Docker image builds and pushes to GHCR
- ✅ k8s/deployment.yaml updates automatically
- ✅ ArgoCD syncs within 5 minutes
- ✅ Application deploys to Kubernetes
- ✅ New pods are running with new image
- ✅ Service accessible at endpoint

## 📞 Summary

**Advantage của Single Repository approach:**
- ✅ Simpler setup (1 repo instead of 2)
- ✅ All code and config together
- ✅ Easier to understand and maintain
- ✅ Still follows GitOps principles
- ✅ Easier to collaborate as team

**Pipeline Flow:**
```
Code Push → GitHub Actions → Build & Push Image → Update Manifest 
→ Push Changes → ArgoCD Detect → Auto-Sync → Deploy ✅
```

**Files to remember:**
- `.github/workflows/ci-cd-single-repo.yml` - Pipeline definition
- `k8s/deployment.yaml` - Auto-updated by pipeline
- `.argocd/application.yaml` - ArgoCD configuration

---

**Status:** ✅ Single Repository CI/CD Ready  
**Implementation Time:** ~15 minutes  
**Complexity:** ⭐⭐ (Simpler than multi-repo)

Happy deploying! 🚀
