resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-1"
    Type        = "Public"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-2"
    Type        = "Public"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name        = "${var.project_name}-private-subnet-1"
    Type        = "Private"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name        = "${var.project_name}-private-subnet-2"
    Type        = "Private"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_eip" "nat_1" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-1"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat_2" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-2"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main_1" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_1[0].id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name        = "${var.project_name}-nat-gateway-1"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main_2" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_2[0].id
  subnet_id     = aws_subnet.public_2.id

  tags = {
    Name        = "${var.project_name}-nat-gateway-2"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Type        = "Public"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main_1[0].id
    }
  }

  tags = {
    Name        = "${var.project_name}-private-rt-1"
    Type        = "Private"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main_2[0].id
    }
  }

  tags = {
    Name        = "${var.project_name}-private-rt-2"
    Type        = "Private"
    Environment = "prod"
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}



