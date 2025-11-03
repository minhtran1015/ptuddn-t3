#!/bin/bash

# Docker build and run script for Spring Boot Demo Application

APP_NAME="demo-spring-boot"
IMAGE_TAG="latest"

echo "🐳 Building Docker image for $APP_NAME..."

# Build the Docker image
docker build -t $APP_NAME:$IMAGE_TAG .

if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully!"
    echo "📦 Image: $APP_NAME:$IMAGE_TAG"
    
    echo ""
    echo "🚀 To run the container, use one of these commands:"
    echo "   docker run -p 8081:8081 $APP_NAME:$IMAGE_TAG"
    echo "   docker-compose up"
    echo ""
    echo "🌐 The application will be available at: http://localhost:8081"
    echo "🗄️  H2 Console will be available at: http://localhost:8081/h2-console"
else
    echo "❌ Docker build failed!"
    exit 1
fi