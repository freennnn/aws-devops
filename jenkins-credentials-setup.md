# Jenkins Credentials Setup Guide

This document provides step-by-step instructions for setting up all necessary Jenkins credentials for the Flask Hello World CI/CD pipeline.

## 📋 Required Credentials

The pipeline requires the following credentials to be configured in Jenkins:

1. **Docker Registry Credentials** - For pushing/pulling Docker images
2. **Kubernetes Cluster Access** - For deploying to K8s
3. **SonarQube Token** - For security scanning
4. **Slack Integration** - For notifications
5. **Email SMTP** - For email notifications
6. **Git Repository Access** - For source code access

## 🔧 Setting Up Credentials

### 1. Access Jenkins Credentials

1. Open Jenkins in your browser: `http://localhost:8080`
2. Login with admin credentials
3. Navigate to: **Manage Jenkins > Manage Credentials**
4. Click on **(global)** domain
5. Click **Add Credentials**

### 2. Docker Registry Credentials

**Credential Type:** Username with password

```
ID: docker-registry-credentials
Description: Docker Registry Credentials
Username: [your-registry-username]
Password: [your-registry-password]
```

**For Docker Hub:**
- Username: Your Docker Hub username
- Password: Your Docker Hub password or access token

**For Local Registry:**
- Username: (can be empty for insecure registry)
- Password: (can be empty for insecure registry)

**For AWS ECR:**
- Username: AWS
- Password: ECR login token (obtained via `aws ecr get-login-password`)

### 3. Docker Registry URL

**Credential Type:** Secret text

```
ID: docker-registry-url
Description: Docker Registry URL
Secret: [registry-url]
```

**Examples:**
- Docker Hub: `https://index.docker.io/v1/`
- Local Registry: `localhost:5000`
- AWS ECR: `123456789012.dkr.ecr.us-west-2.amazonaws.com`
- Azure ACR: `myregistry.azurecr.io`

### 4. Kubernetes Configuration

**Credential Type:** Secret file

```
ID: kubeconfig
Description: Kubernetes Configuration File
File: [upload your kubeconfig file]
```

**To get kubeconfig:**

```bash
# For minikube
kubectl config view --raw > kubeconfig

# For cloud providers
# AWS EKS
aws eks update-kubeconfig --region us-west-2 --name my-cluster

# Google GKE
gcloud container clusters get-credentials my-cluster --zone us-central1-a

# Azure AKS
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

### 5. SonarQube Token

**Credential Type:** Secret text

```
ID: sonarqube-token
Description: SonarQube Authentication Token
Secret: [your-sonarqube-token]
```

**To generate SonarQube token:**

1. Access SonarQube: `http://localhost:9000`
2. Login as admin
3. Go to: **User > My Account > Security**
4. Generate new token
5. Copy the token value

**Or use the setup script:**

```bash
./scripts/setup-sonarqube.sh
# Token will be saved in .sonarqube-token file
```

### 6. Slack Integration

**Credential Type:** Secret text

```
ID: slack-webhook-url
Description: Slack Webhook URL
Secret: [your-slack-webhook-url]
```

**To get Slack webhook URL:**

1. Go to your Slack workspace
2. Navigate to: **Apps > Incoming Webhooks**
3. Create new webhook for your channel
4. Copy the webhook URL

**Or use the setup script:**

```bash
./scripts/setup-notifications.sh --slack
```

### 7. Email SMTP Credentials

**Credential Type:** Username with password

```
ID: smtp-credentials
Description: SMTP Email Credentials
Username: [your-email@domain.com]
Password: [your-email-password-or-app-password]
```

**For Gmail:**
- Username: your-email@gmail.com
- Password: App password (not your regular password)

**To create Gmail app password:**
1. Enable 2FA on your Google account
2. Go to: **Google Account > Security > App passwords**
3. Generate app password for "Mail"
4. Use this password in Jenkins

### 8. Git Repository Access (if private)

**Credential Type:** Username with password or SSH Username with private key

**For HTTPS:**
```
ID: git-credentials
Description: Git Repository Credentials
Username: [your-username]
Password: [personal-access-token]
```

**For SSH:**
```
ID: git-ssh-key
Description: Git SSH Private Key
Username: git
Private Key: [paste your private key]
```

## 🔐 Security Best Practices

### 1. Use Specific Credentials

- Create dedicated service accounts for Jenkins
- Use minimal required permissions
- Rotate credentials regularly

### 2. Credential Scoping

- Use folder-level credentials when possible
- Avoid global credentials for sensitive data
- Use credential binding in pipelines

### 3. Token Management

```bash
# Generate strong tokens
openssl rand -base64 32

# Store tokens securely
echo "token" | base64

# Use environment variables in scripts
export JENKINS_TOKEN="your-token"
```

## 🧪 Testing Credentials

### 1. Docker Registry Test

```bash
# Test Docker login
docker login localhost:5000
docker pull hello-world
docker tag hello-world localhost:5000/test:latest
docker push localhost:5000/test:latest
```

### 2. Kubernetes Access Test

```bash
# Test kubectl access
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### 3. SonarQube Test

```bash
# Test SonarQube API
curl -u admin:admin http://localhost:9000/api/system/status
```

### 4. Slack Test

```bash
# Test Slack webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test from Jenkins"}' \
  YOUR_WEBHOOK_URL
```

## 🔧 Automated Setup

You can use the provided scripts to automate credential setup:

```bash
# Set up all notification systems
./scripts/setup-notifications.sh --all

# Set up Docker registry
./scripts/setup-docker-registry.sh

# Set up SonarQube
./scripts/setup-sonarqube.sh

# Test all configurations
./scripts/setup-notifications.sh --test-only
```

## 📝 Jenkins Pipeline Configuration

### Using Credentials in Jenkinsfile

```groovy
pipeline {
    agent any
    
    environment {
        // Docker credentials
        DOCKER_CREDENTIALS = credentials('docker-registry-credentials')
        DOCKER_REGISTRY = credentials('docker-registry-url')
        
        // SonarQube
        SONAR_TOKEN = credentials('sonarqube-token')
        
        // Notifications
        SLACK_WEBHOOK = credentials('slack-webhook-url')
    }
    
    stages {
        stage('Docker Build') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        def image = docker.build("myapp:${BUILD_NUMBER}")
                        image.push()
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'kubectl apply -f deployment.yaml'
                }
            }
        }
    }
}
```

### Credential Binding Examples

```groovy
// Secret text
withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
    sh 'sonar-scanner -Dsonar.login=$SONAR_TOKEN'
}

// Username/Password
withCredentials([usernamePassword(credentialsId: 'docker-registry-credentials', 
                                  usernameVariable: 'DOCKER_USER', 
                                  passwordVariable: 'DOCKER_PASS')]) {
    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
}

// SSH Key
withCredentials([sshUserPrivateKey(credentialsId: 'git-ssh-key', 
                                  keyFileVariable: 'SSH_KEY')]) {
    sh 'ssh-agent bash -c "ssh-add $SSH_KEY && git clone git@github.com:user/repo.git"'
}

// File
withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
    sh 'kubectl --kubeconfig=$KUBECONFIG get pods'
}
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Docker Registry Access Denied

```bash
# Check credentials
docker login [registry-url]

# Check registry accessibility
curl -v [registry-url]/v2/

# For insecure registries, update Docker daemon.json
{
  "insecure-registries": ["localhost:5000"]
}
```

#### 2. Kubernetes Access Denied

```bash
# Check kubeconfig
kubectl config view

# Test connection
kubectl cluster-info

# Check permissions
kubectl auth can-i '*' '*'
```

#### 3. SonarQube Connection Failed

```bash
# Check SonarQube status
curl http://localhost:9000/api/system/status

# Verify token
curl -u [token]: http://localhost:9000/api/user_tokens/search
```

#### 4. Slack Notifications Not Working

```bash
# Test webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' [webhook-url]

# Check webhook URL format
# Should be: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
```

### Debugging Steps

1. **Check Jenkins Logs**
   ```bash
   # Access Jenkins container logs
   docker logs jenkins
   
   # Or check Jenkins system log
   # Manage Jenkins > System Log
   ```

2. **Test Credentials Outside Jenkins**
   ```bash
   # Test each credential manually
   # Use same commands Jenkins pipeline would use
   ```

3. **Verify Network Connectivity**
   ```bash
   # From Jenkins container
   docker exec -it jenkins bash
   curl -v [target-url]
   ```

## 📋 Credential Checklist

- [ ] Docker registry credentials configured
- [ ] Docker registry URL set
- [ ] Kubernetes kubeconfig uploaded
- [ ] SonarQube token generated and stored
- [ ] Slack webhook URL configured
- [ ] SMTP credentials set up
- [ ] Git credentials (if needed)
- [ ] All credentials tested
- [ ] Pipeline updated to use credentials
- [ ] Security review completed

## 🔄 Credential Rotation

### Recommended Rotation Schedule

- **Passwords**: Every 90 days
- **API Tokens**: Every 6 months
- **SSH Keys**: Every 12 months
- **Webhooks**: When compromised

### Rotation Process

1. Generate new credentials
2. Update Jenkins credential store
3. Test pipeline with new credentials
4. Deactivate old credentials
5. Update documentation

## 📚 Additional Resources

- [Jenkins Credentials Plugin Documentation](https://plugins.jenkins.io/credentials/)
- [Docker Registry Authentication](https://docs.docker.com/registry/spec/auth/)
- [Kubernetes Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
- [SonarQube Authentication](https://docs.sonarqube.org/latest/user-guide/user-token/)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks) 