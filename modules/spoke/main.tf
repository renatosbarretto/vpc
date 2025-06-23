# =============================================================================
# MODULE: SPOKE VPC
# Spoke VPC connected to Hub via Transit Gateway
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  // Define o número de bits para as subnets. /16 para VPC, /24 para subnets -> 8 bits.
  subnet_newbits = 8

  // Calcula os CIDRs para as subnets privadas
  private_subnet_cidrs = [
    for i in range(var.number_of_azs) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i)
  ]
}

# =============================================================================
# VPC SPOKE
# =============================================================================

resource "aws_vpc" "spoke" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.spoke_name}-vpc"
  })
}

# =============================================================================
# SUBNETS PRIVADAS - Generated dynamically using cidrsubnet()
# =============================================================================

resource "aws_subnet" "private" {
  count             = var.number_of_azs
  vpc_id            = aws_vpc.spoke.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.spoke_name}-private-${data.aws_availability_zones.available.names[count.index]}"
    Type = "private"
  })
}

# =============================================================================
# TRANSIT GATEWAY ATTACHMENT
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke" {
  subnet_ids         = aws_subnet.private[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.spoke.id

  dns_support = "enable"

  tags = merge(var.common_tags, {
    Name = "${var.spoke_name}-tgw-attachment"
  })

  depends_on = [var.transit_gateway_attachment_dependencies]
}

# =============================================================================
# ROUTE TABLE
# =============================================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.spoke.id

  tags = merge(var.common_tags, {
    Name = "${var.spoke_name}-private-rt"
  })
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS
# =============================================================================

resource "aws_route_table_association" "private" {
  count          = var.number_of_azs
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# =============================================================================
# ROTAS DINÂMICAS
# =============================================================================

# Rota para internet via Transit Gateway (será configurada no módulo principal)
# Esta rota será adicionada dinamicamente após a criação do attachment

# Rota para comunicação com o Hub (será configurada no módulo principal)
# Esta rota será adicionada dinamicamente após a criação do attachment

# =============================================================================
# VPC ENDPOINTS FOR SSM
# =============================================================================

resource "aws_security_group" "vpc_endpoints" {
  name   = "${var.spoke_name}-vpc-endpoints-sg"
  vpc_id = aws_vpc.spoke.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.common_tags, {
    Name = "${var.spoke_name}-vpc-endpoints-sg"
  })
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.spoke.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  tags = merge(var.common_tags, {
    Name = "${var.spoke_name}-ssm-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.spoke.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  tags = merge(var.common_tags, {
    Name = "${var.spoke_name}-ssmmessages-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.spoke.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  tags = merge(var.common_tags, {
    Name = "${var.spoke_name}-ec2messages-endpoint"
  })
} 