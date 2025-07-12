#!/bin/bash

# Task 5: Cleanup Flask Hello World Application
# This script removes the Flask application deployment

set -e

echo "🧹 Cleaning up Flask Hello World Application"
echo "==========================================="

# Configuration
NAMESPACE="flask-hello-world"
RELEASE_NAME="flask-hello-world"
DOCKER_IMAGE="flask-hello-world:latest"

# Check if Helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Skipping Helm cleanup."
else
    echo "🗑️  Removing Helm release..."
    helm uninstall $RELEASE_NAME -n $NAMESPACE || echo "Release not found or already removed"
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Skipping Kubernetes cleanup."
else
    echo "🗑️  Removing namespace..."
    kubectl delete namespace $NAMESPACE || echo "Namespace not found or already removed"
fi

# Remove Docker image
if command -v docker &> /dev/null; then
    echo "🗑️  Removing Docker image..."
    docker rmi $DOCKER_IMAGE || echo "Docker image not found or already removed"
fi

# Kill any port-forward processes
echo "🔌 Killing any port-forward processes..."
pkill -f "port-forward.*flask-hello-world" || echo "No port-forward processes found"

echo "✅ Cleanup completed successfully!" 