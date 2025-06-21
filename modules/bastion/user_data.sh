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
    git

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

# Create a welcome message
cat > /etc/motd << EOF
Welcome to ${project_name} Bastion Host
======================================

This is a secure jump server for accessing private resources.

Available tools:
- AWS CLI v2
- Session Manager Plugin
- Standard Linux utilities

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