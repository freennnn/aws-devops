# Data source for latest Ubuntu 22.04 LTS AMI (k3s works well with Ubuntu)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# K3s Master Node
resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_instance_type
  key_name               = var.key_name
  subnet_id              = var.master_subnet_id
  vpc_security_group_ids = [var.security_group_id]

  # Enable detailed monitoring
  monitoring = true

  user_data = base64encode(templatefile("${path.module}/k3s_master_user_data.sh", {
    project_name = var.project_name
    node_token   = var.k3s_token
  }))

  tags = {
    Name                                        = "${var.project_name}-k3s-master"
    Type                                        = "K3s-Master"
    Environment                                 = "prod"
    ManagedBy                                   = "terraform"
    Project                                     = var.project_name
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }
}

# K3s Worker Node
resource "aws_instance" "k3s_worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  key_name               = var.key_name
  subnet_id              = var.worker_subnet_id
  vpc_security_group_ids = [var.security_group_id]

  # Enable detailed monitoring
  monitoring = true

  user_data = base64encode(templatefile("${path.module}/k3s_worker_user_data.sh", {
    project_name = var.project_name
    node_token   = var.k3s_token
    master_ip    = aws_instance.k3s_master.private_ip
  }))

  tags = {
    Name                                        = "${var.project_name}-k3s-worker"
    Type                                        = "K3s-Worker"
    Environment                                 = "prod"
    ManagedBy                                   = "terraform"
    Project                                     = var.project_name
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }

  depends_on = [aws_instance.k3s_master]
} 
