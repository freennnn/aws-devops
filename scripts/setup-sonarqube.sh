#!/bin/bash

# SonarQube Setup Script
# This script sets up SonarQube for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SONARQUBE_URL="http://localhost:9000"
PROJECT_KEY="flask-hello-world"
PROJECT_NAME="Flask Hello World"
ADMIN_USER="admin"
ADMIN_PASS="admin123"

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
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed. Please install curl first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

start_sonarqube() {
    log_info "Starting SonarQube..."
    
    # Start SonarQube using Docker Compose
    docker-compose -f docker-compose.sonarqube.yml up -d
    
    log_info "Waiting for SonarQube to start..."
    
    # Wait for SonarQube to be ready
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$SONARQUBE_URL/api/system/status" > /dev/null 2>&1; then
            local status=$(curl -s "$SONARQUBE_URL/api/system/status" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            if [ "$status" = "UP" ]; then
                log_success "SonarQube is ready!"
                break
            fi
        fi
        
        echo -n "."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "SonarQube failed to start within expected time"
        exit 1
    fi
}

setup_sonarqube_project() {
    log_info "Setting up SonarQube project..."
    
    # Change default admin password
    log_info "Changing default admin password..."
    curl -s -u admin:admin -X POST "$SONARQUBE_URL/api/users/change_password" \
        -d "login=admin&previousPassword=admin&password=$ADMIN_PASS" || true
    
    # Create project
    log_info "Creating project..."
    curl -s -u "$ADMIN_USER:$ADMIN_PASS" -X POST "$SONARQUBE_URL/api/projects/create" \
        -d "project=$PROJECT_KEY&name=$PROJECT_NAME" || log_warning "Project might already exist"
    
    # Generate token
    log_info "Generating authentication token..."
    TOKEN_RESPONSE=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" -X POST "$SONARQUBE_URL/api/user_tokens/generate" \
        -d "name=jenkins-token")
    
    if echo "$TOKEN_RESPONSE" | grep -q "token"; then
        TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        log_success "Authentication token generated: $TOKEN"
        
        # Save token to file
        echo "$TOKEN" > .sonarqube-token
        log_info "Token saved to .sonarqube-token file"
    else
        log_warning "Failed to generate token. You may need to create it manually."
    fi
    
    # Set quality gate
    log_info "Setting up quality gate..."
    curl -s -u "$ADMIN_USER:$ADMIN_PASS" -X POST "$SONARQUBE_URL/api/qualitygates/select" \
        -d "projectKey=$PROJECT_KEY&gateId=1" || log_warning "Failed to set quality gate"
    
    log_success "SonarQube project setup completed"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -s, --start-only    Only start SonarQube, don't configure project"
    echo "  -c, --config-only   Only configure project, assume SonarQube is running"
    echo "  -r, --restart       Restart SonarQube services"
    echo "  --stop              Stop SonarQube services"
    echo ""
    echo "Examples:"
    echo "  $0                  Start SonarQube and configure project"
    echo "  $0 -s               Only start SonarQube"
    echo "  $0 -c               Only configure project"
    echo "  $0 --stop           Stop SonarQube"
    echo ""
}

stop_sonarqube() {
    log_info "Stopping SonarQube..."
    docker-compose -f docker-compose.sonarqube.yml down
    log_success "SonarQube stopped"
}

restart_sonarqube() {
    log_info "Restarting SonarQube..."
    docker-compose -f docker-compose.sonarqube.yml restart
    log_success "SonarQube restarted"
}

show_info() {
    echo ""
    echo "=== SonarQube Information ==="
    echo "URL: $SONARQUBE_URL"
    echo "Username: $ADMIN_USER"
    echo "Password: $ADMIN_PASS"
    echo "Project Key: $PROJECT_KEY"
    echo ""
    echo "=== Usage Instructions ==="
    echo "1. Access SonarQube at: $SONARQUBE_URL"
    echo "2. Login with admin/$ADMIN_PASS"
    echo "3. Configure Jenkins with the generated token"
    echo "4. Run analysis: sonar-scanner"
    echo ""
}

main() {
    local start_only=false
    local config_only=false
    local restart=false
    local stop=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--start-only)
                start_only=true
                shift
                ;;
            -c|--config-only)
                config_only=true
                shift
                ;;
            -r|--restart)
                restart=true
                shift
                ;;
            --stop)
                stop=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    check_prerequisites
    
    if [ "$stop" = true ]; then
        stop_sonarqube
        exit 0
    fi
    
    if [ "$restart" = true ]; then
        restart_sonarqube
        exit 0
    fi
    
    if [ "$config_only" = false ]; then
        start_sonarqube
    fi
    
    if [ "$start_only" = false ]; then
        setup_sonarqube_project
    fi
    
    show_info
    log_success "SonarQube setup completed successfully!"
}

# Run main function
main "$@" 