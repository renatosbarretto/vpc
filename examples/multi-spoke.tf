# =============================================================================
# EXEMPLO: Múltiplos Spokes
# Este arquivo demonstra como usar os módulos para criar múltiplos spokes
# =============================================================================

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
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  environment = "prod"
  project     = "enterprise-network"
  
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
    Owner       = "Network Team"
    CostCenter  = "Infrastructure"
  }

  # Configuração de múltiplos spokes
  spokes = {
    dev = {
      vpc_cidr = "10.1.0.0/16"
      name     = "dev"
    }
    staging = {
      vpc_cidr = "10.2.0.0/16"
      name     = "staging"
    }
    prod = {
      vpc_cidr = "10.3.0.0/16"
      name     = "prod"
    }
    analytics = {
      vpc_cidr = "10.4.0.0/16"
      name     = "analytics"
    }
    ml = {
      vpc_cidr = "10.5.0.0/16"
      name     = "ml"
    }
  }
}

# =============================================================================
# MODULE: HUB
# =============================================================================

module "hub" {
  source = "../modules/hub"

  vpc_cidr        = "10.0.0.0/16"
  environment     = local.environment
  project         = local.project
  number_of_azs   = 3  # Alta disponibilidade para produção
  common_tags     = local.common_tags
}

# =============================================================================
# MODULE: SPOKES
# =============================================================================

module "spokes" {
  source = "../modules/spoke"
  
  for_each = local.spokes

  vpc_cidr                              = each.value.vpc_cidr
  environment                           = local.environment
  spoke_name                            = each.value.name
  project                              = local.project
  number_of_azs                        = 3  # Alta disponibilidade
  transit_gateway_id                   = module.hub.transit_gateway_id
  transit_gateway_attachment_dependencies = [module.hub.transit_gateway_attachment_id]
  common_tags                          = local.common_tags
}

# =============================================================================
# ROTAS DINÂMICAS
# =============================================================================

# Rotas do Hub para todos os Spokes
resource "aws_route" "hub_to_spokes" {
  for_each = local.spokes

  route_table_id         = module.hub.public_route_table_id
  destination_cidr_block = each.value.vpc_cidr
  transit_gateway_id     = module.hub.transit_gateway_id

  depends_on = [
    module.spokes[each.key].transit_gateway_attachment_id
  ]
}

# Rotas dos Spokes para internet via Hub
resource "aws_route" "spokes_to_internet" {
  for_each = local.spokes

  route_table_id         = module.spokes[each.key].private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.hub.transit_gateway_id

  depends_on = [
    module.spokes[each.key].transit_gateway_attachment_id
  ]
}

# Rotas dos Spokes para o Hub
resource "aws_route" "spokes_to_hub" {
  for_each = local.spokes

  route_table_id         = module.spokes[each.key].private_route_table_id
  destination_cidr_block = module.hub.vpc_cidr
  transit_gateway_id     = module.hub.transit_gateway_id

  depends_on = [
    module.spokes[each.key].transit_gateway_attachment_id
  ]
}

# =============================================================================
# TRANSIT GATEWAY ROUTE TABLE CONFIGURATION
# =============================================================================

# Propaga as rotas dos spokes na tabela de rotas do Transit Gateway
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes" {
  for_each = local.spokes

  transit_gateway_attachment_id  = module.spokes[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.hub.transit_gateway_route_table_id

  depends_on = [
    module.spokes[each.key].transit_gateway_attachment_id
  ]
}

# Associa os spokes na tabela de rotas do Transit Gateway
resource "aws_ec2_transit_gateway_route_table_association" "spokes" {
  for_each = local.spokes

  transit_gateway_attachment_id  = module.spokes[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = module.hub.transit_gateway_route_table_id

  depends_on = [
    module.spokes[each.key].transit_gateway_attachment_id
  ]
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "network_architecture" {
  description = "Resumo da arquitetura de rede"
  value = {
    hub = {
      vpc_cidr        = module.hub.vpc_cidr
      public_subnets  = length(module.hub.public_subnet_ids)
      private_subnets = length(module.hub.private_subnet_ids)
      nat_gateways    = length(module.hub.nat_gateway_ids)
    }
    spokes = {
      count = length(module.spokes)
      names = keys(module.spokes)
      vpcs = {
        for k, v in module.spokes : k => {
          vpc_cidr = v.vpc_cidr
          subnets  = length(v.private_subnet_ids)
        }
      }
    }
    transit_gateway = {
      id  = module.hub.transit_gateway_id
      attachments = length(module.spokes) + 1 # +1 for hub attachment
    }
  }
} 