#!/bin/bash
# User data script for Public EC2 instance

# Update system
yum update -y

# Install essential packages
yum install -y \
    htop \
    vim \
    git \
    wget \
    curl \
    net-tools \
    telnet

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Configure SSH for forwarding to private instances
cat >> /home/ec2-user/.ssh/config <<EOF
Host private-*
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF

chmod 600 /home/ec2-user/.ssh/config
chown ec2-user:ec2-user /home/ec2-user/.ssh/config

# Create welcome message
cat > /etc/motd <<EOF
======================================
  Welcome to Public EC2 Instance
  NT548 Lab 01 - Terraform Demo
======================================
This is a public EC2 instance that can:
- Access Internet directly via Internet Gateway
- SSH to private EC2 instances
- Act as a bastion/jump host

Installed tools:
- Docker & Docker Compose
- AWS CLI v2
- htop, vim, git, wget, curl

To connect to private instance:
ssh ec2-user@<private-ip>

======================================
EOF

# Log completion
echo "User data script completed at $(date)" > /var/log/userdata.log
