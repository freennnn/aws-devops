# Screenshots for Task 4

This directory contains screenshots demonstrating the successful completion of Task 4 requirements.

## Required Screenshots

### 1. kubectl get all --all-namespaces
File: `kubectl-get-all-namespaces.png`
- Shows all Kubernetes resources across all namespaces
- Demonstrates Jenkins deployment in the jenkins namespace
- Verifies persistent volume claims and services

### 2. Jenkins Hello World Job Log
File: `jenkins-hello-world-job.png`
- Shows the console output of the Hello World job
- Demonstrates successful job execution
- Shows "Hello World" message in the logs

### 3. Jenkins Dashboard
File: `jenkins-dashboard.png`
- Shows the Jenkins main dashboard
- Demonstrates successful web interface access
- Shows the Hello World job in the job list

## How to Generate Screenshots

### 1. kubectl get all --all-namespaces
```bash
# Start minikube and deploy Jenkins
minikube start --driver=docker
./scripts/deploy-jenkins.sh

# Get all resources
kubectl get all --all-namespaces

# Take screenshot of the terminal output
```

### 2. Jenkins Hello World Job
```bash
# Set up port forwarding
kubectl --namespace jenkins port-forward svc/jenkins 8080:8080

# Access Jenkins at http://localhost:8080
# Login with admin credentials
# Navigate to "hello-world" job
# Click "Build Now"
# Click on build number to view details
# Go to "Console Output"
# Take screenshot showing "Hello World" output
```

### 3. Jenkins Dashboard
```bash
# Access Jenkins at http://localhost:8080
# Login with admin credentials
# Take screenshot of the main dashboard
# Ensure "hello-world" job is visible
```

## Note

Screenshots should be placed in this directory with the following naming convention:
- `kubectl-get-all-namespaces.png`
- `jenkins-hello-world-job.png`
- `jenkins-dashboard.png`

These screenshots will be referenced in the pull request template and documentation. 