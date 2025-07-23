#!/bin/bash

# Monitoring Stack Deployment Script
# Deploys Prometheus and Grafana to Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="monitoring"
PROMETHEUS_RELEASE="prometheus-monitoring"
GRAFANA_RELEASE="grafana-monitoring"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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
    
    local missing=0
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        missing=1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed"
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

create_namespace() {
    log_info "Creating monitoring namespace..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_warning "Namespace '$NAMESPACE' already exists"
    else
        kubectl create namespace "$NAMESPACE"
        log_success "Namespace '$NAMESPACE' created"
    fi
    
    # Label namespace for monitoring
    kubectl label namespace "$NAMESPACE" name=monitoring --overwrite
}

add_helm_repositories() {
    log_info "Adding Helm repositories..."
    
    # Add Bitnami repository
    helm repo add bitnami https://charts.bitnami.com/bitnami
    
    # Update repositories
    helm repo update
    
    log_success "Helm repositories updated"
}

create_secrets() {
    log_info "Creating secrets..."
    
    # Create Grafana admin password secret
    if kubectl get secret grafana-admin-secret -n "$NAMESPACE" &> /dev/null; then
        log_warning "Grafana admin secret already exists"
    else
        kubectl create secret generic grafana-admin-secret \
            --from-literal=password="MySecureGrafanaPassword123!" \
            -n "$NAMESPACE"
        log_success "Grafana admin secret created"
    fi
    
    # Create SMTP secret (template - user should update with real values)
    if kubectl get secret grafana-smtp-secret -n "$NAMESPACE" &> /dev/null; then
        log_warning "Grafana SMTP secret already exists"
    else
        kubectl create secret generic grafana-smtp-secret \
            --from-literal=username="your-email@gmail.com" \
            --from-literal=password="your-app-password" \
            -n "$NAMESPACE"
        log_success "Grafana SMTP secret created (update with real values)"
    fi
}

deploy_prometheus() {
    log_info "Deploying Prometheus..."
    
    cd "$PROJECT_ROOT/helm-charts/monitoring/prometheus"
    
    # Update dependencies
    helm dependency update
    
    # Deploy Prometheus
    helm upgrade --install "$PROMETHEUS_RELEASE" . \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --wait \
        --timeout=15m \
        --values values.yaml
    
    log_success "Prometheus deployed successfully"
}

deploy_grafana() {
    log_info "Deploying Grafana..."
    
    cd "$PROJECT_ROOT/helm-charts/monitoring/grafana"
    
    # Update dependencies
    helm dependency update
    
    # Deploy Grafana
    helm upgrade --install "$GRAFANA_RELEASE" . \
        --namespace "$NAMESPACE" \
        --wait \
        --timeout=10m \
        --values values.yaml
    
    log_success "Grafana deployed successfully"
}

apply_alert_rules() {
    log_info "Applying alert rules..."
    
    # Apply alert rules
    kubectl apply -f "$PROJECT_ROOT/helm-charts/monitoring/alert-rules.yaml" -n "$NAMESPACE"
    
    log_success "Alert rules applied"
}

wait_for_pods() {
    log_info "Waiting for pods to be ready..."
    
    # Wait for Prometheus pods
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kube-prometheus -n "$NAMESPACE" --timeout=300s
    
    # Wait for Grafana pods
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n "$NAMESPACE" --timeout=300s
    
    log_success "All pods are ready"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    echo ""
    echo "=== Monitoring Stack Status ==="
    kubectl get all -n "$NAMESPACE"
    
    echo ""
    echo "=== Persistent Volumes ==="
    kubectl get pvc -n "$NAMESPACE"
    
    echo ""
    echo "=== Services ==="
    kubectl get services -n "$NAMESPACE"
    
    echo ""
    echo "=== Alert Rules ==="
    kubectl get prometheusrules -n "$NAMESPACE"
    
    log_success "Deployment verification completed"
}

setup_port_forwarding() {
    log_info "Setting up port forwarding for local access..."
    
    # Stop any existing port forwards
    pkill -f "kubectl.*port-forward.*prometheus" || true
    pkill -f "kubectl.*port-forward.*grafana" || true
    
    # Start Prometheus port forward
    kubectl port-forward -n "$NAMESPACE" svc/"$PROMETHEUS_RELEASE"-kube-prometheus 9090:9090 &
    PROMETHEUS_PF_PID=$!
    
    # Start Grafana port forward
    kubectl port-forward -n "$NAMESPACE" svc/"$GRAFANA_RELEASE"-grafana 3000:3000 &
    GRAFANA_PF_PID=$!
    
    sleep 5
    
    echo ""
    echo "=== Access Information ==="
    echo "Prometheus: http://localhost:9090"
    echo "Grafana: http://localhost:3000"
    echo "  Username: admin"
    echo "  Password: MySecureGrafanaPassword123!"
    echo ""
    echo "Port forwarding PIDs:"
    echo "  Prometheus: $PROMETHEUS_PF_PID"
    echo "  Grafana: $GRAFANA_PF_PID"
    echo ""
    echo "To stop port forwarding:"
    echo "  kill $PROMETHEUS_PF_PID $GRAFANA_PF_PID"
    
    log_success "Port forwarding configured"
}

test_connectivity() {
    log_info "Testing connectivity..."
    
    # Test Prometheus
    if curl -s http://localhost:9090/-/healthy > /dev/null; then
        log_success "Prometheus is accessible at http://localhost:9090"
    else
        log_warning "Prometheus might not be ready yet. Try again in a few minutes."
    fi
    
    # Test Grafana
    if curl -s http://localhost:3000/api/health > /dev/null; then
        log_success "Grafana is accessible at http://localhost:3000"
    else
        log_warning "Grafana might not be ready yet. Try again in a few minutes."
    fi
}

generate_dashboard_json() {
    log_info "Generating dashboard JSON..."
    
    cat > "$PROJECT_ROOT/kubernetes-monitoring-dashboard.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Kubernetes Cluster Monitoring",
    "tags": ["kubernetes", "cluster", "monitoring"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 90}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 8, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "Memory Usage %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 90}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 8, "x": 8, "y": 0}
      },
      {
        "id": 3,
        "title": "Disk Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - ((node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"}) * 100)",
            "legendFormat": "Disk Usage %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 90}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 8, "x": 16, "y": 0}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF
    
    log_success "Dashboard JSON generated: kubernetes-monitoring-dashboard.json"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  --skip-prometheus       Skip Prometheus deployment"
    echo "  --skip-grafana          Skip Grafana deployment"
    echo "  --skip-port-forward     Skip port forwarding setup"
    echo "  --cleanup               Remove monitoring stack"
    echo ""
    echo "Examples:"
    echo "  $0                      Deploy complete monitoring stack"
    echo "  $0 --skip-port-forward  Deploy without setting up port forwarding"
    echo "  $0 --cleanup            Remove monitoring stack"
    echo ""
}

cleanup_monitoring() {
    log_info "Cleaning up monitoring stack..."
    
    # Stop port forwarding
    pkill -f "kubectl.*port-forward.*prometheus" || true
    pkill -f "kubectl.*port-forward.*grafana" || true
    
    # Uninstall releases
    helm uninstall "$PROMETHEUS_RELEASE" -n "$NAMESPACE" || true
    helm uninstall "$GRAFANA_RELEASE" -n "$NAMESPACE" || true
    
    # Delete alert rules
    kubectl delete -f "$PROJECT_ROOT/helm-charts/monitoring/alert-rules.yaml" -n "$NAMESPACE" || true
    
    # Delete secrets
    kubectl delete secret grafana-admin-secret -n "$NAMESPACE" || true
    kubectl delete secret grafana-smtp-secret -n "$NAMESPACE" || true
    
    # Delete namespace
    kubectl delete namespace "$NAMESPACE" || true
    
    log_success "Monitoring stack cleanup completed"
}

main() {
    local skip_prometheus=false
    local skip_grafana=false
    local skip_port_forward=false
    local cleanup=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --skip-prometheus)
                skip_prometheus=true
                shift
                ;;
            --skip-grafana)
                skip_grafana=true
                shift
                ;;
            --skip-port-forward)
                skip_port_forward=true
                shift
                ;;
            --cleanup)
                cleanup=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ "$cleanup" = true ]; then
        cleanup_monitoring
        exit 0
    fi
    
    echo "🚀 Starting Monitoring Stack Deployment"
    echo "======================================="
    
    check_prerequisites
    create_namespace
    add_helm_repositories
    create_secrets
    
    if [ "$skip_prometheus" = false ]; then
        deploy_prometheus
        apply_alert_rules
    fi
    
    if [ "$skip_grafana" = false ]; then
        deploy_grafana
    fi
    
    wait_for_pods
    verify_deployment
    generate_dashboard_json
    
    if [ "$skip_port_forward" = false ]; then
        setup_port_forwarding
        sleep 5
        test_connectivity
    fi
    
    echo ""
    echo "🎉 Monitoring Stack Deployment Completed!"
    echo "========================================="
    echo ""
    echo "Next Steps:"
    echo "1. Access Grafana at http://localhost:3000 (admin/MySecureGrafanaPassword123!)"
    echo "2. Access Prometheus at http://localhost:9090"
    echo "3. Update SMTP settings in Grafana for alerting"
    echo "4. Configure contact points and notification policies"
    echo "5. Test alert rules by generating CPU/memory load"
    echo ""
}

# Run main function
main "$@" 