# GitOps Repository Setup - ptuddn-t3-argocd

## 📋 Step-by-Step Setup

### Step 1: Create New Repository on GitHub

1. Go to https://github.com/new
2. Enter repository name: `ptuddn-t3-argocd`
3. Set as **Private** (recommended for credentials)
4. Add description: "GitOps repository for ptuddn-t3 deployments"
5. Click "Create repository"

### Step 2: Clone the Repository Locally

```bash
git clone https://github.com/YOUR_USERNAME/ptuddn-t3-argocd.git
cd ptuddn-t3-argocd
```

### Step 3: Create Directory Structure

```bash
# Create the required directories
mkdir -p demo-app/{templates,envs/{dev,staging,production}}
mkdir -p argocd-apps
mkdir -p scripts
```

### Step 4: Create Files

Copy the following files into your repository:

#### a) `demo-app/Chart.yaml`

```yaml
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
  - name: Your Name
    email: your.email@example.com
```

#### b) `demo-app/values.yaml`

```yaml
replicaCount: 3

image:
  repository: ghcr.io/minhtran1015/ptuddn-t3
  pullPolicy: Always
  tag: "main-latest"  # This will be updated by CI/CD

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
```

#### c) Copy Helm Templates

From the main `ptuddn-t3` repository, copy the Kubernetes manifests into `demo-app/templates/`:

```bash
# From ptuddn-t3 directory:
cp k8s/namespace.yaml demo-app/templates/
cp k8s/deployment.yaml demo-app/templates/
cp k8s/service.yaml demo-app/templates/
cp k8s/configmap.yaml demo-app/templates/
cp k8s/secret.yaml demo-app/templates/
cp k8s/ingress.yaml demo-app/templates/
cp k8s/hpa.yaml demo-app/templates/
cp k8s/pdb.yaml demo-app/templates/
cp k8s/servicemonitor.yaml demo-app/templates/
```

#### d) `argocd-apps/demo-app-app.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/minhtran1015/ptuddn-t3-argocd
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
```

#### e) `README.md`

```markdown
# ptuddn-t3-argocd

GitOps repository for ptuddn-t3 Spring Boot application deployments using ArgoCD.

## Repository Structure

```
ptuddn-t3-argocd/
├── demo-app/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── ingress.yaml
│   │   ├── hpa.yaml
│   │   ├── pdb.yaml
│   │   └── servicemonitor.yaml
│   └── envs/
│       ├── dev/
│       ├── staging/
│       └── production/
├── argocd-apps/
│   └── demo-app-app.yaml
├── scripts/
└── README.md
```

## How It Works

1. **Developer** pushes code to `ptuddn-t3` repository
2. **GitHub Actions** builds Docker image and pushes to GHCR
3. **CD Workflow** updates image tag in `demo-app/values.yaml` in this repository
4. **ArgoCD** detects the change and automatically syncs
5. **Kubernetes** applies the new deployment

## Manual Deployment

```bash
# View ArgoCD applications
kubectl get applications -n argocd

# Manually sync
argocd app sync demo-app

# View application status
kubectl get all -n demo-app
```

## Update Image Tag Manually

```bash
# Edit values.yaml
sed -i 's/tag: .*/tag: new-tag/g' demo-app/values.yaml

# Commit and push
git add demo-app/values.yaml
git commit -m "Update image tag to new-tag"
git push origin main
```

ArgoCD will automatically detect and apply the changes.

## Security Notes

- Keep this repository private
- Rotate secrets regularly
- Never commit sensitive data; use Kubernetes Secrets instead
- Review all changes before pushing
```

### Step 5: Commit and Push

```bash
git add .
git commit -m "Initial GitOps repository setup"
git push origin main
```

### Step 6: Verify Repository

```bash
git log --oneline
```

## ✅ Verification Checklist

- [ ] Repository created on GitHub
- [ ] All files and directories created
- [ ] Initial commit pushed
- [ ] Repository URL is accessible from GitHub Actions
- [ ] Personal Access Token has read/write access to this repo

## 🔧 Next Steps

1. Go back to main `ptuddn-t3` repository
2. Set GitHub secrets (ARGOCD_REPO, ARGOCD_TOKEN)
3. Push a test commit to trigger CI/CD
4. Monitor ArgoCD for automatic sync

## 📞 Troubleshooting

### Access Denied Error
- Verify Personal Access Token has `repo` scope
- Check token hasn't expired
- Ensure token is used for `ARGOCD_TOKEN` secret

### ArgoCD Can't Clone Repository
- Check repository URL in `argocd-apps/demo-app-app.yaml`
- Verify repository is accessible from cluster
- Check ArgoCD credentials are configured

### Image Not Updating
- Check CD workflow logs in GitHub Actions
- Verify image tag was updated in `values.yaml`
- Check ArgoCD sync status in UI
