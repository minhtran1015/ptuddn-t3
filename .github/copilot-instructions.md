# Copilot Instructions for ptuddn-t3

This is a **Spring Boot 3.5.6 REST API** with JWT authentication, role-based authorization, and containerized deployment.

## Architecture Overview

**Three-layer architecture:**
- **Controllers** (`controller/`): REST endpoints with security checks via `SecurityContextHolder`
- **Entities** (`entity/`): JPA entities (User, Blog) with audit timestamps via `@PrePersist/@PreUpdate`
- **Repositories** (`repository/`): Spring Data JPA interfaces

**Security Flow:**
1. Requests → `JwtAuthenticationFilter` extracts Bearer token from headers
2. `JwtUtil` validates token (HS512 algorithm, configurable expiration)
3. `CustomUserDetailsService` loads user authorities for role-based checks
4. Controller methods check ownership or ADMIN role before allowing modifications

**Key Files:**
- `SecurityConfig.java`: Stateless session, CSRF disabled, method-level security via `@PreAuthorize`
- `JwtAuthenticationFilter.java`: Runs once per request, sets `SecurityContext.authentication`
- `BlogController.java`: Examples of authorization patterns (check `blog.getAuthor().getId()` vs `currentUser.getId()`)

## Development Workflows

### Build & Run
```bash
./gradlew bootRun  # Starts on port 8081 with H2 in-memory database
./gradlew test     # Runs unit tests with JUnit 5
./gradlew build    # Creates executable JAR in build/libs/
```

### Database Access (Development)
- **H2 Console**: http://localhost:8081/h2-console (enabled in `application.properties`)
- **JDBC URL**: `jdbc:h2:mem:testdb`
- **Default Credentials**: sa / password

### MySQL Integration
For persistent data, use Docker Compose:
```bash
./deploy-mysql.sh start     # Orchestrates MySQL 8.0, phpMyAdmin (8080), app (8081)
./deploy-mysql.sh backup    # Automated database backups
docker-compose -f docker-compose-mysql.yml exec mysql mysql -u root -prootpassword demoapp
```
See `MYSQL_SETUP.md` for full configuration and troubleshooting.

### Containerization
```bash
docker build -t demo-app .                    # Uses optimized multi-stage Dockerfile
docker-compose up -d --build                  # Runs app with volume mounts for logs
docker-compose logs -f demo-app               # Stream real-time logs
```

## Project-Specific Patterns

### Authorization Pattern
Controllers retrieve current user from `SecurityContextHolder` (never inject from request):
```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
String username = auth.getName();
User currentUser = userRepository.findByUsername(username).get();

// Check ownership or admin status
if (!entity.getAuthor().getId().equals(currentUser.getId()) && 
    !currentUser.getRole().name().equals("ADMIN")) {
    return ResponseEntity.status(403).build();
}
```

### Entity Timestamp Pattern
Entities use JPA callbacks for audit trails:
```java
@PrePersist
protected void onCreate() {
    createdAt = LocalDateTime.now();
}

@PreUpdate
protected void onUpdate() {
    updatedAt = LocalDateTime.now();
}
```

### DTO for Requests
Input validation via `@Valid` and DTOs (e.g., `LoginRequest`, `BlogRequest`). Password excluded from responses via `@JsonIgnore`.

### Role-Based Access
- **ADMIN**: Can CRUD all users/blogs
- **USER**: Can only view own blogs, create blogs
- Default users created by `DataInitializer.java` on startup: admin/admin123, user/user123

## Configuration & Conventions

### Property Files
- `application.properties`: Base config (H2, port 8081, JWT secret)
- `application-mysql.properties`: MySQL credentials for compose deployments
- **JWT Secret** in `app.jwt.secret` (currently hardcoded; rotate for production)
- **Expiration** in `app.jwt.expiration` (milliseconds, default 24 hours)

### Common Pitfalls
1. **Circular JSON serialization**: Use `@JsonIgnore` on back-references (e.g., User.blogs list)
2. **CORS**: Enabled via `@CrossOrigin(origins = "*")` on controllers; configured in `SecurityConfig`
3. **Stateless sessions**: Every request needs Authorization header; no cookies
4. **Port conflicts**: Default 8081; ensure MySQL (3306) and phpMyAdmin (8080) aren't blocked

### Dependencies
- **Spring Boot**: 3.5.6 (Java 21 required)
- **Security**: Spring Security + JJWT 0.11.5
- **Persistence**: Spring Data JPA + H2/MySQL
- **Validation**: Jakarta Bean Validation

## Testing & Debugging

### Sample Curl Commands
```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

# Create blog with token
curl -X POST http://localhost:8081/api/blogs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Test","content":"Content"}'
```

### Known Issues
- GET `/api/blogs` and `/api/blogs/{id}` endpoints require investigation (see `API_TEST_RESULTS.md`)
- Some routes may have 403 conflicts; verify method-level security

### Test Data
Default users (created by `DataInitializer` at startup):
- admin / admin123 (ADMIN role)
- user / user123 (USER role)
