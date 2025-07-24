#!/bin/bash

# Stress Test Script for Alert Verification
# This script generates CPU and memory load to test alert rules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="monitoring"
STRESS_NAMESPACE="stress-test"
CPU_STRESS_DURATION="300"  # 5 minutes
MEMORY_STRESS_DURATION="300"  # 5 minutes

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
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    # Check if monitoring namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_error "Monitoring namespace '$NAMESPACE' does not exist. Deploy monitoring stack first."
        exit 1
    fi
    
    # Check if Prometheus is running
    if ! kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=kube-prometheus | grep -q Running; then
        log_error "Prometheus is not running. Deploy monitoring stack first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

create_stress_namespace() {
    log_info "Creating stress test namespace..."
    
    if kubectl get namespace "$STRESS_NAMESPACE" &> /dev/null; then
        log_warning "Stress test namespace already exists"
    else
        kubectl create namespace "$STRESS_NAMESPACE"
        log_success "Stress test namespace created"
    fi
}

deploy_stress_pods() {
    log_info "Deploying stress test pods..."
    
    # CPU Stress Pod
    cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-stress
  namespace: $STRESS_NAMESPACE
  labels:
    app: cpu-stress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-stress
  template:
    metadata:
      labels:
        app: cpu-stress
    spec:
      containers:
      - name: stress
        image: polinux/stress
        command: ["stress"]
        args: 
          - "--cpu"
          - "2"
          - "--timeout"
          - "${CPU_STRESS_DURATION}s"
          - "--verbose"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 2000m
            memory: 256Mi
      restartPolicy: Always
EOF

    # Memory Stress Pod
    cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-stress
  namespace: $STRESS_NAMESPACE
  labels:
    app: memory-stress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: memory-stress
  template:
    metadata:
      labels:
        app: memory-stress
    spec:
      containers:
      - name: stress
        image: polinux/stress
        command: ["stress"]
        args:
          - "--vm"
          - "2"
          - "--vm-bytes"
          - "512M"
          - "--timeout"
          - "${MEMORY_STRESS_DURATION}s"
          - "--verbose"
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 1Gi
      restartPolicy: Always
EOF

    log_success "Stress test pods deployed"
}

monitor_stress_test() {
    log_info "Monitoring stress test progress..."
    
    local start_time=$(date +%s)
    local max_duration=$((CPU_STRESS_DURATION > MEMORY_STRESS_DURATION ? CPU_STRESS_DURATION : MEMORY_STRESS_DURATION))
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $max_duration ]; then
            break
        fi
        
        echo ""
        echo "=== Stress Test Status (${elapsed}s elapsed) ==="
        
        # Check CPU stress pod
        local cpu_status=$(kubectl get pods -n "$STRESS_NAMESPACE" -l app=cpu-stress --no-headers | awk '{print $3}' | head -1)
        echo "CPU Stress Pod: $cpu_status"
        
        # Check memory stress pod
        local memory_status=$(kubectl get pods -n "$STRESS_NAMESPACE" -l app=memory-stress --no-headers | awk '{print $3}' | head -1)
        echo "Memory Stress Pod: $memory_status"
        
        # Show resource usage
        echo ""
        echo "=== Resource Usage ==="
        kubectl top nodes 2>/dev/null || echo "Metrics server not available"
        
        sleep 30
    done
    
    log_success "Stress test monitoring completed"
}

check_alerts() {
    log_info "Checking fired alerts..."
    
    # Port forward to Prometheus
    kubectl port-forward -n "$NAMESPACE" svc/prometheus-monitoring-kube-prometheus 9090:9090 &
    local pf_pid=$!
    
    sleep 10
    
    # Check alerts
    local alerts=$(curl -s http://localhost:9090/api/v1/alerts 2>/dev/null || echo "")
    
    if [ -n "$alerts" ]; then
        echo ""
        echo "=== Current Alerts ==="
        echo "$alerts" | jq -r '.data[] | select(.state == "firing") | "\(.labels.alertname): \(.labels.severity) - \(.annotations.summary)"' 2>/dev/null || echo "No alerts firing or jq not available"
        
        # Count firing alerts
        local firing_count=$(echo "$alerts" | jq -r '.data[] | select(.state == "firing") | .labels.alertname' 2>/dev/null | wc -l)
        
        if [ "$firing_count" -gt 0 ]; then
            log_success "$firing_count alert(s) are currently firing"
        else
            log_warning "No alerts are currently firing"
        fi
    else
        log_warning "Could not retrieve alerts from Prometheus"
    fi
    
    # Cleanup port forward
    kill $pf_pid 2>/dev/null || true
}

show_prometheus_targets() {
    log_info "Checking Prometheus targets..."
    
    # Port forward to Prometheus
    kubectl port-forward -n "$NAMESPACE" svc/prometheus-monitoring-kube-prometheus 9090:9090 &
    local pf_pid=$!
    
    sleep 10
    
    # Check targets
    local targets=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null || echo "")
    
    if [ -n "$targets" ]; then
        echo ""
        echo "=== Prometheus Targets ==="
        echo "$targets" | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health) - \(.lastScrape)"' 2>/dev/null | head -10 || echo "Could not parse targets"
    else
        log_warning "Could not retrieve targets from Prometheus"
    fi
    
    # Cleanup port forward
    kill $pf_pid 2>/dev/null || true
}

cleanup_stress_test() {
    log_info "Cleaning up stress test resources..."
    
    # Delete stress test deployments
    kubectl delete deployment cpu-stress -n "$STRESS_NAMESPACE" --ignore-not-found=true
    kubectl delete deployment memory-stress -n "$STRESS_NAMESPACE" --ignore-not-found=true
    
    # Wait for pods to terminate
    kubectl wait --for=delete pod -l app=cpu-stress -n "$STRESS_NAMESPACE" --timeout=60s || true
    kubectl wait --for=delete pod -l app=memory-stress -n "$STRESS_NAMESPACE" --timeout=60s || true
    
    # Delete namespace
    kubectl delete namespace "$STRESS_NAMESPACE" --ignore-not-found=true
    
    log_success "Stress test cleanup completed"
}

generate_test_report() {
    log_info "Generating stress test report..."
    
    local timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local report_file="stress-test-report-${timestamp}.md"
    
    cat > "$report_file" << EOF
# Stress Test Report

**Date**: $(date)
**Duration**: CPU ${CPU_STRESS_DURATION}s, Memory ${MEMORY_STRESS_DURATION}s

## Test Configuration

- **CPU Stress**: 2 cores for ${CPU_STRESS_DURATION} seconds
- **Memory Stress**: 2 VMs with 512MB each for ${MEMORY_STRESS_DURATION} seconds

## Results

### Pods Status
\`\`\`
$(kubectl get pods -n "$STRESS_NAMESPACE" --ignore-not-found=true || echo "No stress pods found")
\`\`\`

### Resource Usage
\`\`\`
$(kubectl top nodes 2>/dev/null || echo "Metrics server not available")
\`\`\`

### Monitoring Stack Status
\`\`\`
$(kubectl get pods -n "$NAMESPACE" | grep -E "(prometheus|grafana)")
\`\`\`

## Alerts Status

Check Prometheus UI at http://localhost:9090/alerts for current alert status.

## Next Steps

1. Access Grafana at http://localhost:3000 to view dashboards
2. Check email for alert notifications
3. Review alert rules configuration if needed
4. Adjust thresholds based on test results

EOF
    
    log_success "Test report generated: $report_file"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  --cpu-duration SECONDS  Duration for CPU stress test (default: 300)"
    echo "  --memory-duration SEC   Duration for memory stress test (default: 300)"
    echo "  --cleanup-only          Only cleanup existing stress tests"
    echo "  --check-alerts-only     Only check current alerts"
    echo ""
    echo "Examples:"
    echo "  $0                      Run full stress test"
    echo "  $0 --cpu-duration 600   Run 10-minute CPU stress test"
    echo "  $0 --cleanup-only       Clean up stress test resources"
    echo "  $0 --check-alerts-only  Check current alerts"
    echo ""
}

main() {
    local cleanup_only=false
    local check_alerts_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --cpu-duration)
                CPU_STRESS_DURATION="$2"
                shift 2
                ;;
            --memory-duration)
                MEMORY_STRESS_DURATION="$2"
                shift 2
                ;;
            --cleanup-only)
                cleanup_only=true
                shift
                ;;
            --check-alerts-only)
                check_alerts_only=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ "$cleanup_only" = true ]; then
        cleanup_stress_test
        exit 0
    fi
    
    if [ "$check_alerts_only" = true ]; then
        check_alerts
        show_prometheus_targets
        exit 0
    fi
    
    echo "🧪 Starting Alert Stress Test"
    echo "============================="
    echo "CPU Stress Duration: ${CPU_STRESS_DURATION}s"
    echo "Memory Stress Duration: ${MEMORY_STRESS_DURATION}s"
    echo ""
    
    check_prerequisites
    create_stress_namespace
    deploy_stress_pods
    
    # Wait for pods to start
    log_info "Waiting for stress test pods to start..."
    sleep 30
    
    # Monitor the test
    monitor_stress_test
    
    # Check alerts
    check_alerts
    show_prometheus_targets
    
    # Generate report
    generate_test_report
    
    echo ""
    echo "🎉 Stress Test Completed!"
    echo "========================"
    echo ""
    echo "Next Steps:"
    echo "1. Check Prometheus alerts at http://localhost:9090/alerts"
    echo "2. Check Grafana dashboards at http://localhost:3000"
    echo "3. Verify email notifications were sent"
    echo "4. Review the generated test report"
    echo ""
    echo "To cleanup stress test resources:"
    echo "$0 --cleanup-only"
    echo ""
}

# Run main function
main "$@" 