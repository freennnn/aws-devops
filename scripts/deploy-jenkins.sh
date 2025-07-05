#!/bin/bash

# Jenkins Deployment Script for Kubernetes
# This script deploys Jenkins using Helm on a Kubernetes cluster

set -e

# Configuration
NAMESPACE="jenkins"
RELEASE_NAME="jenkins"
CHART_DIR="./helm-charts/jenkins"
TIMEOUT="10m"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    # Check if minikube is running
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Kubernetes cluster is not accessible. Please ensure minikube is running."
        exit 1
    fi
    
    # Check if chart directory exists
    if [ ! -d "$CHART_DIR" ]; then
        log_error "Chart directory $CHART_DIR does not exist."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

setup_helm_repos() {
    log_info "Setting up Helm repositories..."
    
    # Add Jenkins Helm repository
    helm repo add jenkins https://charts.jenkins.io
    helm repo update
    
    log_success "Helm repositories configured"
}

create_namespace() {
    log_info "Creating namespace $NAMESPACE..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_warning "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace "$NAMESPACE"
        log_success "Namespace $NAMESPACE created"
    fi
}

deploy_jenkins() {
    log_info "Deploying Jenkins..."
    
    # Update chart dependencies
    cd "$CHART_DIR"
    helm dependency update
    
    # Deploy Jenkins
    helm upgrade --install "$RELEASE_NAME" . \
        --namespace "$NAMESPACE" \
        --wait \
        --timeout="$TIMEOUT" \
        --set jenkins.controller.admin.password="${JENKINS_ADMIN_PASSWORD:-admin123}" \
        --set jenkins.controller.jenkinsUrl="http://localhost:8080"
    
    cd - > /dev/null
    
    log_success "Jenkins deployed successfully"
}

wait_for_jenkins() {
    log_info "Waiting for Jenkins to be ready..."
    
    # Wait for pod to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jenkins -n "$NAMESPACE" --timeout=300s
    
    log_success "Jenkins is ready"
}

get_jenkins_info() {
    log_info "Getting Jenkins information..."
    
    echo ""
    echo "=== Jenkins Deployment Information ==="
    echo ""
    
    # Get admin password
    echo "Admin Password:"
    kubectl exec --namespace "$NAMESPACE" -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password 2>/dev/null || echo "Failed to retrieve password"
    echo ""
    
    # Get service information
    echo "Service Information:"
    kubectl get svc -n "$NAMESPACE"
    echo ""
    
    # Get pod information
    echo "Pod Information:"
    kubectl get pods -n "$NAMESPACE"
    echo ""
    
    # Get PVC information
    echo "Persistent Volume Claims:"
    kubectl get pvc -n "$NAMESPACE"
    echo ""
    
    echo "=== Access Instructions ==="
    echo "1. Set up port forwarding:"
    echo "   kubectl --namespace $NAMESPACE port-forward svc/jenkins 8080:8080"
    echo ""
    echo "2. Access Jenkins at: http://localhost:8080"
    echo "   Username: admin"
    echo "   Password: [shown above]"
    echo ""
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check if Jenkins pod is running
    if kubectl get pod -l app.kubernetes.io/name=jenkins -n "$NAMESPACE" --field-selector=status.phase=Running &> /dev/null; then
        log_success "Jenkins pod is running"
    else
        log_error "Jenkins pod is not running"
        return 1
    fi
    
    # Check if service is created
    if kubectl get svc jenkins -n "$NAMESPACE" &> /dev/null; then
        log_success "Jenkins service is created"
    else
        log_error "Jenkins service is not created"
        return 1
    fi
    
    # Check if PVC is bound
    if kubectl get pvc -n "$NAMESPACE" -o jsonpath='{.items[*].status.phase}' | grep -q "Bound"; then
        log_success "Persistent volume is bound"
    else
        log_error "Persistent volume is not bound"
        return 1
    fi
    
    log_success "Deployment verification passed"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help                Show this help message"
    echo "  -n, --namespace NAME      Specify namespace (default: jenkins)"
    echo "  -r, --release NAME        Specify release name (default: jenkins)"
    echo "  -t, --timeout DURATION    Specify timeout (default: 10m)"
    echo "  -p, --password PASSWORD   Specify admin password (default: admin123)"
    echo ""
    echo "Environment Variables:"
    echo "  JENKINS_ADMIN_PASSWORD    Admin password for Jenkins"
    echo ""
    echo "Examples:"
    echo "  $0                        Deploy with default settings"
    echo "  $0 -n my-jenkins          Deploy to 'my-jenkins' namespace"
    echo "  $0 -p mySecretPassword     Deploy with custom admin password"
    echo ""
}

cleanup_on_error() {
    log_error "Deployment failed. Cleaning up..."
    helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" 2>/dev/null || true
    kubectl delete namespace "$NAMESPACE" 2>/dev/null || true
    exit 1
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -r|--release)
                RELEASE_NAME="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -p|--password)
                JENKINS_ADMIN_PASSWORD="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set trap for cleanup on error
    trap cleanup_on_error ERR
    
    # Main deployment flow
    log_info "Starting Jenkins deployment..."
    log_info "Namespace: $NAMESPACE"
    log_info "Release: $RELEASE_NAME"
    log_info "Timeout: $TIMEOUT"
    echo ""
    
    check_prerequisites
    setup_helm_repos
    create_namespace
    deploy_jenkins
    wait_for_jenkins
    verify_deployment
    get_jenkins_info
    
    log_success "Jenkins deployment completed successfully!"
}

# Run main function
main "$@" 