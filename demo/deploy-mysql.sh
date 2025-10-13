#!/bin/bash

# MySQL Docker Deployment Script
# Triển khai ứng dụng với MySQL và lưu trữ dữ liệu bền vững

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 MySQL Docker Deployment for Spring Boot Demo${NC}"
echo "=================================================="

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
}

# Function to create necessary directories
create_directories() {
    echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
    mkdir -p mysql-data logs
    
    # Set proper permissions for MySQL data directory
    chmod 755 mysql-data
    
    echo -e "${GREEN}✅ Directories created successfully!${NC}"
}

# Function to start services
start_services() {
    echo -e "${YELLOW}🚀 Starting MySQL and Spring Boot services...${NC}"
    
    # Build and start services
    docker-compose -f docker-compose-mysql.yml up -d --build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Services started successfully!${NC}"
        
        echo -e "\n${BLUE}⏳ Waiting for services to be ready...${NC}"
        sleep 30
        
        # Check service health
        check_services_health
    else
        echo -e "${RED}❌ Failed to start services!${NC}"
        exit 1
    fi
}

# Function to check services health
check_services_health() {
    echo -e "${YELLOW}🔍 Checking services health...${NC}"
    
    # Check MySQL
    if docker-compose -f docker-compose-mysql.yml exec mysql mysqladmin ping -h localhost -u root -prootpassword > /dev/null 2>&1; then
        echo -e "${GREEN}✅ MySQL is healthy${NC}"
    else
        echo -e "${RED}❌ MySQL is not responding${NC}"
    fi
    
    # Check Spring Boot app
    if curl -f http://localhost:8081/actuator/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Spring Boot application is healthy${NC}"
    else
        echo -e "${YELLOW}⚠️  Spring Boot application is still starting up...${NC}"
    fi
}

# Function to show service information
show_service_info() {
    echo -e "\n${BLUE}📋 Service Information:${NC}"
    echo "========================="
    echo -e "${GREEN}🌐 Spring Boot Application:${NC} http://localhost:8081"
    echo -e "${GREEN}🗄️  MySQL Database:${NC} localhost:3306"
    echo -e "${GREEN}📊 phpMyAdmin:${NC} http://localhost:8080"
    echo ""
    echo -e "${BLUE}🔐 Database Credentials:${NC}"
    echo "Database: demoapp"
    echo "Username: demouser"
    echo "Password: demopassword"
    echo "Root Password: rootpassword"
    echo ""
    echo -e "${BLUE}📁 Data Persistence:${NC}"
    echo "MySQL Data: ./mysql-data (bind mount)"
    echo "Application Logs: ./logs (bind mount)"
    echo "MySQL Config: ./mysql-config/my.cnf"
    echo "Init Scripts: ./mysql-init/"
}

# Function to show useful commands
show_commands() {
    echo -e "\n${BLUE}🛠️  Useful Commands:${NC}"
    echo "==================="
    echo "# View logs"
    echo "docker-compose -f docker-compose-mysql.yml logs -f"
    echo ""
    echo "# Stop services"
    echo "docker-compose -f docker-compose-mysql.yml down"
    echo ""
    echo "# Backup MySQL data"
    echo "docker-compose -f docker-compose-mysql.yml exec mysql mysqldump -u root -prootpassword demoapp > backup.sql"
    echo ""
    echo "# Restore MySQL data"
    echo "docker-compose -f docker-compose-mysql.yml exec -T mysql mysql -u root -prootpassword demoapp < backup.sql"
    echo ""
    echo "# Connect to MySQL"
    echo "docker-compose -f docker-compose-mysql.yml exec mysql mysql -u root -prootpassword demoapp"
    echo ""
    echo "# View container status"
    echo "docker-compose -f docker-compose-mysql.yml ps"
}

# Function to stop services
stop_services() {
    echo -e "${YELLOW}🛑 Stopping services...${NC}"
    docker-compose -f docker-compose-mysql.yml down
    echo -e "${GREEN}✅ Services stopped successfully!${NC}"
}

# Main script logic
case "${1:-start}" in
    "start")
        check_docker
        create_directories
        start_services
        show_service_info
        show_commands
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        stop_services
        sleep 5
        check_docker
        create_directories
        start_services
        show_service_info
        ;;
    "status")
        docker-compose -f docker-compose-mysql.yml ps
        ;;
    "logs")
        docker-compose -f docker-compose-mysql.yml logs -f
        ;;
    "backup")
        echo -e "${YELLOW}💾 Creating database backup...${NC}"
        docker-compose -f docker-compose-mysql.yml exec mysql mysqldump -u root -prootpassword demoapp > "backup_$(date +%Y%m%d_%H%M%S).sql"
        echo -e "${GREEN}✅ Backup created successfully!${NC}"
        ;;
    "help")
        echo "Usage: $0 {start|stop|restart|status|logs|backup|help}"
        echo ""
        echo "Commands:"
        echo "  start   - Start MySQL and Spring Boot services"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  status  - Show service status"
        echo "  logs    - Show service logs"
        echo "  backup  - Create database backup"
        echo "  help    - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac