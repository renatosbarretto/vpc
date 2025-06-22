# VPC Hub - Networking Central
# Esta VPC funciona como hub para conectar as outras VPCs

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "vpc-hub-spoke"
      Environment = "hub"
      ManagedBy   = "terraform"
    }
  }
}

# =============================================================================
# VPC HUB
# =============================================================================

# VPC Principal
resource "aws_vpc" "hub" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-hub"
  }
}

# Subnets Públicas (para NAT Gateway e Transit Gateway)
resource "aws_subnet" "hub_public" {
  count             = 4
  vpc_id            = aws_vpc.hub.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "hub-public-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# Subnets Privadas (para recursos internos)
resource "aws_subnet" "hub_private" {
  count             = 4
  vpc_id            = aws_vpc.hub.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "hub-private-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# =============================================================================
# INTERNET GATEWAY
# =============================================================================

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "hub-igw"
  }
}

# =============================================================================
# NAT GATEWAY
# =============================================================================

# Elastic IP para NAT Gateway
resource "aws_eip" "hub_nat" {
  count = 4
  domain = "vpc"

  tags = {
    Name = "hub-nat-eip-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "hub" {
  count         = 4
  allocation_id = aws_eip.hub_nat[count.index].id
  subnet_id     = aws_subnet.hub_public[count.index].id

  tags = {
    Name = "hub-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.hub]
}

# =============================================================================
# TRANSIT GATEWAY
# =============================================================================

# Transit Gateway
resource "aws_ec2_transit_gateway" "hub" {
  description = "Transit Gateway para Hub and Spoke"

  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "hub-transit-gateway"
  }
}

# =============================================================================
# ROUTE TABLES
# =============================================================================

# Route Table Pública
resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  tags = {
    Name = "hub-public-rt"
  }
}

# Route Tables Privadas
resource "aws_route_table" "hub_private" {
  count  = 4
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub[count.index].id
  }

  tags = {
    Name = "hub-private-rt-${count.index + 1}"
  }
}

# Gerencia a tabela de rotas principal (default) para nomeá-la
resource "aws_default_route_table" "hub_default" {
  default_route_table_id = aws_vpc.hub.main_route_table_id

  tags = {
    Name = "hub-main-rt-unused"
  }
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS
# =============================================================================

# Associações das subnets públicas
resource "aws_route_table_association" "hub_public" {
  count          = 4
  subnet_id      = aws_subnet.hub_public[count.index].id
  route_table_id = aws_route_table.hub_public.id
}

# Associações das subnets privadas
resource "aws_route_table_association" "hub_private" {
  count          = 4
  subnet_id      = aws_subnet.hub_private[count.index].id
  route_table_id = aws_route_table.hub_private[count.index].id
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
} 