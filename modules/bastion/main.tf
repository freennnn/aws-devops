# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
  }))

  tags = {
    Name        = "${var.project_name}-bastion"
    Type        = "Bastion"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

# Elastic IP for Bastion Host (optional but recommended)
resource "aws_eip" "bastion" {
  count    = var.enable_eip ? 1 : 0
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-bastion-eip"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }

  depends_on = [aws_instance.bastion]
} 
