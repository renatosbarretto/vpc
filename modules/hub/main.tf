# =============================================================================
# MODULE: HUB VPC
# Central networking hub with Transit Gateway for multi-VPC connectivity
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

  // Calcula os CIDRs para as subnets públicas
  public_subnet_cidrs = [
    for i in range(var.number_of_azs) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i)
  ]

  // Calcula os CIDRs para as subnets privadas, começando após as públicas
  private_subnet_cidrs = [
    for i in range(var.number_of_azs) : cidrsubnet(var.vpc_cidr, local.subnet_newbits, i + var.number_of_azs)
  ]
}

# =============================================================================
# VPC HUB
# =============================================================================

resource "aws_vpc" "hub" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "hub-vpc"
  })
}

# =============================================================================
# SUBNETS - Generated dynamically using cidrsubnet()
# =============================================================================

# Subnets públicas
resource "aws_subnet" "public" {
  count             = var.number_of_azs
  vpc_id            = aws_vpc.hub.id
  cidr_block        = local.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "hub-public-${data.aws_availability_zones.available.names[count.index]}"
    Type = "public"
  })
}

# Subnets privadas
resource "aws_subnet" "private" {
  count             = var.number_of_azs
  vpc_id            = aws_vpc.hub.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "hub-private-${data.aws_availability_zones.available.names[count.index]}"
    Type = "private"
  })
}

# =============================================================================
# INTERNET GATEWAY
# =============================================================================

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = merge(var.common_tags, {
    Name = "hub-igw"
  })
}

# =============================================================================
# ELASTIC IPs para NAT Gateways
# =============================================================================

resource "aws_eip" "nat" {
  count  = var.number_of_azs
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "hub-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.hub]
}

# =============================================================================
# NAT GATEWAYS
# =============================================================================

resource "aws_nat_gateway" "hub" {
  count         = var.number_of_azs
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, {
    Name = "hub-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.hub]
}

# =============================================================================
# TRANSIT GATEWAY
# =============================================================================

resource "aws_ec2_transit_gateway" "hub" {
  description = "Transit Gateway for Hub and Spoke architecture"

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = merge(var.common_tags, {
    Name = "hub-transit-gateway"
  })
}

resource "aws_ec2_transit_gateway_route_table" "hub_spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.hub.id

  tags = merge(var.common_tags, {
    Name = "hub-spoke-tgw-rt"
  })
}

# =============================================================================
# ROUTE TABLES
# =============================================================================

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  tags = merge(var.common_tags, {
    Name = "hub-public-rt"
  })
}

# Route Tables Privadas (uma por AZ)
resource "aws_route_table" "private" {
  count  = var.number_of_azs
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub[count.index].id
  }

  tags = merge(var.common_tags, {
    Name = "hub-private-rt-${count.index + 1}"
  })
}

# =============================================================================
# ROUTE TABLE ASSOCIATIONS
# =============================================================================

# Associações das subnets públicas
resource "aws_route_table_association" "public" {
  count          = var.number_of_azs
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associações das subnets privadas
resource "aws_route_table_association" "private" {
  count          = var.number_of_azs
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# =============================================================================
# TRANSIT GATEWAY DNS SUPPORT
# =============================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = aws_subnet.private[*].id
  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  vpc_id             = aws_vpc.hub.id

  dns_support = "enable"

  tags = merge(var.common_tags, {
    Name = "hub-tgw-attachment"
  })
}

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_spoke.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_spoke.id
}

# =============================================================================
# ROTAS PARA SPOKES (serão criadas dinamicamente)
# =============================================================================

# Este recurso será usado para adicionar rotas para os spokes
# As rotas específicas serão criadas no módulo principal 