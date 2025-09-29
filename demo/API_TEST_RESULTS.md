# API Test Results

## Working APIs ✅

### Authentication
```bash
# Register new user
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
# Response: User registered successfully!

# Login 
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
# Response: JWT token returned successfully

# Admin login
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
# Response: JWT token returned successfully
```

### Blog Management
```bash
# Create blog post (POST) - WORKS ✅
curl -X POST http://localhost:8081/api/blogs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"title":"My First Blog","content":"This is my first blog post!"}'
# Response: Blog created successfully with full blog object

# Get user's own blogs (GET /my-blogs) - WORKS ✅
curl http://localhost:8081/api/blogs/my-blogs \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
# Response: Array of user's blogs with proper JSON structure
```

## Non-Working APIs ❌

### Blog Management Issues
```bash
# Get all blogs (GET /) - FAILS with 403 ❌
curl http://localhost:8081/api/blogs \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
# Response: HTTP 403 Forbidden

# Get blog by ID (GET /{id}) - FAILS with 403 ❌
curl http://localhost:8081/api/blogs/4 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"  
# Response: HTTP 403 Forbidden
```

## Key Observations

1. **Authentication works perfectly** - both user and admin login generate valid JWT tokens
2. **JWT tokens are valid** - proven by successful blog creation and my-blogs retrieval  
3. **Circular reference fixed** - JSON serialization no longer causes infinite loops
4. **Specific endpoint issue** - Only `/api/blogs` (GET all) and `/api/blogs/{id}` (GET by ID) fail
5. **Route mapping inconsistency** - POST and specific GET routes work, but general GET routes fail

## Next Steps for Debugging

The issue appears to be specific to certain GET endpoint mappings in the BlogController, not authentication or authorization in general.

## Demo Data Available

- Admin user: admin/admin123 (ADMIN role)
- Regular user: user/user123 (USER role) 
- Test user: testuser/password123 (USER role)
- Sample blog data pre-loaded via DataInitializer