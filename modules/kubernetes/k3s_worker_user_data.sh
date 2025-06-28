#!/bin/bash

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting K3s worker installation at $(date)"

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget htop vim git unzip

# Set hostname
hostnamectl set-hostname ${project_name}-k3s-worker

# Wait for master to be ready (simple check)
echo "Waiting for master node to be ready..."
while ! nc -z ${master_ip} 6443; do
  echo "Waiting for master at ${master_ip}:6443..."
  sleep 10
done

echo "Master node is ready, joining cluster..."

# Install K3s worker (agent)
curl -sfL https://get.k3s.io | K3S_URL=https://${master_ip}:6443 K3S_TOKEN="${node_token}" sh -s - \
  --node-ip $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Install kubectl for ubuntu user (for troubleshooting)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Add kubectl completion
echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc
echo 'alias k=kubectl' >> /home/ubuntu/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ubuntu/.bashrc

# Enable and start k3s-agent
systemctl enable k3s-agent
systemctl start k3s-agent

# Wait for the agent to be ready
sleep 30

echo "K3s worker installation completed at $(date)"
echo "Worker joined cluster with master at ${master_ip}"
echo "Worker node ready!" 