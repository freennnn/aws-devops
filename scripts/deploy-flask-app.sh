#!/bin/bash

# Task 5: Deploy Flask Hello World Application with Helm
# This script deploys the Flask application to a Kubernetes cluster

set -e

echo "🚀 Starting Flask Hello World Application Deployment"
echo "==============================================="

# Configuration
NAMESPACE="flask-hello-world"
RELEASE_NAME="flask-hello-world"
CHART_PATH="helm-charts/flask-hello-world"
DOCKER_IMAGE="flask-hello-world:latest"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if Helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if minikube is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster is not accessible. Please start minikube first:"
    echo "   minikube start"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Step 1: Build Docker image
echo "🔨 Building Docker image..."
cd flask-hello-world
docker build -t $DOCKER_IMAGE .
cd ..

# Step 2: Load image into minikube (if using minikube)
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "📦 Loading Docker image into minikube..."
    minikube image load $DOCKER_IMAGE
fi

# Step 3: Create namespace
echo "📁 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Step 4: Deploy with Helm
echo "🚀 Deploying Flask application with Helm..."
helm upgrade --install $RELEASE_NAME $CHART_PATH \
    --namespace $NAMESPACE \
    --set image.repository=flask-hello-world \
    --set image.tag=latest \
    --set image.pullPolicy=Never \
    --wait

# Step 5: Check deployment status
echo "🔍 Checking deployment status..."
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE

# Step 6: Set up port forwarding
echo "🌐 Setting up port forwarding..."
echo "Run the following command to access the application:"
echo "kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:80"
echo ""
echo "Then visit: http://localhost:8080"
echo ""

# Step 7: Display helpful information
echo "📋 Deployment Summary:"
echo "- Release Name: $RELEASE_NAME"
echo "- Namespace: $NAMESPACE"
echo "- Image: $DOCKER_IMAGE"
echo ""
echo "📝 Useful commands:"
echo "- Check pods: kubectl get pods -n $NAMESPACE"
echo "- Check logs: kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=flask-hello-world"
echo "- Port forward: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8080:80"
echo "- Delete deployment: helm uninstall $RELEASE_NAME -n $NAMESPACE"
echo ""
echo "✅ Deployment completed successfully!" 