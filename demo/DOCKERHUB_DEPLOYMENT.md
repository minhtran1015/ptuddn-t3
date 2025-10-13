# Deploy to Docker Hub Guide

This guide will help you push your Spring Boot application to Docker Hub.

## Prerequisites

1. **Docker Hub Account**: Create a free account at [hub.docker.com](https://hub.docker.com)
2. **Docker Desktop**: Ensure Docker is installed and running
3. **Built Docker Image**: Your application image should be built locally

## Method 1: Automated Deployment (Recommended)

Use the deployment script for a streamlined process:

```bash
./deploy-to-dockerhub.sh
```

The script will:
- Prompt for your Docker Hub username if not configured
- Handle Docker Hub authentication
- Build and tag your image
- Push both `latest` and versioned tags
- Provide deployment information

## Method 2: Manual Deployment

### Step 1: Login to Docker Hub

```bash
docker login
```

Enter your Docker Hub username and password when prompted.

### Step 2: Build and Tag Your Image

Replace `YOUR_USERNAME` with your actual Docker Hub username:

```bash
# Build the image
docker build -t YOUR_USERNAME/demo-spring-boot:latest .

# Tag with a version (optional but recommended)
docker tag YOUR_USERNAME/demo-spring-boot:latest YOUR_USERNAME/demo-spring-boot:v1.0.0
```

### Step 3: Push to Docker Hub

```bash
# Push latest tag
docker push YOUR_USERNAME/demo-spring-boot:latest

# Push version tag (if you created one)
docker push YOUR_USERNAME/demo-spring-boot:v1.0.0
```

## Step 4: Verify Deployment

1. **Check your Docker Hub repository**: Visit `https://hub.docker.com/r/YOUR_USERNAME/demo-spring-boot`
2. **Test pulling and running**:
   ```bash
   # Remove local image to test pull
   docker rmi YOUR_USERNAME/demo-spring-boot:latest
   
   # Pull and run from Docker Hub
   docker run -p 8081:8081 YOUR_USERNAME/demo-spring-boot:latest
   ```

## Repository Configuration

### Making Repository Public/Private

1. Go to your repository on Docker Hub
2. Click on "Settings"
3. Under "Visibility settings", choose:
   - **Public**: Anyone can pull your image
   - **Private**: Only you and collaborators can access

### Adding Description and Documentation

1. Edit your repository on Docker Hub
2. Add a comprehensive description
3. Include usage instructions and environment variables

## Best Practices

### Tagging Strategy

```bash
# Use semantic versioning
docker tag YOUR_USERNAME/demo-spring-boot:latest YOUR_USERNAME/demo-spring-boot:v1.0.0
docker tag YOUR_USERNAME/demo-spring-boot:latest YOUR_USERNAME/demo-spring-boot:1.0
docker tag YOUR_USERNAME/demo-spring-boot:latest YOUR_USERNAME/demo-spring-boot:1

# Environment-specific tags
docker tag YOUR_USERNAME/demo-spring-boot:latest YOUR_USERNAME/demo-spring-boot:prod
docker tag YOUR_USERNAME/demo-spring-boot:latest YOUR_USERNAME/demo-spring-boot:staging
```

### Optimized Image for Production

For production deployments, use the optimized Dockerfile:

```bash
docker build -f Dockerfile.optimized -t YOUR_USERNAME/demo-spring-boot:prod .
docker push YOUR_USERNAME/demo-spring-boot:prod
```

## Using Your Deployed Image

### Basic Usage

```bash
docker run -d --name my-spring-app -p 8081:8081 YOUR_USERNAME/demo-spring-boot:latest
```

### With Environment Variables

```bash
docker run -d \
  --name my-spring-app \
  -p 8081:8081 \
  -e SPRING_PROFILES_ACTIVE=production \
  -e JAVA_OPTS="-Xmx512m" \
  YOUR_USERNAME/demo-spring-boot:latest
```

### With Docker Compose

Update your `docker-compose.yml`:

```yaml
services:
  demo-app:
    image: YOUR_USERNAME/demo-spring-boot:latest
    ports:
      - "8081:8081"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
```

## Troubleshooting

### Authentication Issues

```bash
# Re-login to Docker Hub
docker logout
docker login

# Check authentication
docker info | grep Username
```

### Push Failures

```bash
# Check if image exists locally
docker images | grep demo-spring-boot

# Verify image tag format
docker images YOUR_USERNAME/demo-spring-boot
```

### Rate Limits

Docker Hub has rate limits for anonymous pulls:
- **Anonymous**: 100 pulls per 6 hours
- **Authenticated**: 200 pulls per 6 hours
- **Pro/Team**: Higher limits

## Security Considerations

1. **Use specific version tags** instead of `latest` in production
2. **Scan images for vulnerabilities**:
   ```bash
   docker scan YOUR_USERNAME/demo-spring-boot:latest
   ```
3. **Use multi-stage builds** to reduce image size and attack surface
4. **Keep base images updated** regularly
5. **Don't include secrets** in Docker images

## Automated CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/docker-publish.yml`:

```yaml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        push: true
        tags: ${{ secrets.DOCKERHUB_USERNAME }}/demo-spring-boot:latest
```

## Next Steps

After successful deployment:

1. **Monitor your application** using Docker Hub insights
2. **Set up automated builds** for continuous deployment
3. **Configure webhooks** for deployment notifications
4. **Implement health checks** in your Docker configuration
5. **Set up monitoring and logging** for production use