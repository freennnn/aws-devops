# S3 Bucket
resource "aws_s3_bucket" "demo_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "demo_bucket_versioning" {
  bucket = aws_s3_bucket.demo_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# EC2 Instance
resource "aws_instance" "demo_instance" {
  ami           = "ami-0c7217cdde317cfec"  # Amazon Linux 2023 AMI in us-east-1
  instance_type = var.instance_type

  tags = {
    Name        = "terraform-demo-instance"
    Environment = var.environment
  }
} 