# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_access.name

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              dnf update -y
              
              # Install Node.js 22 LTS (using NodeSource repository)
              curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
              dnf install -y nodejs
              
              # Verify Node.js installation
              node --version
              npm --version
              
              # Install PM2 globally
              npm install -g pm2
              
              # Install Caddy
              dnf install -y dnf-plugins-core
              dnf copr enable -y @caddy/caddy
              dnf install -y caddy
              
              # Start and enable Caddy
              systemctl enable caddy
              systemctl start caddy
              
              # Create application directory
              mkdir -p /var/www/myapp
              chown ec2-user:ec2-user /var/www/myapp
              EOF

  tags = {
    Name        = "${var.project_name}-web-server"
    OS          = "Amazon Linux 2023"
    NodeVersion = "22.x LTS"
  }
}

# IAM role for EC2 to access S3
resource "aws_iam_role" "ec2_s3_access" {
  name = "${var.project_name}-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "${var.project_name}-ec2-s3-policy"
  role = aws_iam_role.ec2_s3_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_access" {
  name = "${var.project_name}-ec2-s3-profile"
  role = aws_iam_role.ec2_s3_access.name
}
