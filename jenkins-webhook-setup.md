# Jenkins GitHub Webhook Integration

This guide explains how to set up Jenkins to be triggered by GitHub push events, addressing the evaluation requirement for GitHub-triggered Jenkins builds.

## 🔧 Setup Steps

### 1. Configure Jenkins GitHub Plugin

In Jenkins dashboard:
1. Go to **Manage Jenkins** → **Manage Plugins**
2. Install **GitHub plugin** if not already installed
3. Restart Jenkins

### 2. Configure GitHub Webhook

In your GitHub repository:
1. Go to **Settings** → **Webhooks**
2. Click **Add webhook**
3. Configure:
   ```
   Payload URL: http://your-jenkins-url/github-webhook/
   Content type: application/json
   Secret: (optional but recommended)
   Events: Just the push event
   ```

### 3. Configure Jenkins Job

In your Jenkins pipeline job:
1. Go to job **Configure**
2. Under **Build Triggers**, check:
   - ☑️ **GitHub hook trigger for GITScm polling**
3. Under **Pipeline**, set:
   ```
   Definition: Pipeline script from SCM
   SCM: Git
   Repository URL: https://github.com/your-username/your-repo.git
   Branch Specifier: */main (or your target branch)
   Script Path: Jenkinsfile
   ```

### 4. Test the Integration

1. Make a small commit to your repository:
   ```bash
   echo "# Test commit" >> README.md
   git add README.md
   git commit -m "Test Jenkins webhook trigger"
   git push origin main
   ```

2. Check Jenkins dashboard - a new build should start automatically

## 📸 Required Screenshots for Evaluation

To meet the evaluation criteria, capture these screenshots:

### A. Jenkins Build Triggered by GitHub Push
- **Location**: Jenkins Dashboard → Your Pipeline Job
- **Show**: Build history with builds triggered by GitHub webhooks
- **File name**: `jenkins-github-triggered-build.png`

### B. Successful Pipeline Execution
- **Location**: Jenkins → Your Job → Latest Build → Console Output
- **Show**: Complete console log showing all stages passing
- **File name**: `jenkins-pipeline-success.png`

### C. Application Verification
- **Location**: Jenkins → Your Job → Latest Build → Console Output (Verification section)
- **Show**: Application verification tests passing with curl responses
- **File name**: `jenkins-app-verification.png`

### D. Docker Image in ECR
- **Location**: AWS Console → ECR → Your Repository
- **Show**: Docker images with tags and push timestamps
- **File name**: `ecr-docker-images.png`

### E. Kubernetes Deployment
- **Location**: Terminal or kubectl output
- **Show**: `kubectl get pods -n flask-hello-world` showing running pods
- **File name**: `kubernetes-deployment.png`

## 🔍 Troubleshooting

### Webhook Not Triggering Jenkins

1. **Check GitHub webhook deliveries**:
   - Go to your repo → Settings → Webhooks
   - Click on your webhook → Recent Deliveries
   - Look for successful deliveries (green checkmark)

2. **Check Jenkins URL is accessible**:
   ```bash
   curl -I http://your-jenkins-url/github-webhook/
   # Should return HTTP 200
   ```

3. **Check Jenkins logs**:
   ```bash
   docker logs jenkins  # If using Docker
   # or check Jenkins → Manage Jenkins → System Log
   ```

### Build Not Starting

1. **Verify repository access**:
   - Jenkins needs access to your GitHub repository
   - Add GitHub credentials in Jenkins if private repo

2. **Check branch configuration**:
   - Ensure branch specifier matches your push branch
   - Use `*/main` for main branch, `*/task-6` for task-6 branch

## 🎯 Manual Trigger Alternative

If webhooks fail, you can manually trigger with proof:

1. **Manual Build**: Click "Build Now" in Jenkins
2. **Screenshot**: Capture the build process and success
3. **Documentation**: Note that this was a manual trigger for evaluation

## 📋 Validation Checklist

Before submitting, ensure you have:
- [ ] GitHub webhook configured and working
- [ ] Jenkins job triggered by GitHub push
- [ ] Screenshots of successful pipeline execution
- [ ] Evidence of application verification
- [ ] Docker image in registry (ECR or local)
- [ ] Kubernetes deployment working
- [ ] All screenshots properly named and organized 