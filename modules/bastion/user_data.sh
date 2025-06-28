#!/bin/bash

# Update system
yum update -y

# Install useful tools for bastion host
yum install -y \
    htop \
    vim \
    wget \
    curl \
    unzip \
    git \
    nc

# Configure SSH
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# Install Session Manager plugin (for AWS Systems Manager)
yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

# Install kubectl for Kubernetes management
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install helm (Kubernetes package manager)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create kubectl configuration directory for ec2-user
mkdir -p /home/ec2-user/.kube
chown ec2-user:ec2-user /home/ec2-user/.kube

# Add kubectl completion and aliases for ec2-user
echo 'source <(kubectl completion bash)' >> /home/ec2-user/.bashrc
echo 'alias k=kubectl' >> /home/ec2-user/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ec2-user/.bashrc
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bashrc

# Create useful scripts for K8s management
cat > /home/ec2-user/setup-kubeconfig.sh << 'EOF'
#!/bin/bash
# Script to copy kubeconfig from K3s master node
# Usage: ./setup-kubeconfig.sh <master-private-ip> <key-file>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <master-private-ip> <key-file>"
    echo "Example: $0 10.0.3.100 ~/.ssh/rs-devops-key.pem"
    exit 1
fi

MASTER_IP=$1
KEY_FILE=$2

echo "Copying kubeconfig from K3s master at $MASTER_IP..."
scp -i $KEY_FILE -o StrictHostKeyChecking=no ubuntu@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Replace localhost with actual master IP
sed -i "s/127.0.0.1/$MASTER_IP/g" ~/.kube/config

echo "Kubeconfig setup complete!"
echo "Testing connection..."
kubectl get nodes
EOF

chmod +x /home/ec2-user/setup-kubeconfig.sh
chown ec2-user:ec2-user /home/ec2-user/setup-kubeconfig.sh

# Create a welcome message
cat > /etc/motd << EOF
Welcome to ${project_name} Bastion Host
======================================

This is a secure jump server for accessing private resources and managing Kubernetes.

Available tools:
- AWS CLI v2
- kubectl (Kubernetes CLI)
- helm (Kubernetes package manager)
- Session Manager Plugin
- Standard Linux utilities

Kubernetes Management:
- Run './setup-kubeconfig.sh <master-ip> <key-file>' to configure kubectl
- Use 'kubectl get nodes' to check cluster status
- Use 'k' as an alias for kubectl

Security Notice:
- SSH key authentication only
- Root login disabled
- All connections are logged

EOF

# Set hostname
hostnamectl set-hostname ${project_name}-bastion

# Configure CloudWatch agent (optional)
yum install -y amazon-cloudwatch-agent

# Enable and start services
systemctl enable sshd
systemctl start sshd

echo "Bastion host setup completed at $(date)" >> /var/log/user-data.log 