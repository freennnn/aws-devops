#!/bin/bash

# Jenkins Cleanup Script for Kubernetes
# This script removes Jenkins deployment and associated resources

set -e

# Configuration
NAMESPACE="jenkins"
RELEASE_NAME="jenkins"

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

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help                Show this help message"
    echo "  -n, --namespace NAME      Specify namespace (default: jenkins)"
    echo "  -r, --release NAME        Specify release name (default: jenkins)"
    echo "  -f, --force               Force cleanup without confirmation"
    echo "  --keep-pvc               Keep persistent volume claims"
    echo ""
    echo "Examples:"
    echo "  $0                        Cleanup with confirmation"
    echo "  $0 -f                     Force cleanup without confirmation"
    echo "  $0 -n my-jenkins          Cleanup from 'my-jenkins' namespace"
    echo "  $0 --keep-pvc             Keep persistent storage"
    echo ""
}

confirm_cleanup() {
    if [[ "${FORCE_CLEANUP:-false}" == "true" ]]; then
        return 0
    fi
    
    echo ""
    log_warning "This will remove the following resources:"
    echo "  - Helm release: $RELEASE_NAME"
    echo "  - Namespace: $NAMESPACE"
    if [[ "${KEEP_PVC:-false}" == "false" ]]; then
        echo "  - All persistent volume claims"
    fi
    echo ""
    
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
}

cleanup_helm_release() {
    log_info "Removing Helm release '$RELEASE_NAME'..."
    
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
        log_success "Helm release '$RELEASE_NAME' removed"
    else
        log_warning "Helm release '$RELEASE_NAME' not found"
    fi
}

cleanup_persistent_volumes() {
    if [[ "${KEEP_PVC:-false}" == "true" ]]; then
        log_info "Keeping persistent volume claims as requested"
        return 0
    fi
    
    log_info "Removing persistent volume claims..."
    
    # Get PVCs in the namespace
    if kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | grep -q .; then
        kubectl delete pvc --all -n "$NAMESPACE"
        log_success "Persistent volume claims removed"
    else
        log_warning "No persistent volume claims found"
    fi
}

cleanup_namespace() {
    log_info "Removing namespace '$NAMESPACE'..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        kubectl delete namespace "$NAMESPACE"
        log_success "Namespace '$NAMESPACE' removed"
    else
        log_warning "Namespace '$NAMESPACE' not found"
    fi
}

verify_cleanup() {
    log_info "Verifying cleanup..."
    
    # Check if helm release exists
    if helm list -n "$NAMESPACE" 2>/dev/null | grep -q "$RELEASE_NAME"; then
        log_warning "Helm release '$RELEASE_NAME' still exists"
    else
        log_success "Helm release '$RELEASE_NAME' removed successfully"
    fi
    
    # Check if namespace exists
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_warning "Namespace '$NAMESPACE' still exists"
    else
        log_success "Namespace '$NAMESPACE' removed successfully"
    fi
}

get_cleanup_info() {
    log_info "Getting cleanup information..."
    
    echo ""
    echo "=== Current State ==="
    echo ""
    
    # Show helm releases
    echo "Helm Releases:"
    helm list -A | grep -E "(NAME|$RELEASE_NAME)" || echo "No matching releases found"
    echo ""
    
    # Show namespaces
    echo "Namespaces:"
    kubectl get namespaces | grep -E "(NAME|$NAMESPACE)" || echo "No matching namespaces found"
    echo ""
    
    # Show persistent volumes
    echo "Persistent Volumes:"
    kubectl get pv | grep -E "(NAME|$NAMESPACE)" || echo "No matching persistent volumes found"
    echo ""
}

main() {
    local FORCE_CLEANUP="false"
    local KEEP_PVC="false"
    
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
            -f|--force)
                FORCE_CLEANUP="true"
                shift
                ;;
            --keep-pvc)
                KEEP_PVC="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Export variables for subfunctions
    export FORCE_CLEANUP
    export KEEP_PVC
    
    # Main cleanup flow
    log_info "Starting Jenkins cleanup..."
    log_info "Namespace: $NAMESPACE"
    log_info "Release: $RELEASE_NAME"
    echo ""
    
    get_cleanup_info
    confirm_cleanup
    
    cleanup_helm_release
    cleanup_persistent_volumes
    cleanup_namespace
    verify_cleanup
    
    log_success "Jenkins cleanup completed successfully!"
}

# Run main function
main "$@" 