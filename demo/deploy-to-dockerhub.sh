#!/bin/bash

# Docker Hub deployment script for Spring Boot Demo Application

# Configuration
DOCKER_HUB_USERNAME=""  # Set your Docker Hub username here
APP_NAME="demo-spring-boot"
IMAGE_TAG="latest"
VERSION_TAG="v1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Docker Hub Deployment Script${NC}"
echo "=================================="

# Check if Docker Hub username is set
if [ -z "$DOCKER_HUB_USERNAME" ]; then
    echo -e "${YELLOW}⚠️  Docker Hub username not set in script.${NC}"
    read -p "Enter your Docker Hub username: " DOCKER_HUB_USERNAME
    
    if [ -z "$DOCKER_HUB_USERNAME" ]; then
        echo -e "${RED}❌ Docker Hub username is required!${NC}"
        exit 1
    fi
fi

# Docker Hub repository name
REPO_NAME="$DOCKER_HUB_USERNAME/$APP_NAME"

echo -e "${BLUE}📦 Repository: $REPO_NAME${NC}"
echo ""

# Check if user is logged into Docker Hub
echo -e "${YELLOW}🔐 Checking Docker Hub authentication...${NC}"
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}⚠️  Not logged into Docker Hub. Please login:${NC}"
    docker login
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Docker login failed!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Docker authentication successful!${NC}"
echo ""

# Build the Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
docker build -t $REPO_NAME:$IMAGE_TAG .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
fi

# Tag with version
echo -e "${YELLOW}🏷️  Tagging image with version $VERSION_TAG...${NC}"
docker tag $REPO_NAME:$IMAGE_TAG $REPO_NAME:$VERSION_TAG

# Push latest tag
echo -e "${YELLOW}📤 Pushing latest tag to Docker Hub...${NC}"
docker push $REPO_NAME:$IMAGE_TAG

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to push latest tag!${NC}"
    exit 1
fi

# Push version tag
echo -e "${YELLOW}📤 Pushing version tag to Docker Hub...${NC}"
docker push $REPO_NAME:$VERSION_TAG

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to push version tag!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Successfully pushed to Docker Hub!${NC}"
echo ""
echo -e "${BLUE}📋 Deployment Information:${NC}"
echo "Repository: $REPO_NAME"
echo "Tags pushed: latest, $VERSION_TAG"
echo ""
echo -e "${BLUE}🚀 To run from Docker Hub:${NC}"
echo "docker run -p 8081:8081 $REPO_NAME:latest"
echo ""
echo -e "${BLUE}🌐 Docker Hub URL:${NC}"
echo "https://hub.docker.com/r/$REPO_NAME"
echo ""
echo -e "${BLUE}📊 Image information:${NC}"
docker images | grep $REPO_NAME