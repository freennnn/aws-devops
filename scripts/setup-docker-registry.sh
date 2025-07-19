#!/bin/bash

# Docker Registry Setup Script
# This script sets up a local Docker registry for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY_NAME="local-registry"
REGISTRY_PORT="5000"
REGISTRY_URL="localhost:${REGISTRY_PORT}"
REGISTRY_DATA_DIR="./docker-registry-data"

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
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

start_registry() {
    log_info "Starting local Docker registry..."
    
    # Create data directory
    mkdir -p "$REGISTRY_DATA_DIR"
    
    # Check if registry is already running
    if docker ps --format "table {{.Names}}" | grep -q "^${REGISTRY_NAME}$"; then
        log_warning "Registry '$REGISTRY_NAME' is already running"
        return 0
    fi
    
    # Remove existing stopped container if it exists
    if docker ps -a --format "table {{.Names}}" | grep -q "^${REGISTRY_NAME}$"; then
        log_info "Removing existing stopped registry container..."
        docker rm "$REGISTRY_NAME"
    fi
    
    # Start the registry
    docker run -d \
        --name "$REGISTRY_NAME" \
        --restart=unless-stopped \
        -p "${REGISTRY_PORT}:5000" \
        -v "$(pwd)/${REGISTRY_DATA_DIR}:/var/lib/registry" \
        -e REGISTRY_STORAGE_DELETE_ENABLED=true \
        registry:2
    
    # Wait for registry to be ready
    log_info "Waiting for registry to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://${REGISTRY_URL}/v2/" > /dev/null 2>&1; then
            log_success "Registry is ready!"
            break
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "Registry failed to start within expected time"
        exit 1
    fi
}

stop_registry() {
    log_info "Stopping Docker registry..."
    
    if docker ps --format "table {{.Names}}" | grep -q "^${REGISTRY_NAME}$"; then
        docker stop "$REGISTRY_NAME"
        log_success "Registry stopped"
    else
        log_warning "Registry is not running"
    fi
}

remove_registry() {
    log_info "Removing Docker registry..."
    
    # Stop if running
    if docker ps --format "table {{.Names}}" | grep -q "^${REGISTRY_NAME}$"; then
        docker stop "$REGISTRY_NAME"
    fi
    
    # Remove container
    if docker ps -a --format "table {{.Names}}" | grep -q "^${REGISTRY_NAME}$"; then
        docker rm "$REGISTRY_NAME"
        log_success "Registry container removed"
    else
        log_warning "Registry container does not exist"
    fi
    
    # Optionally remove data directory
    if [ -d "$REGISTRY_DATA_DIR" ]; then
        read -p "Remove registry data directory? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$REGISTRY_DATA_DIR"
            log_success "Registry data directory removed"
        fi
    fi
}

list_images() {
    log_info "Listing images in registry..."
    
    if ! curl -s -f "http://${REGISTRY_URL}/v2/" > /dev/null 2>&1; then
        log_error "Registry is not accessible at ${REGISTRY_URL}"
        return 1
    fi
    
    # Get repository list
    local repos=$(curl -s "http://${REGISTRY_URL}/v2/_catalog" | jq -r '.repositories[]?' 2>/dev/null || echo "")
    
    if [ -z "$repos" ]; then
        log_info "No images found in registry"
        return 0
    fi
    
    echo "Images in registry:"
    echo "===================="
    
    for repo in $repos; do
        echo "Repository: $repo"
        local tags=$(curl -s "http://${REGISTRY_URL}/v2/${repo}/tags/list" | jq -r '.tags[]?' 2>/dev/null || echo "")
        
        if [ -n "$tags" ]; then
            for tag in $tags; do
                echo "  - ${REGISTRY_URL}/${repo}:${tag}"
            done
        else
            echo "  - No tags found"
        fi
        echo ""
    done
}

test_registry() {
    log_info "Testing registry functionality..."
    
    # Pull a small test image
    log_info "Pulling test image..."
    docker pull hello-world:latest
    
    # Tag for local registry
    log_info "Tagging image for local registry..."
    docker tag hello-world:latest "${REGISTRY_URL}/hello-world:test"
    
    # Push to local registry
    log_info "Pushing image to local registry..."
    docker push "${REGISTRY_URL}/hello-world:test"
    
    # Remove local images
    log_info "Removing local images..."
    docker rmi hello-world:latest "${REGISTRY_URL}/hello-world:test" || true
    
    # Pull from local registry
    log_info "Pulling image from local registry..."
    docker pull "${REGISTRY_URL}/hello-world:test"
    
    # Run test
    log_info "Running test container..."
    docker run --rm "${REGISTRY_URL}/hello-world:test"
    
    # Cleanup
    docker rmi "${REGISTRY_URL}/hello-world:test" || true
    
    log_success "Registry test completed successfully!"
}

configure_insecure_registry() {
    log_info "Configuring Docker for insecure registry..."
    
    local docker_config_dir=""
    local daemon_json=""
    
    # Detect OS and set paths
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        docker_config_dir="$HOME/.docker"
        daemon_json="$docker_config_dir/daemon.json"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if [ -d "/etc/docker" ]; then
            docker_config_dir="/etc/docker"
            daemon_json="$docker_config_dir/daemon.json"
        else
            log_error "Docker config directory not found"
            return 1
        fi
    else
        log_warning "OS not supported for automatic configuration"
        return 1
    fi
    
    # Create config directory if it doesn't exist
    mkdir -p "$docker_config_dir"
    
    # Create or update daemon.json
    if [ -f "$daemon_json" ]; then
        # Backup existing config
        cp "$daemon_json" "${daemon_json}.backup"
        log_info "Backed up existing daemon.json"
    fi
    
    # Add insecure registry configuration
    cat > "$daemon_json" << EOF
{
  "insecure-registries": ["${REGISTRY_URL}"]
}
EOF
    
    log_success "Docker daemon configuration updated"
    log_warning "Please restart Docker daemon for changes to take effect"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_info "On Linux, you can restart Docker with:"
        log_info "  sudo systemctl restart docker"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "On macOS, restart Docker Desktop from the menu"
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -s, --start         Start Docker registry"
    echo "  -S, --stop          Stop Docker registry"
    echo "  -r, --remove        Remove Docker registry and optionally data"
    echo "  -l, --list          List images in registry"
    echo "  -t, --test          Test registry functionality"
    echo "  -c, --configure     Configure Docker for insecure registry"
    echo "  --status            Show registry status"
    echo ""
    echo "Examples:"
    echo "  $0 -s               Start registry"
    echo "  $0 -l               List images"
    echo "  $0 -t               Test registry"
    echo "  $0 -S               Stop registry"
    echo ""
}

show_status() {
    echo "=== Docker Registry Status ==="
    echo "Registry Name: $REGISTRY_NAME"
    echo "Registry URL: $REGISTRY_URL"
    echo "Data Directory: $REGISTRY_DATA_DIR"
    echo ""
    
    if docker ps --format "table {{.Names}}" | grep -q "^${REGISTRY_NAME}$"; then
        echo "Status: RUNNING ✅"
        echo "Container ID: $(docker ps --filter name=$REGISTRY_NAME --format "{{.ID}}")"
        echo "Image: $(docker ps --filter name=$REGISTRY_NAME --format "{{.Image}}")"
        echo "Ports: $(docker ps --filter name=$REGISTRY_NAME --format "{{.Ports}}")"
    elif docker ps -a --format "table {{.Names}}" | grep -q "^${REGISTRY_NAME}$"; then
        echo "Status: STOPPED ⏸️"
    else
        echo "Status: NOT CREATED ❌"
    fi
    
    echo ""
    
    # Test connectivity
    if curl -s -f "http://${REGISTRY_URL}/v2/" > /dev/null 2>&1; then
        echo "Connectivity: OK ✅"
    else
        echo "Connectivity: FAILED ❌"
    fi
    
    echo ""
    echo "=== Usage Instructions ==="
    echo "1. Tag your image: docker tag myapp:latest ${REGISTRY_URL}/myapp:latest"
    echo "2. Push to registry: docker push ${REGISTRY_URL}/myapp:latest"
    echo "3. Pull from registry: docker pull ${REGISTRY_URL}/myapp:latest"
    echo ""
}

main() {
    local action=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--start)
                action="start"
                shift
                ;;
            -S|--stop)
                action="stop"
                shift
                ;;
            -r|--remove)
                action="remove"
                shift
                ;;
            -l|--list)
                action="list"
                shift
                ;;
            -t|--test)
                action="test"
                shift
                ;;
            -c|--configure)
                action="configure"
                shift
                ;;
            --status)
                action="status"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Default action
    if [ -z "$action" ]; then
        action="start"
    fi
    
    check_prerequisites
    
    case $action in
        start)
            start_registry
            show_status
            ;;
        stop)
            stop_registry
            ;;
        remove)
            remove_registry
            ;;
        list)
            list_images
            ;;
        test)
            test_registry
            ;;
        configure)
            configure_insecure_registry
            ;;
        status)
            show_status
            ;;
        *)
            log_error "Unknown action: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 