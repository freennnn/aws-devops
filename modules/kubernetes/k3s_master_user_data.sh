#!/bin/bash

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting K3s master installation at $(date)"

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget htop vim git unzip

# Set hostname
hostnamectl set-hostname ${project_name}-k3s-master

# Install K3s master
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" K3S_TOKEN="${node_token}" sh -s - \
  --cluster-init \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --disable servicelb \
  --node-ip $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
while ! kubectl get nodes >/dev/null 2>&1; do
  echo "Waiting for k3s..."
  sleep 10
done

# Make kubeconfig accessible
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
chmod 600 /home/ubuntu/.kube/config

# Install kubectl for ubuntu user
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Add kubectl completion
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

# Create a simple nginx deployment for testing
cat > /home/ubuntu/test-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
EOF

chown ubuntu:ubuntu /home/ubuntu/test-deployment.yaml

# Enable and start k3s
systemctl enable k3s
systemctl start k3s

# Wait for k3s to be fully ready
sleep 30

# Verify installation
kubectl get nodes
kubectl get pods --all-namespaces

echo "K3s master installation completed at $(date)"
echo "Cluster token: ${node_token}"
echo "Kubeconfig location: /etc/rancher/k3s/k3s.yaml"
echo "Master node ready!" 