# Kubernetes Deployment and Monitoring Guide

This guide provides comprehensive instructions for deploying the Spring Boot application to Kubernetes and setting up monitoring with Prometheus and Grafana.

## Prerequisites

Before deploying the application, ensure you have the following:

- **Docker Desktop** with Kubernetes enabled
- **kubectl** installed and configured
- **Helm 3.x** installed
- **Git** for cloning repositories

### Verify Prerequisites

```bash
# Check Docker and Kubernetes
docker --version
kubectl cluster-info

# Check Helm
helm version

# Check Git
git --version
```

## Kubernetes Cluster Setup

### 1. Enable Kubernetes in Docker Desktop

1. Open Docker Desktop
2. Go to **Settings** → **Kubernetes**
3. Check **"Enable Kubernetes"**
4. Click **"Apply & Restart"**
5. Wait for the cluster to start (may take several minutes)

### 2. Verify Cluster Status

```bash
# Check cluster status
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check cluster components
kubectl get pods -n kube-system
```

Expected output should show the control plane running and nodes in Ready state.

## Application Deployment

### 1. Clone or Navigate to Project

```bash
cd /path/to/ptuddn-t3
```

### 2. Deploy Application Components

```bash
# Create namespace and service account
kubectl apply -f deployment/k8s/namespace.yaml

# Deploy all application resources
kubectl apply -f deployment/k8s/

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/demo-app -n demo-app
```

### 3. Verify Deployment

```bash
# Check pod status
kubectl get pods -n demo-app

# Check deployment status
kubectl get deployment -n demo-app

# Check services
kubectl get svc -n demo-app

# Check all resources
kubectl get all -n demo-app
```

### 4. Access the Application

```bash
# Port-forward the service
kubectl port-forward -n demo-app svc/demo-app 8080:80

# Test endpoints in another terminal
curl http://localhost:8080/health
curl http://localhost:8080/

Expected responses:

- `/health`: `OK`
- `/`: `Spring Boot Application Running`

## Monitoring Setup

### 1. Install Prometheus and Grafana

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Update repositories
helm repo update

# Install monitoring stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### 2. Verify Monitoring Installation

```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Check services
kubectl get svc -n monitoring

# Check Helm release
helm list -n monitoring
```

### 3. Access Monitoring Tools

#### Grafana Setup

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Get admin password
kubectl get secret --namespace monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

- **URL**: <http://localhost:3000>
- **Username**: admin
- **Password**: (output from above command)

#### Prometheus Setup

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```

- **URL**: <http://localhost:9090>

### 4. Configure Grafana

1. **Login to Grafana**
   - Open <http://localhost:3000>
   - Use admin credentials from above

2. **Add Prometheus Data Source**
   - Go to **Configuration** → **Data Sources**
   - Click **"Add data source"**
   - Select **Prometheus**
   - URL: `http://monitoring-kube-prometheus-prometheus:9090`
   - Click **"Save & Test"**

3. **Import Dashboards**
   - Go to **Dashboards** → **Browse**
   - Click **"New"** → **"Import"**
   - Import dashboard ID: `4701` (JVM Dashboard) or `3662` (Spring Boot Statistics)
   - Select the Prometheus data source
   - Click **"Import"**

## Application Metrics

### Metrics Endpoints

The Spring Boot application exposes the following actuator endpoints:

- **Health Check**: `/actuator/health`
- **Metrics**: `/actuator/metrics`
- **Prometheus Metrics**: `/actuator/prometheus`
- **Info**: `/actuator/info`

### ServiceMonitor Configuration

The application includes a ServiceMonitor that automatically configures Prometheus to scrape metrics:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: demo-app
  namespace: demo-app
spec:
  selector:
    matchLabels:
      app: demo-app
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
```

### Available Metrics

Common Spring Boot metrics include:

- **JVM Metrics**: Memory usage, GC statistics, thread counts
- **HTTP Metrics**: Request counts, response times, error rates
- **System Metrics**: CPU usage, disk I/O
- **Application Metrics**: Custom business metrics

## Troubleshooting

### Application Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n demo-app

# Check pod events
kubectl describe pod <pod-name> -n demo-app

# Check logs
kubectl logs -n demo-app deployment/demo-app --tail=100
```

#### Service Not Accessible

```bash
# Check service
kubectl get svc -n demo-app

# Check endpoints
kubectl get endpoints -n demo-app

# Test port-forward
kubectl port-forward -n demo-app svc/demo-app 8080:80
curl http://localhost:8080/health
```

### Monitoring Issues

#### Prometheus Not Scraping

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n demo-app

# Check Prometheus targets (via UI)
# Visit http://localhost:9090/targets
```

#### Grafana Data Source Issues

```bash
# Test data source connection in Grafana
# Configuration → Data Sources → Prometheus → "Save & Test"
```

#### Port Conflicts

If default ports are in use, use alternative ports:

```bash
# Application
kubectl port-forward -n demo-app svc/demo-app 8081:80

# Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80

# Prometheus
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9091:9090
```

### Common Issues

1. **Image Pull Errors**: Ensure Docker images are built and available
2. **Resource Constraints**: Check node resources and pod limits
3. **Network Policies**: Verify no network policies blocking traffic
4. **RBAC Issues**: Check service account permissions

## Scaling and Management

### Scaling the Application

```bash
# Scale deployment
kubectl scale deployment demo-app --replicas=5 -n demo-app

# Check HPA (if configured)
kubectl get hpa -n demo-app
```

### Updating the Application

```bash
# Update deployment image
kubectl set image deployment/demo-app demo-app=your-repo/demo-app:v2.0 -n demo-app

# Check rollout status
kubectl rollout status deployment/demo-app -n demo-app
```

### Logs and Debugging

```bash
# View application logs
kubectl logs -n demo-app deployment/demo-app -f

# View monitoring logs
kubectl logs -n monitoring deployment/monitoring-grafana -f
kubectl logs -n monitoring deployment/monitoring-kube-prometheus-prometheus -f
```

## Cleanup

### Remove Application

```bash
# Delete application resources
kubectl delete -f deployment/k8s/

# Delete namespace
kubectl delete namespace demo-app
```

### Remove Monitoring

```bash
# Uninstall monitoring stack
helm uninstall monitoring -n monitoring

# Delete namespace
kubectl delete namespace monitoring
```

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
