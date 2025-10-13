# Docker Setup for Spring Boot Demo Application

This guide will help you build and run the Spring Boot application using Docker.

## Prerequisites

- Docker installed on your system
- Docker Compose (usually comes with Docker Desktop)

## Quick Start

### Option 1: Using the Build Script (Recommended)

Run the automated build script:

```bash
./build-docker.sh
```

This script will:
- Build the Docker image
- Provide instructions for running the container
- Show you the application URLs

### Option 2: Manual Docker Build

1. **Build the Docker image:**
   ```bash
   docker build -t demo-spring-boot:latest .
   ```

2. **Run the container:**
   ```bash
   docker run -p 8081:8081 demo-spring-boot:latest
   ```

### Option 3: Using Docker Compose

1. **Start the application:**
   ```bash
   docker-compose up
   ```

2. **Run in detached mode:**
   ```bash
   docker-compose up -d
   ```

3. **Stop the application:**
   ```bash
   docker-compose down
   ```

## Available Dockerfiles

### Standard Dockerfile (`Dockerfile`)
- Simple single-stage build
- Good for development and testing
- Includes full JDK in runtime

### Optimized Dockerfile (`Dockerfile.optimized`)
- Multi-stage build for smaller image size
- Uses JRE instead of JDK for runtime
- Includes security improvements (non-root user)
- Includes health checks
- Recommended for production

To use the optimized Dockerfile:
```bash
docker build -f Dockerfile.optimized -t demo-spring-boot:optimized .
```

## Application Access

Once the container is running, you can access:

- **Main Application**: http://localhost:8081
- **H2 Database Console**: http://localhost:8081/h2-console
  - JDBC URL: `jdbc:h2:mem:testdb`
  - Username: `sa`
  - Password: `password`

## API Endpoints

The application includes authentication endpoints:
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login and get JWT token
- `GET /api/blogs` - Get all blogs (authenticated)
- `POST /api/blogs` - Create a new blog (authenticated)

## Configuration

### Environment Variables

You can override configuration using environment variables:

```bash
docker run -p 8081:8081 \
  -e SPRING_PROFILES_ACTIVE=production \
  -e SPRING_DATASOURCE_URL=jdbc:h2:mem:proddb \
  demo-spring-boot:latest
```

### Volume Mounts

To persist logs, you can mount a volume:

```bash
docker run -p 8081:8081 \
  -v $(pwd)/logs:/app/logs \
  demo-spring-boot:latest
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using port 8081
   lsof -i :8081
   
   # Use a different port
   docker run -p 8082:8081 demo-spring-boot:latest
   ```

2. **Container Won't Start**
   ```bash
   # Check container logs
   docker logs <container-id>
   ```

3. **Build Fails**
   ```bash
   # Clean build cache
   docker builder prune
   
   # Rebuild without cache
   docker build --no-cache -t demo-spring-boot:latest .
   ```

### Health Check

The optimized Docker image includes a health check. You can check the container health:

```bash
docker ps  # Look for "healthy" status
docker inspect <container-id>  # Detailed health information
```

## Production Considerations

For production deployment:

1. Use the optimized Dockerfile (`Dockerfile.optimized`)
2. Set appropriate JVM memory limits
3. Use external database instead of H2
4. Configure proper logging
5. Set up monitoring and health checks
6. Use specific version tags instead of `latest`

Example production run:
```bash
docker run -d \
  --name demo-app-prod \
  -p 8081:8081 \
  -e SPRING_PROFILES_ACTIVE=production \
  -e JAVA_OPTS="-Xmx1g -Xms512m" \
  --restart unless-stopped \
  demo-spring-boot:v1.0.0
```

## Files Overview

- `Dockerfile` - Standard Docker build configuration
- `Dockerfile.optimized` - Production-optimized Docker build
- `.dockerignore` - Files to exclude from Docker build context
- `docker-compose.yml` - Docker Compose configuration
- `build-docker.sh` - Automated build script