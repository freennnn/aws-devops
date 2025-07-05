# Task 4: Jenkins Deployment on Kubernetes

This document provides comprehensive instructions for deploying Jenkins on Kubernetes using Helm charts, including local development with Minikube and automated deployment via GitHub Actions.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Local Development Setup](#local-development-setup)
4. [Jenkins Configuration](#jenkins-configuration)
5. [GitHub Actions Pipeline](#github-actions-pipeline)
6. [Verification](#verification)
7. [Security Considerations](#security-considerations)
8. [Troubleshooting](#troubleshooting)
9. [Clean Up](#clean-up)

## 🎯 Overview

This implementation provides:
- **Helm Chart**: Custom Jenkins deployment with JCasC (Jenkins Configuration as Code)
- **GitHub Actions Pipeline**: Automated CI/CD for Jenkins deployment
- **Security**: Authentication, authorization, and security scanning
- **Persistence**: Persistent storage for Jenkins data
- **Monitoring**: Health checks and logging

## 📦 Prerequisites

### Local Development
- **Docker Desktop**: For running Minikube
- **Minikube**: Local Kubernetes cluster
- **Helm**: Package manager for Kubernetes
- **kubectl**: Kubernetes command-line tool

### Installation Commands

```bash
# Install on macOS using Homebrew
brew install minikube helm

# Verify installations
minikube version
helm version
kubectl version --client
```

## 🚀 Local Development Setup

### 1. Start Minikube Cluster

```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify cluster status
minikube status
kubectl get nodes
```

### 2. Check Persistent Volume Support

```bash
# Check storage classes
kubectl get storageclass

# Expected output:
# NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE
# standard (default)   k8s.io/minikube-hostpath   Delete          Immediate
```

### 3. Install Helm and Verify

```bash
# Add Bitnami repository for verification
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Test Helm installation with Nginx
helm install nginx-test bitnami/nginx
kubectl get pods

# Clean up test deployment
helm uninstall nginx-test
```

### 4. Deploy Jenkins

```bash
# Create namespace
kubectl create namespace jenkins

# Add Jenkins Helm repository
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Deploy using our custom chart
cd helm-charts/jenkins
helm dependency update
helm install jenkins . --namespace jenkins --wait

# Check deployment status
kubectl get pods -n jenkins
kubectl get svc -n jenkins
```

### 5. Access Jenkins

```bash
# Get admin password
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password

# Set up port forwarding
kubectl --namespace jenkins port-forward svc/jenkins 8080:8080

# Access Jenkins at: http://localhost:8080
# Username: admin
# Password: [from previous command]
```

## ⚙️ Jenkins Configuration

### Jenkins Configuration as Code (JCasC)

Our Helm chart includes JCasC configuration for:

1. **Hello World Job**: Automatically created freestyle job
2. **Security Settings**: Authentication and authorization
3. **Plugin Management**: Essential plugins pre-installed
4. **Resource Allocation**: CPU and memory limits

### Key Features

- **Persistent Storage**: 8GB persistent volume for Jenkins data
- **Resource Limits**: Configured for optimal performance
- **Security**: Disabled setup wizard, configured authentication
- **Plugins**: Pre-installed essential plugins including:
  - Configuration as Code
  - Kubernetes
  - Blue Ocean
  - Pipeline plugins
  - Git integration

### Hello World Job Configuration

The Hello World job is automatically created via JCasC with:
- **Name**: `hello-world`
- **Type**: Freestyle job
- **Action**: Executes `echo "Hello World"` shell command
- **Description**: "A simple Hello World job created via JCasC"

## 🔄 GitHub Actions Pipeline

### Pipeline Overview

The GitHub Actions pipeline (`jenkins-deployment.yml`) includes:

1. **Validation**: Helm chart linting and templating
2. **Deployment**: Automated deployment to Minikube
3. **Security Scan**: Trivy vulnerability scanning
4. **Cleanup**: Resource cleanup for PR environments

### Pipeline Jobs

#### 1. Validate Chart
- Lints Helm chart syntax
- Templates chart for validation
- Packages chart as artifact

#### 2. Deploy to Minikube
- Starts fresh Minikube instance
- Deploys Jenkins with custom configuration
- Runs accessibility tests
- Exports logs on failure

#### 3. Security Scan
- Runs Trivy security scanner
- Uploads results to GitHub Security tab
- Scans for vulnerabilities in configurations

#### 4. Cleanup
- Removes resources after PR testing
- Prevents resource waste

### Triggering the Pipeline

```bash
# Push to task_4 branch
git add .
git commit -m "Add Jenkins deployment configuration"
git push origin task_4

# Or trigger manually from GitHub Actions UI
```

## ✅ Verification

### 1. Cluster Status

```bash
# Check all resources
kubectl get all --all-namespaces

# Expected output should show:
# - Jenkins pod running in jenkins namespace
# - Jenkins service with ClusterIP
# - Persistent volume claims
# - Default Kubernetes services
```

### 2. Jenkins Accessibility

```bash
# Test HTTP response
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080

# Expected: 200 (after login) or 403 (login required)
```

### 3. Hello World Job

1. **Login to Jenkins**: http://localhost:8080
2. **Navigate to Jobs**: Click on "hello-world" job
3. **Run Job**: Click "Build Now"
4. **Check Output**: View console output showing "Hello World"

### 4. Persistent Storage

```bash
# Check persistent volume claims
kubectl get pvc -n jenkins

# Restart Jenkins pod to verify data persistence
kubectl delete pod -l app.kubernetes.io/name=jenkins -n jenkins
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jenkins -n jenkins --timeout=300s
```

## 🔒 Security Considerations

### Authentication & Authorization

- **Admin User**: Configured with secure password
- **Anonymous Access**: Disabled
- **CSRF Protection**: Enabled
- **User Signup**: Disabled

### Security Features

1. **Matrix Authorization**: Role-based access control
2. **Credentials Binding**: Secure credential management
3. **LDAP/PAM Support**: Enterprise authentication ready
4. **Security Scanning**: Automated vulnerability detection

### Security Best Practices

- Change default passwords immediately
- Use strong authentication methods
- Regularly update plugins
- Monitor security advisories
- Implement network policies

## 🛠️ Troubleshooting

### Common Issues

#### 1. Minikube Won't Start
```bash
# Check Docker Desktop is running
docker ps

# Delete and recreate cluster
minikube delete
minikube start --driver=docker
```

#### 2. Jenkins Pod Stuck in Init State
```bash
# Check pod events
kubectl describe pod -l app.kubernetes.io/name=jenkins -n jenkins

# Check logs
kubectl logs -l app.kubernetes.io/name=jenkins -n jenkins --tail=50
```

#### 3. Persistent Volume Issues
```bash
# Check storage class
kubectl get storageclass

# Check PVC status
kubectl get pvc -n jenkins
kubectl describe pvc -n jenkins
```

#### 4. Port Forwarding Issues
```bash
# Kill existing port forwards
pkill -f "kubectl.*port-forward"

# Restart port forwarding
kubectl --namespace jenkins port-forward svc/jenkins 8080:8080
```

### Log Analysis

```bash
# Jenkins application logs
kubectl logs -l app.kubernetes.io/name=jenkins -n jenkins -c jenkins

# Init container logs
kubectl logs -l app.kubernetes.io/name=jenkins -n jenkins -c init
```

## 🧹 Clean Up

### Local Cleanup

```bash
# Uninstall Jenkins
helm uninstall jenkins -n jenkins

# Delete namespace
kubectl delete namespace jenkins

# Stop Minikube
minikube stop

# Delete Minikube cluster (optional)
minikube delete
```

### GitHub Actions Cleanup

Cleanup is automatic for PR environments. For persistent deployments:

```bash
# Manual cleanup via workflow dispatch
# Or use the cleanup job configuration
```

## 📊 Resource Requirements

### Minimum Requirements

- **CPU**: 2 cores
- **Memory**: 4GB RAM
- **Storage**: 10GB available space
- **Network**: Internet access for image pulls

### Jenkins Resource Allocation

- **Controller**: 2 CPU cores, 4GB memory
- **Agent**: 1 CPU core, 2GB memory
- **Storage**: 8GB persistent volume

## 🎉 Success Criteria

- ✅ Minikube cluster running with persistent storage
- ✅ Helm installed and verified with Nginx deployment
- ✅ Jenkins deployed in separate namespace
- ✅ Jenkins accessible via web browser
- ✅ Hello World job created and executable
- ✅ GitHub Actions pipeline successful
- ✅ Security configurations applied
- ✅ Persistent storage verified

## 🔗 Additional Resources

- [Jenkins Helm Chart Documentation](https://github.com/jenkinsci/helm-charts)
- [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

## 📝 Notes

- This configuration is optimized for development and learning
- For production deployments, consider additional security hardening
- Regular backups of Jenkins data are recommended
- Monitor resource usage and adjust limits as needed 