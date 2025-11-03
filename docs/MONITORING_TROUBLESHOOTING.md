# Monitoring and Actuator Troubleshooting Guide

## Problem Summary

We encountered issues with Spring Boot Actuator endpoints not being accessible in our Kubernetes deployment, preventing Prometheus from scraping metrics and Grafana dashboards from displaying data.

## Issues Identified and Solutions Attempted

### 1. Missing Actuator Dependencies
**Problem**: Initial Docker image didn't include Spring Boot Actuator dependencies.
**Solution**: Added the following dependencies to `build.gradle`:
```gradle
implementation 'org.springframework.boot:spring-boot-starter-actuator'
implementation 'io.micrometer:micrometer-registry-prometheus'
```

### 2. Docker Build Context Issues
**Problem**: Dockerfile was trying to copy source files from wrong directory structure.
**Original Dockerfile**: Located in `/deployment/` but trying to copy from relative paths that didn't exist.
**Solution**: Modified Dockerfile to use pre-built JAR approach:
```dockerfile
# Use OpenJDK 21 as the base image
FROM openjdk:21-jdk-slim

# Set the working directory in the container
WORKDIR /app

# Copy the pre-built JAR file
COPY app.jar .

# Expose the port that the application runs on
EXPOSE 8081

# Set the entry point to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 3. Actuator Configuration Issues
**Problem**: Actuator endpoints returning 404 despite dependencies being present.
**Configuration Attempted**:
```properties
spring.application.name=demo
server.port=8081

# Actuator configuration for monitoring
management.endpoints.web.exposure.include=*
management.endpoint.health.enabled=true
management.endpoint.metrics.enabled=true
management.endpoint.prometheus.enabled=true
```

### 4. Port Forwarding and Service Configuration
**Problem**: Port forwarding conflicts and service mapping issues.
**Service Configuration**:
- Service forwards port 80 to container port 8081
- Multiple port forward attempts using different local ports (8080, 8082, 8084, 8085)

### 5. JAR Validation and Verification
**Verified**:
- Actuator dependencies are present in JAR: `spring-boot-actuator-autoconfigure-3.5.6.jar`, `spring-boot-actuator-3.5.6.jar`
- Application.properties is correctly packaged in `BOOT-INF/classes/application.properties`
- Local JAR execution shows: "Exposing 14 endpoints beneath base path '/actuator'"

## Current Status

### What's Working:
- ✅ Application starts successfully in Kubernetes
- ✅ Basic Spring Boot application endpoints accessible (root `/` returns "Spring Boot Application Running")
- ✅ Actuator dependencies are included in the JAR
- ✅ Local execution shows actuator endpoints being exposed
- ✅ ServiceMonitor is configured for Prometheus scraping

### What's Not Working:
- ❌ Actuator endpoints return 404 in Kubernetes environment
- ❌ `/actuator/health` endpoint not accessible
- ❌ `/actuator/prometheus` endpoint not accessible for metrics scraping
- ❌ Grafana dashboards show "No data" due to missing metrics

## Key Observations

1. **Local vs Container Behavior**: Actuator works locally but not in Kubernetes container
2. **Logs Show Endpoints Exposed**: Container logs don't show the "Exposing 14 endpoints" message that appears locally
3. **JAR Contents Verified**: The JAR contains all necessary actuator files and configuration
4. **Service Configuration**: Kubernetes service correctly forwards traffic to container port 8081

## Next Steps to Investigate

1. **Container Environment**: Check if there are environment variables or runtime differences affecting actuator in container
2. **Spring Profile Issues**: Verify if container is using a different Spring profile that disables actuator
3. **Classpath Issues**: Ensure actuator auto-configuration is being triggered in container environment
4. **Security Configuration**: Check if any security settings are blocking actuator endpoints
5. **Spring Boot Version Compatibility**: Verify Spring Boot 3.5.6 actuator configuration requirements

## Debugging Commands Used

```bash
# Check JAR contents for actuator
jar tf app.jar | grep actuator

# Verify application.properties in JAR
jar xf app.jar BOOT-INF/classes/application.properties && cat BOOT-INF/classes/application.properties

# Test endpoints
curl -s http://localhost:8085/actuator/health
curl -s http://localhost:8085/actuator/prometheus
curl -s http://localhost:8085/actuator

# Check pod logs
kubectl logs -n demo-app deployment/demo-app --tail=50

# Port forward for testing
kubectl port-forward -n demo-app svc/demo-app 8085:80
```

## Expected vs Actual Behavior

**Expected**: 
- `/actuator/health` should return health status JSON
- `/actuator/prometheus` should return metrics in Prometheus format
- Container logs should show "Exposing X endpoints beneath base path '/actuator'"

**Actual**:
- All actuator endpoints return 404 Not Found
- Container logs don't mention actuator endpoint exposure
- Basic application functionality works fine

## Related Files

- `/demo/build.gradle` - Contains actuator dependencies
- `/demo/src/main/resources/application.properties` - Actuator configuration
- `/deployment/Dockerfile` - Container build configuration
- `/deployment/k8s/servicemonitor.yaml` - Prometheus scraping configuration
- `/docs/spring-boot-dashboard.json` - Grafana dashboard expecting actuator metrics