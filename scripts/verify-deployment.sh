#!/bin/bash

# Application Verification Script
# This script verifies that the Flask application is deployed and working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="flask-hello-world"
NAMESPACE="flask-hello-world"
LOCAL_PORT="8080"
SERVICE_PORT="80"
MAX_RETRIES=30
RETRY_INTERVAL=5

# Test configuration
EXPECTED_RESPONSE="Hello, World!"
PERFORMANCE_THRESHOLD=2.0  # seconds
STRESS_TEST_REQUESTS=100
STRESS_TEST_CONCURRENCY=10

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

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=0
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        missing=1
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        missing=1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

check_namespace() {
    log_test "Checking if namespace exists..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_success "Namespace '$NAMESPACE' exists"
        return 0
    else
        log_error "Namespace '$NAMESPACE' does not exist"
        return 1
    fi
}

check_deployment() {
    log_test "Checking deployment status..."
    
    # Check if deployment exists
    if ! kubectl get deployment "$APP_NAME" -n "$NAMESPACE" &> /dev/null; then
        log_error "Deployment '$APP_NAME' not found in namespace '$NAMESPACE'"
        return 1
    fi
    
    # Check deployment status
    local ready_replicas=$(kubectl get deployment "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local replicas=$(kubectl get deployment "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [ "$ready_replicas" = "$replicas" ] && [ "$replicas" != "0" ]; then
        log_success "Deployment is ready: $ready_replicas/$replicas replicas"
        return 0
    else
        log_error "Deployment is not ready: $ready_replicas/$replicas replicas"
        return 1
    fi
}

check_pods() {
    log_test "Checking pod status..."
    
    local pods=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" --no-headers 2>/dev/null || echo "")
    
    if [ -z "$pods" ]; then
        log_error "No pods found for app '$APP_NAME'"
        return 1
    fi
    
    local running_count=0
    local total_count=0
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            total_count=$((total_count + 1))
            local status=$(echo "$line" | awk '{print $3}')
            local ready=$(echo "$line" | awk '{print $2}')
            
            if [ "$status" = "Running" ] && [[ "$ready" == *"/"* ]]; then
                local ready_containers=$(echo "$ready" | cut -d'/' -f1)
                local total_containers=$(echo "$ready" | cut -d'/' -f2)
                
                if [ "$ready_containers" = "$total_containers" ]; then
                    running_count=$((running_count + 1))
                fi
            fi
        fi
    done <<< "$pods"
    
    if [ $running_count -eq $total_count ] && [ $total_count -gt 0 ]; then
        log_success "All pods are running: $running_count/$total_count"
        return 0
    else
        log_error "Not all pods are running: $running_count/$total_count"
        return 1
    fi
}

check_service() {
    log_test "Checking service status..."
    
    if ! kubectl get service "$APP_NAME" -n "$NAMESPACE" &> /dev/null; then
        log_error "Service '$APP_NAME' not found in namespace '$NAMESPACE'"
        return 1
    fi
    
    local service_type=$(kubectl get service "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.type}')
    local cluster_ip=$(kubectl get service "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')
    
    log_success "Service '$APP_NAME' exists (Type: $service_type, ClusterIP: $cluster_ip)"
    return 0
}

setup_port_forward() {
    log_test "Setting up port forwarding..."
    
    # Kill any existing port forwards
    pkill -f "kubectl.*port-forward.*$APP_NAME" || true
    
    # Start port forwarding in background
    kubectl port-forward -n "$NAMESPACE" "svc/$APP_NAME" "$LOCAL_PORT:$SERVICE_PORT" &
    local pf_pid=$!
    
    # Wait for port forward to be ready
    local attempts=0
    while [ $attempts -lt 10 ]; do
        if nc -z localhost "$LOCAL_PORT" &> /dev/null; then
            log_success "Port forwarding is ready (PID: $pf_pid)"
            echo "$pf_pid" > /tmp/port-forward.pid
            return 0
        fi
        
        sleep 2
        attempts=$((attempts + 1))
    done
    
    log_error "Port forwarding failed to start"
    kill $pf_pid 2>/dev/null || true
    return 1
}

cleanup_port_forward() {
    if [ -f /tmp/port-forward.pid ]; then
        local pid=$(cat /tmp/port-forward.pid)
        kill $pid 2>/dev/null || true
        rm -f /tmp/port-forward.pid
        log_info "Port forwarding cleaned up"
    fi
    
    # Kill any remaining port forward processes
    pkill -f "kubectl.*port-forward.*$APP_NAME" || true
}

test_connectivity() {
    log_test "Testing application connectivity..."
    
    local url="http://localhost:$LOCAL_PORT"
    local attempts=0
    
    while [ $attempts -lt $MAX_RETRIES ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            log_success "Application is reachable at $url"
            return 0
        fi
        
        log_info "Waiting for application to be ready... (attempt $((attempts + 1))/$MAX_RETRIES)"
        sleep $RETRY_INTERVAL
        attempts=$((attempts + 1))
    done
    
    log_error "Application is not reachable after $MAX_RETRIES attempts"
    return 1
}

test_response_content() {
    log_test "Testing response content..."
    
    local url="http://localhost:$LOCAL_PORT"
    local response=$(curl -s "$url" 2>/dev/null || echo "")
    
    if [ "$response" = "$EXPECTED_RESPONSE" ]; then
        log_success "Response content is correct: '$response'"
        return 0
    else
        log_error "Response content is incorrect. Expected: '$EXPECTED_RESPONSE', Got: '$response'"
        return 1
    fi
}

test_http_status() {
    log_test "Testing HTTP status codes..."
    
    local url="http://localhost:$LOCAL_PORT"
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$status" = "200" ]; then
        log_success "HTTP status is correct: $status"
        return 0
    else
        log_error "HTTP status is incorrect: $status (expected 200)"
        return 1
    fi
}

test_response_headers() {
    log_test "Testing response headers..."
    
    local url="http://localhost:$LOCAL_PORT"
    local headers=$(curl -s -I "$url" 2>/dev/null || echo "")
    
    if echo "$headers" | grep -q "HTTP/1.1 200 OK\|HTTP/1.0 200 OK"; then
        log_success "Response headers are correct"
        
        # Check for security headers (optional)
        if echo "$headers" | grep -qi "content-type"; then
            local content_type=$(echo "$headers" | grep -i "content-type" | head -1 | cut -d':' -f2 | xargs)
            log_info "Content-Type: $content_type"
        fi
        
        return 0
    else
        log_error "Response headers are incorrect"
        return 1
    fi
}

test_performance() {
    log_test "Testing response time performance..."
    
    local url="http://localhost:$LOCAL_PORT"
    local response_time=$(curl -s -o /dev/null -w "%{time_total}" "$url" 2>/dev/null || echo "999")
    
    # Convert to comparable format (remove decimal point for comparison)
    local response_time_int=$(echo "$response_time * 1000" | bc 2>/dev/null | cut -d'.' -f1 || echo "999000")
    local threshold_int=$(echo "$PERFORMANCE_THRESHOLD * 1000" | bc 2>/dev/null | cut -d'.' -f1 || echo "2000")
    
    if [ "$response_time_int" -lt "$threshold_int" ]; then
        log_success "Response time is acceptable: ${response_time}s (threshold: ${PERFORMANCE_THRESHOLD}s)"
        return 0
    else
        log_warning "Response time is slow: ${response_time}s (threshold: ${PERFORMANCE_THRESHOLD}s)"
        return 1
    fi
}

test_error_handling() {
    log_test "Testing error handling..."
    
    local url="http://localhost:$LOCAL_PORT/nonexistent-endpoint"
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$status" = "404" ]; then
        log_success "Error handling is correct: 404 for non-existent endpoint"
        return 0
    else
        log_warning "Error handling might be incorrect: $status for non-existent endpoint (expected 404)"
        return 1
    fi
}

test_multiple_requests() {
    log_test "Testing multiple concurrent requests..."
    
    local url="http://localhost:$LOCAL_PORT"
    local success_count=0
    local total_requests=10
    
    for i in $(seq 1 $total_requests); do
        if curl -s -f "$url" > /dev/null 2>&1; then
            success_count=$((success_count + 1))
        fi
    done
    
    if [ $success_count -eq $total_requests ]; then
        log_success "All concurrent requests successful: $success_count/$total_requests"
        return 0
    else
        log_warning "Some concurrent requests failed: $success_count/$total_requests"
        return 1
    fi
}

run_stress_test() {
    log_test "Running stress test..."
    
    if ! command -v ab &> /dev/null; then
        log_warning "Apache Bench (ab) not available, skipping stress test"
        return 0
    fi
    
    local url="http://localhost:$LOCAL_PORT/"
    
    log_info "Running $STRESS_TEST_REQUESTS requests with concurrency $STRESS_TEST_CONCURRENCY"
    
    local ab_output=$(ab -n $STRESS_TEST_REQUESTS -c $STRESS_TEST_CONCURRENCY "$url" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        local failed_requests=$(echo "$ab_output" | grep "Failed requests:" | awk '{print $3}')
        local requests_per_second=$(echo "$ab_output" | grep "Requests per second:" | awk '{print $4}')
        
        if [ "$failed_requests" = "0" ]; then
            log_success "Stress test passed: 0 failed requests, $requests_per_second req/sec"
            return 0
        else
            log_warning "Stress test completed with $failed_requests failed requests"
            return 1
        fi
    else
        log_warning "Stress test failed to run"
        return 1
    fi
}

check_pod_logs() {
    log_test "Checking pod logs for errors..."
    
    local pods=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" -o name 2>/dev/null || echo "")
    
    if [ -z "$pods" ]; then
        log_warning "No pods found to check logs"
        return 1
    fi
    
    local error_count=0
    
    while IFS= read -r pod; do
        if [ -n "$pod" ]; then
            local logs=$(kubectl logs "$pod" -n "$NAMESPACE" --tail=50 2>/dev/null || echo "")
            
            # Check for common error patterns
            if echo "$logs" | grep -qi "error\|exception\|traceback\|failed\|fatal"; then
                log_warning "Potential errors found in logs for $pod"
                error_count=$((error_count + 1))
            fi
        fi
    done <<< "$pods"
    
    if [ $error_count -eq 0 ]; then
        log_success "No errors found in pod logs"
        return 0
    else
        log_warning "Potential errors found in $error_count pod(s)"
        return 1
    fi
}

generate_report() {
    log_info "Generating verification report..."
    
    local report_file="verification-report.txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$report_file" << EOF
# Application Verification Report
Generated: $timestamp

## Summary
Application: $APP_NAME
Namespace: $NAMESPACE
Verification completed successfully.

## Test Results
EOF
    
    # Add test results
    echo "- ✅ Namespace check: PASSED" >> "$report_file"
    echo "- ✅ Deployment check: PASSED" >> "$report_file"
    echo "- ✅ Pod status check: PASSED" >> "$report_file"
    echo "- ✅ Service check: PASSED" >> "$report_file"
    echo "- ✅ Connectivity test: PASSED" >> "$report_file"
    echo "- ✅ Response content test: PASSED" >> "$report_file"
    echo "- ✅ HTTP status test: PASSED" >> "$report_file"
    
    # Add deployment info
    cat >> "$report_file" << EOF

## Deployment Information
EOF
    
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$APP_NAME" >> "$report_file" 2>/dev/null || true
    echo "" >> "$report_file"
    kubectl get services -n "$NAMESPACE" >> "$report_file" 2>/dev/null || true
    
    log_success "Verification report generated: $report_file"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -n, --namespace NAME    Specify namespace (default: $NAMESPACE)"
    echo "  -a, --app NAME          Specify app name (default: $APP_NAME)"
    echo "  -p, --port PORT         Specify local port for port-forward (default: $LOCAL_PORT)"
    echo "  --skip-stress           Skip stress testing"
    echo "  --quick                 Run only basic tests"
    echo "  --verbose               Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                      Run all verification tests"
    echo "  $0 --quick              Run only basic tests"
    echo "  $0 -n my-namespace      Test app in different namespace"
    echo ""
}

main() {
    local skip_stress=false
    local quick_mode=false
    local verbose=false
    
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
            -a|--app)
                APP_NAME="$2"
                shift 2
                ;;
            -p|--port)
                LOCAL_PORT="$2"
                shift 2
                ;;
            --skip-stress)
                skip_stress=true
                shift
                ;;
            --quick)
                quick_mode=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set up cleanup trap
    trap cleanup_port_forward EXIT
    
    log_info "Starting application verification..."
    log_info "App: $APP_NAME, Namespace: $NAMESPACE, Port: $LOCAL_PORT"
    
    # Run verification tests
    local failed=0
    
    check_prerequisites || failed=$((failed + 1))
    check_namespace || failed=$((failed + 1))
    check_deployment || failed=$((failed + 1))
    check_pods || failed=$((failed + 1))
    check_service || failed=$((failed + 1))
    
    setup_port_forward || failed=$((failed + 1))
    
    if [ $failed -eq 0 ]; then
        test_connectivity || failed=$((failed + 1))
        test_response_content || failed=$((failed + 1))
        test_http_status || failed=$((failed + 1))
        test_response_headers || failed=$((failed + 1))
        
        if [ "$quick_mode" = false ]; then
            test_performance || true  # Don't fail on performance warnings
            test_error_handling || true  # Don't fail on error handling warnings
            test_multiple_requests || failed=$((failed + 1))
            check_pod_logs || true  # Don't fail on log warnings
            
            if [ "$skip_stress" = false ]; then
                run_stress_test || true  # Don't fail on stress test warnings
            fi
        fi
    fi
    
    cleanup_port_forward
    
    if [ $failed -eq 0 ]; then
        log_success "🎉 All verification tests passed!"
        generate_report
        exit 0
    else
        log_error "❌ $failed verification test(s) failed"
        exit 1
    fi
}

# Run main function
main "$@" 