terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Security Group: The "Firewall"
# We open Port 80 (Website), 22 (SSH), and 30000-32767 (Kubernetes Apps)
resource "aws_security_group" "online_vote_sg" {
  name        = "online_vote_sg"
  description = "Allow Kubernetes and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Key Pair: This lets you log in securely
resource "aws_key_pair" "deployer" {
  key_name   = "project-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbVz+1Vj7R8BENi6UPbCAQCIeglz1PHioHHaacRehVcXWCQGU8B/FSoPiKw0x1VTBWHaE5RJwJMzAy/J1plr8ADBQdhb/NV1BlYO5acT8LlwjYtbJlc4HrqVzJbkwYJ6UHoElFjJPh1eWYIWsePxk+ZMRBRZbb2cQb5uoX3lr70+naCxkH0jKAmbV0KfXNnXQ9vopVewR0NvwXy/RABt9l+SYM64nkUZS3vl2wYCnt/LxM9WFkB6x8m1bFPhck3NjvYmHwLlksYeebifq5zck3fVWApMrViiLO7eicziRsIYi8ylLK5EOeGEUQ1vZLF7g4yJ/GW6s2QM7vCPulbcUB redmi@DESKTOP-MC09I0A"
}

# 3. The Server (EC2)
resource "aws_instance" "k8s_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 (US East 1)
  instance_type = "t3.micro"            # FREE TIER SAFE

  vpc_security_group_ids = [aws_security_group.online_vote_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-EOF
#!/bin/bash
# 1. Install Docker
apt-get update -y
apt-get install -y docker.io
usermod -aG docker ubuntu

# 2. Install K3s (Lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -s - --disable traefik --write-kubeconfig-mode 644

# 3. Create Swap Memory
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 4. Configure Environment
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/ubuntu/.bashrc
EOF

  tags = {
    Name = "Student-Project-FreeTier"
  }
}

output "server_ip" {
  value = aws_instance.k8s_server.public_ip
}