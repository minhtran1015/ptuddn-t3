# Spring Boot REST API with JWT Authentication

This is a minimal Gradle project demonstrating Spring Boot REST APIs with JWT authentication and authorization.

## Features

- **User Management**: CRUD operations for users
- **Blog Management**: CRUD operations for blogs
- **JWT Authentication**: Login/Register with JWT tokens
- **Role-based Authorization**: ADMIN and USER roles
- **Security**: 
  - Only ADMIN can delete users
  - Users can only view/edit their own blogs
  - ADMIN can manage all blogs

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login and get JWT token

### Users
- `GET /api/users` - Get all users
- `GET /api/users/{id}` - Get user by ID
- `PUT /api/users/{id}` - Update user (own profile or admin)
- `DELETE /api/users/{id}` - Delete user (admin only)

### Blogs
- `GET /api/blogs` - Get all blogs
- `GET /api/blogs/{id}` - Get blog by ID
- `GET /api/blogs/my-blogs` - Get current user's blogs
- `POST /api/blogs` - Create new blog
- `PUT /api/blogs/{id}` - Update blog (own blog or admin)
- `DELETE /api/blogs/{id}` - Delete blog (own blog or admin)

## Default Users

The application creates default users on startup:
- **Admin**: username=`admin`, password=`admin123`, role=`ADMIN`
- **User**: username=`user`, password=`user123`, role=`USER`

## Database

- Uses H2 in-memory database for simplicity
- H2 Console available at: http://localhost:8080/h2-console
- JDBC URL: `jdbc:h2:mem:testdb`
- Username: `sa`, Password: `password`

## Running the Application

1. Build and run:
   ```bash
   ./gradlew bootRun
   ```

2. The application will start on http://localhost:8080

## Usage Examples

### 1. Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 2. Create Blog (with JWT token)
```bash
curl -X POST http://localhost:8080/api/blogs \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"title":"My Blog","content":"This is my blog content"}'
```

### 3. Get All Blogs
```bash
curl -X GET http://localhost:8080/api/blogs \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Technologies Used

- Spring Boot 3.5.6
- Spring Security
- Spring Data JPA
- JWT (jsonwebtoken)
- H2 Database
- Java 21