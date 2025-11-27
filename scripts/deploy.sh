#!/bin/bash

# Deployment script for EC2 instance
# This script can be run manually or called from GitHub Actions

set -e

echo "🚀 Starting deployment..."

# Navigate to app directory
cd /home/$USER/app || cd ~/app

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down || true

# Pull latest code (if using git on server)
# echo "📥 Pulling latest code..."
# git pull origin main || true

# Build and start containers
echo "🔨 Building and starting containers..."
docker-compose up -d --build

# Wait for containers to be healthy
echo "⏳ Waiting for containers to be ready..."
sleep 10

# Check container status
echo "📊 Container status:"
docker-compose ps

# Clean up old images
echo "🧹 Cleaning up old Docker images..."
docker image prune -f

echo "✅ Deployment complete!"

