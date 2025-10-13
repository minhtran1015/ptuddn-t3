# MySQL Database Integration với Data Persistence

Hướng dẫn tích hợp MySQL database với Spring Boot application sử dụng Docker và lưu trữ dữ liệu bền vững.

## 🎯 Tính năng chính

- **MySQL 8.0** làm database chính
- **Data Persistence** sử dụng bind mount và volume mount
- **phpMyAdmin** để quản lý database
- **Health checks** cho tất cả services
- **Custom network** để kết nối các container
- **Backup/Restore** scripts
- **Performance optimization** cho MySQL

## 📁 Cấu trúc thư mục

```
demo/
├── docker-compose-mysql.yml    # Docker Compose với MySQL
├── deploy-mysql.sh            # Script triển khai MySQL
├── mysql-config/              # Cấu hình MySQL
│   └── my.cnf                # MySQL configuration
├── mysql-init/               # Scripts khởi tạo
│   └── 01-init.sql          # SQL initialization
├── mysql-data/              # Dữ liệu MySQL (bind mount)
├── logs/                    # Application logs (bind mount)
└── src/main/resources/
    └── application-mysql.properties  # MySQL config cho Spring Boot
```

## 🚀 Triển khai nhanh

### Sử dụng script tự động (Khuyến nghị)

```bash
# Khởi động tất cả services
./deploy-mysql.sh start

# Dừng services
./deploy-mysql.sh stop

# Khởi động lại
./deploy-mysql.sh restart

# Xem trạng thái
./deploy-mysql.sh status

# Xem logs
./deploy-mysql.sh logs

# Backup database
./deploy-mysql.sh backup
```

### Triển khai thủ công

```bash
# Tạo thư mục cần thiết
mkdir -p mysql-data logs

# Khởi động services
docker-compose -f docker-compose-mysql.yml up -d --build

# Xem logs
docker-compose -f docker-compose-mysql.yml logs -f
```

## 🔧 Cấu hình Database

### MySQL Configuration (mysql-config/my.cnf)

```ini
[mysqld]
# Character set
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# Performance
innodb_buffer_pool_size=256M
max_connections=200

# Logging
slow_query_log=1
long_query_time=2
```

### Spring Boot Configuration (application-mysql.properties)

```properties
# MySQL Database Configuration
spring.datasource.url=jdbc:mysql://mysql:3306/demoapp?createDatabaseIfNotExist=true
spring.datasource.username=demouser
spring.datasource.password=demopassword
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect
```

## 📊 Services và Ports

| Service | Port | Mô tả |
|---------|------|-------|
| Spring Boot App | 8081 | Main application |
| MySQL | 3306 | Database server |
| phpMyAdmin | 8080 | Database management UI |

## 🗄️ Database Credentials

```
Database Name: demoapp
Username: demouser
Password: demopassword
Root Password: rootpassword
```

## 💾 Data Persistence

### Bind Mounts
- **MySQL Data**: `./mysql-data` → `/var/lib/mysql`
- **Application Logs**: `./logs` → `/app/logs`
- **MySQL Config**: `./mysql-config/my.cnf` → `/etc/mysql/conf.d/my.cnf`
- **Init Scripts**: `./mysql-init` → `/docker-entrypoint-initdb.d`

### Volume Mounts
- **App Temp**: Named volume `app_temp` cho temporary files

## 🔍 Monitoring và Health Checks

### MySQL Health Check
```bash
mysqladmin ping -h localhost -u root -prootpassword
```

### Application Health Check
```bash
curl -f http://localhost:8081/actuator/health
```

## 🛠️ Database Management

### Kết nối MySQL qua command line
```bash
docker-compose -f docker-compose-mysql.yml exec mysql mysql -u root -prootpassword demoapp
```

### Sử dụng phpMyAdmin
1. Mở browser: http://localhost:8080
2. Server: mysql
3. Username: root
4. Password: rootpassword

### Backup Database
```bash
# Tự động backup với script
./deploy-mysql.sh backup

# Manual backup
docker-compose -f docker-compose-mysql.yml exec mysql mysqldump -u root -prootpassword demoapp > backup.sql
```

### Restore Database
```bash
# Restore từ backup file
docker-compose -f docker-compose-mysql.yml exec -T mysql mysql -u root -prootpassword demoapp < backup.sql
```

## 🔧 Troubleshooting

### Container không start được

```bash
# Kiểm tra logs
docker-compose -f docker-compose-mysql.yml logs mysql
docker-compose -f docker-compose-mysql.yml logs demo-app

# Kiểm tra port conflicts
netstat -an | grep :3306
netstat -an | grep :8081
```

### MySQL connection errors

```bash
# Kiểm tra MySQL đã sẵn sàng chưa
docker-compose -f docker-compose-mysql.yml exec mysql mysqladmin ping -h localhost -u root -prootpassword

# Restart MySQL
docker-compose -f docker-compose-mysql.yml restart mysql
```

### Data persistence issues

```bash
# Kiểm tra quyền thư mục
ls -la mysql-data/
chmod 755 mysql-data/

# Kiểm tra volume mounts
docker-compose -f docker-compose-mysql.yml exec mysql ls -la /var/lib/mysql/
```

## 🔐 Security Best Practices

1. **Thay đổi passwords mặc định** trong production
2. **Sử dụng secrets** thay vì environment variables
3. **Giới hạn network access** chỉ cho các container cần thiết
4. **Regular backup** dữ liệu quan trọng
5. **Monitor logs** cho security issues

## 📈 Performance Optimization

### MySQL Configuration
- `innodb_buffer_pool_size`: 70-80% RAM
- `max_connections`: Adjust based on load
- `query_cache_size`: Disable trong MySQL 8.0+

### Application Configuration
- Connection pooling với HikariCP
- Proper indexing cho queries
- Monitor slow queries

## 🔄 Production Deployment

### Environment Variables
```bash
# Set cho production
export MYSQL_ROOT_PASSWORD=strong_root_password
export MYSQL_PASSWORD=strong_user_password
export JWT_SECRET=production_jwt_secret
```

### Docker Compose Override
```yaml
# docker-compose.prod.yml
services:
  mysql:
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - /data/mysql:/var/lib/mysql  # Absolute path for production
```

### SSL Configuration
Thêm SSL certificates cho secure connections:
```yaml
volumes:
  - ./ssl/server-cert.pem:/etc/mysql/ssl/server-cert.pem
  - ./ssl/server-key.pem:/etc/mysql/ssl/server-key.pem
```

## 📝 Logs và Monitoring

### Xem logs realtime
```bash
# Tất cả services
docker-compose -f docker-compose-mysql.yml logs -f

# Chỉ MySQL
docker-compose -f docker-compose-mysql.yml logs -f mysql

# Chỉ Spring Boot app
docker-compose -f docker-compose-mysql.yml logs -f demo-app
```

### Log rotation
Cấu hình log rotation trong production để tránh đầy disk:
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```