pipeline {
    agent any
    
    environment {
        // Application Configuration
        APP_NAME = 'flask-hello-world'
        DOCKER_REGISTRY = credentials('docker-registry-url') // Configure in Jenkins
        DOCKER_CREDENTIALS = credentials('docker-registry-credentials')
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/${APP_NAME}"
        
        // Kubernetes Configuration
        K8S_NAMESPACE = 'flask-hello-world'
        HELM_CHART_PATH = './helm-charts/flask-hello-world'
        
        // SonarQube Configuration
        SONAR_PROJECT_KEY = 'flask-hello-world'
        SONAR_PROJECT_NAME = 'Flask Hello World'
        
        // Notification Configuration
        SLACK_CHANNEL = '#devops-alerts'
        EMAIL_RECIPIENTS = 'devops-team@company.com'
        
        // Build Configuration
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = "${env.GIT_COMMIT?.take(7)}"
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        skipDefaultCheckout(false)
        timestamps()
        ansiColor('xterm')
    }
    
    triggers {
        // Trigger on push to main branch
        pollSCM('H/5 * * * *')
        
        // Trigger on webhook
        githubPush()
    }
    
    stages {
        stage('🚀 Pipeline Start') {
            steps {
                script {
                    echo "🎯 Starting CI/CD Pipeline for ${APP_NAME}"
                    echo "📦 Build Number: ${BUILD_NUMBER}"
                    echo "🔖 Git Commit: ${GIT_COMMIT_SHORT}"
                    echo "🏷️  Image Tag: ${IMAGE_TAG}"
                    
                    // Send start notification
                    sendNotification('STARTED', "Pipeline started for ${APP_NAME} (Build #${BUILD_NUMBER})")
                }
            }
        }
        
        stage('🔍 Checkout & Validation') {
            steps {
                echo "📥 Checking out source code..."
                
                // Validate required files exist
                script {
                    def requiredFiles = [
                        'flask-hello-world/main.py',
                        'flask-hello-world/requirements.txt',
                        'flask-hello-world/Dockerfile',
                        'helm-charts/flask-hello-world/Chart.yaml'
                    ]
                    
                    requiredFiles.each { file ->
                        if (!fileExists(file)) {
                            error("Required file not found: ${file}")
                        }
                    }
                    echo "✅ All required files validated"
                }
            }
        }
        
        stage('🏗️ Application Build') {
            steps {
                dir('flask-hello-world') {
                    echo "🔨 Installing Python dependencies..."
                    sh '''
                        python3 -m venv venv
                        source venv/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt
                        pip install pytest pytest-cov flake8 safety bandit
                    '''
                    
                    echo "📋 Generating requirements freeze..."
                    sh '''
                        source venv/bin/activate
                        pip freeze > requirements-freeze.txt
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'flask-hello-world/requirements-freeze.txt', fingerprint: true
                }
            }
        }
        
        stage('🧪 Unit Tests') {
            parallel {
                stage('Python Tests') {
                    steps {
                        dir('flask-hello-world') {
                            echo "🧪 Running unit tests..."
                            sh '''
                                source venv/bin/activate
                                python -m pytest tests/ --junitxml=test-results.xml --cov=. --cov-report=xml --cov-report=html || true
                            '''
                        }
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: 'flask-hello-world/test-results.xml'
                            publishCoverage adapters: [
                                coberturaAdapter('flask-hello-world/coverage.xml')
                            ], sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
                            
                            archiveArtifacts artifacts: 'flask-hello-world/htmlcov/**', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('Code Quality') {
                    steps {
                        dir('flask-hello-world') {
                            echo "🔍 Running code quality checks..."
                            sh '''
                                source venv/bin/activate
                                
                                # Python linting
                                flake8 . --output-file=flake8-report.txt --tee || true
                                
                                # Security vulnerability check for dependencies
                                safety check --output text > safety-report.txt || true
                                
                                # Security static analysis
                                bandit -r . -f json -o bandit-report.json || true
                                bandit -r . -f txt -o bandit-report.txt || true
                            '''
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'flask-hello-world/*-report.*', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        stage('🔒 Security Scan with SonarQube') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    changeRequest()
                }
            }
            steps {
                script {
                    def scannerHome = tool 'SonarQubeScanner'
                    
                    withSonarQubeEnv('SonarQube') {
                        dir('flask-hello-world') {
                            echo "🔒 Running SonarQube analysis..."
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.projectName='${SONAR_PROJECT_NAME}' \
                                    -Dsonar.projectVersion=${IMAGE_TAG} \
                                    -Dsonar.sources=. \
                                    -Dsonar.python.coverage.reportPaths=coverage.xml \
                                    -Dsonar.python.xunit.reportPath=test-results.xml \
                                    -Dsonar.exclusions=venv/**,**/__pycache__/**,tests/**
                            """
                        }
                    }
                }
                
                // Wait for quality gate
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            echo "⚠️ SonarQube Quality Gate failed: ${qg.status}"
                            // Don't fail the build, just warn
                            currentBuild.result = 'UNSTABLE'
                        } else {
                            echo "✅ SonarQube Quality Gate passed"
                        }
                    }
                }
            }
        }
        
        stage('🐳 Docker Build & Push') {
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    
                    dir('flask-hello-world') {
                        // Build Docker image
                        def dockerImage = docker.build("${DOCKER_IMAGE}:${IMAGE_TAG}")
                        
                        // Tag with latest if on main branch
                        if (env.BRANCH_NAME == 'main') {
                            dockerImage.tag('latest')
                        }
                        
                        // Push to registry
                        docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS) {
                            echo "📤 Pushing image to registry..."
                            dockerImage.push("${IMAGE_TAG}")
                            
                            if (env.BRANCH_NAME == 'main') {
                                dockerImage.push('latest')
                            }
                        }
                        
                        echo "✅ Docker image pushed: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                    }
                }
            }
        }
        
        stage('🚀 Deploy to Kubernetes') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo "🚀 Deploying to Kubernetes..."
                    
                    // Create namespace if it doesn't exist
                    sh """
                        kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                    """
                    
                    // Deploy using Helm
                    sh """
                        cd ${HELM_CHART_PATH}
                        
                        helm dependency update
                        
                        helm upgrade --install ${APP_NAME} . \
                            --namespace ${K8S_NAMESPACE} \
                            --set image.repository=${DOCKER_REGISTRY}/${APP_NAME} \
                            --set image.tag=${IMAGE_TAG} \
                            --set image.pullPolicy=Always \
                            --set replicaCount=2 \
                            --wait \
                            --timeout=10m
                    """
                    
                    // Wait for deployment to be ready
                    sh """
                        kubectl wait --for=condition=available --timeout=300s \
                            deployment/${APP_NAME} -n ${K8S_NAMESPACE}
                    """
                    
                    echo "✅ Deployment successful"
                }
            }
            post {
                success {
                    script {
                        // Get deployment status
                        sh """
                            echo "📊 Deployment Status:"
                            kubectl get pods -n ${K8S_NAMESPACE} -l app.kubernetes.io/name=${APP_NAME}
                            kubectl get services -n ${K8S_NAMESPACE}
                        """
                    }
                }
            }
        }
        
        stage('🔍 Application Verification') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo "🔍 Running application verification tests..."
                    
                    // Port forward to access the application
                    sh """
                        # Start port forwarding in background
                        kubectl port-forward -n ${K8S_NAMESPACE} svc/${APP_NAME} 8080:80 &
                        PF_PID=\$!
                        
                        # Wait for port forward to be ready
                        sleep 10
                        
                        # Run verification tests
                        echo "Testing application health..."
                        
                        # Basic connectivity test
                        for i in {1..5}; do
                            if curl -f http://localhost:8080/; then
                                echo "✅ Application is responding"
                                break
                            else
                                echo "⏳ Waiting for application... (attempt \$i/5)"
                                sleep 10
                            fi
                            
                            if [ \$i -eq 5 ]; then
                                echo "❌ Application health check failed"
                                kill \$PF_PID || true
                                exit 1
                            fi
                        done
                        
                        # Detailed verification
                        echo "Running detailed verification..."
                        
                        # Test main endpoint
                        RESPONSE=\$(curl -s http://localhost:8080/)
                        if [[ "\$RESPONSE" == *"Hello, World!"* ]]; then
                            echo "✅ Main endpoint test passed"
                        else
                            echo "❌ Main endpoint test failed"
                            echo "Response: \$RESPONSE"
                            kill \$PF_PID || true
                            exit 1
                        fi
                        
                        # Test response time
                        RESPONSE_TIME=\$(curl -o /dev/null -s -w "%{time_total}" http://localhost:8080/)
                        echo "⏱️  Response time: \${RESPONSE_TIME}s"
                        
                        # Cleanup
                        kill \$PF_PID || true
                        
                        echo "✅ All verification tests passed"
                    """
                }
            }
        }
        
        stage('📊 Post-Deployment Tasks') {
            parallel {
                stage('Generate Reports') {
                    steps {
                        script {
                            echo "📊 Generating deployment report..."
                            
                            sh """
                                echo "# Deployment Report - Build ${BUILD_NUMBER}" > deployment-report.md
                                echo "" >> deployment-report.md
                                echo "## Build Information" >> deployment-report.md
                                echo "- **Build Number**: ${BUILD_NUMBER}" >> deployment-report.md
                                echo "- **Git Commit**: ${GIT_COMMIT_SHORT}" >> deployment-report.md
                                echo "- **Image Tag**: ${IMAGE_TAG}" >> deployment-report.md
                                echo "- **Branch**: ${env.BRANCH_NAME}" >> deployment-report.md
                                echo "- **Build Date**: \$(date)" >> deployment-report.md
                                echo "" >> deployment-report.md
                                echo "## Deployment Status" >> deployment-report.md
                                kubectl get pods -n ${K8S_NAMESPACE} -o wide >> deployment-report.md
                                echo "" >> deployment-report.md
                                echo "## Services" >> deployment-report.md
                                kubectl get services -n ${K8S_NAMESPACE} >> deployment-report.md
                            """
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'deployment-report.md', fingerprint: true
                        }
                    }
                }
                
                stage('Update Documentation') {
                    when {
                        branch 'main'
                    }
                    steps {
                        script {
                            echo "📝 Updating deployment documentation..."
                            
                            // Update deployment version in documentation
                            sh """
                                if [ -f "DEPLOYMENT.md" ]; then
                                    sed -i "s/Current Version:.*/Current Version: ${IMAGE_TAG}/" DEPLOYMENT.md
                                    sed -i "s/Last Deployed:.*/Last Deployed: \$(date)/" DEPLOYMENT.md
                                fi
                            """
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "🧹 Cleaning up workspace..."
                
                // Stop any port forwarding processes
                sh "pkill -f 'kubectl.*port-forward' || true"
                
                // Clean up Docker images on agent
                sh """
                    docker rmi ${DOCKER_IMAGE}:${IMAGE_TAG} || true
                    docker system prune -f || true
                """
            }
        }
        
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                
                sendNotification('SUCCESS', """
                    🎉 Pipeline completed successfully!
                    
                    **Build**: #${BUILD_NUMBER}
                    **Branch**: ${env.BRANCH_NAME}
                    **Commit**: ${GIT_COMMIT_SHORT}
                    **Image**: ${DOCKER_IMAGE}:${IMAGE_TAG}
                    
                    ✅ Application deployed and verified
                """.stripIndent())
            }
        }
        
        failure {
            script {
                echo "❌ Pipeline failed!"
                
                sendNotification('FAILURE', """
                    🚨 Pipeline failed!
                    
                    **Build**: #${BUILD_NUMBER}
                    **Branch**: ${env.BRANCH_NAME}  
                    **Commit**: ${GIT_COMMIT_SHORT}
                    **Stage**: ${env.STAGE_NAME}
                    
                    Please check the build logs for details.
                """.stripIndent())
            }
        }
        
        unstable {
            script {
                echo "⚠️ Pipeline completed with warnings!"
                
                sendNotification('UNSTABLE', """
                    ⚠️ Pipeline completed with warnings!
                    
                    **Build**: #${BUILD_NUMBER}
                    **Branch**: ${env.BRANCH_NAME}
                    **Commit**: ${GIT_COMMIT_SHORT}
                    
                    Please review the warnings in the build logs.
                """.stripIndent())
            }
        }
    }
}

// Helper function to send notifications
def sendNotification(String status, String message) {
    def color = [
        'STARTED': 'good',
        'SUCCESS': 'good', 
        'FAILURE': 'danger',
        'UNSTABLE': 'warning'
    ][status] ?: 'good'
    
    try {
        // Slack notification
        slackSend(
            channel: env.SLACK_CHANNEL,
            color: color,
            message: message,
            teamDomain: 'your-team',
            token: 'slack-token'
        )
    } catch (Exception e) {
        echo "Failed to send Slack notification: ${e.getMessage()}"
    }
    
    try {
        // Email notification for failures
        if (status in ['FAILURE', 'UNSTABLE']) {
            emailext(
                subject: "Jenkins Pipeline ${status}: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: message,
                to: env.EMAIL_RECIPIENTS,
                attachLog: true,
                compressLog: true
            )
        }
    } catch (Exception e) {
        echo "Failed to send email notification: ${e.getMessage()}"
    }
} 