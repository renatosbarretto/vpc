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
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Encontra o Transit Gateway do Hub para se conectar a ele
data "aws_ec2_transit_gateway" "hub" {
  filter {
    name   = "tag:Name"
    values = ["hub-transit-gateway"]
  }
}

# =============================================================================
# VPC SPOKE DEV
# =============================================================================

resource "aws_vpc" "dev" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-dev"
  }
}

# =============================================================================
# SUBNETS
# =============================================================================

# Usamos a mesma fonte de dados para garantir que as subnets fiquem em AZs diferentes
data "aws_availability_zones" "available" {
  state = "available"
}

# Subnets Privadas
resource "aws_subnet" "dev_private" {
  count             = 2 # Começando com 2 AZs para o Spoke
  vpc_id            = aws_vpc.dev.id
  cidr_block        = "10.1.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "dev-private-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# =============================================================================
# TRANSIT GATEWAY ATTACHMENT
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "dev_attachment" {
  subnet_ids         = aws_subnet.dev_private[*].id
  transit_gateway_id = data.aws_ec2_transit_gateway.hub.id
  vpc_id             = aws_vpc.dev.id

  tags = {
    Name = "dev-spoke-attachment"
  }
}

# =============================================================================
# ROUTING
# =============================================================================

# Tabela de rotas para as subnets privadas
resource "aws_route_table" "dev_private" {
  vpc_id = aws_vpc.dev.id

  # Rota padrão aponta para o Transit Gateway
  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = data.aws_ec2_transit_gateway.hub.id
  }

  tags = {
    Name = "dev-private-rt"
  }
}

# Associação da tabela de rotas com as subnets
resource "aws_route_table_association" "dev_private" {
  count          = length(aws_subnet.dev_private)
  subnet_id      = aws_subnet.dev_private[count.index].id
  route_table_id = aws_route_table.dev_private.id
} 