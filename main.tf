# =============================================================================
# MAIN TERRAFORM CONFIGURATION
# Hub and Spoke Architecture with Transit Gateway
# =============================================================================

# =============================================================================
# MODULE: HUB
# =============================================================================

module "hub" {
  source = "./modules/hub"

  vpc_cidr       = "10.0.0.0/16"
  environment    = local.environment
  project        = local.project
  number_of_azs  = var.number_of_azs
  common_tags    = local.common_tags
  additional_tags = var.additional_tags
}

# =============================================================================
# MODULE: SPOKES
# =============================================================================

module "spokes" {
  source = "./modules/spoke"
  
  for_each = local.spokes

  vpc_cidr                              = each.value.vpc_cidr
  environment                           = local.environment
  spoke_name                            = each.value.name
  project                              = local.project
  number_of_azs                        = var.number_of_azs
  transit_gateway_id                   = module.hub.transit_gateway_id
  transit_gateway_route_table_id       = module.hub.transit_gateway_route_table_id
  transit_gateway_attachment_dependencies = [module.hub.transit_gateway_attachment_id]
  common_tags                          = local.common_tags
  additional_tags                      = var.additional_tags
  aws_region                           = "us-east-1"
}

# =============================================================================
# ROUTING CONFIGURATION
# =============================================================================

# =============================================================================
# TRANSIT GATEWAY ROUTING
# =============================================================================

# Rota Padrão no TGW para Internet via Hub
# Isso permite que os spokes acessem a internet através do NAT Gateway do Hub
resource "aws_ec2_transit_gateway_route" "default_to_hub" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.hub.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.hub.transit_gateway_route_table_id
}

# =============================================================================
# HUB VPC ROUTING
# =============================================================================

# Rota da route table pública do Hub para os spokes via TGW
resource "aws_route" "hub_public_to_spokes" {
  for_each = local.spokes

  route_table_id         = module.hub.public_route_table_id
  destination_cidr_block = each.value.vpc_cidr
  transit_gateway_id     = module.hub.transit_gateway_id

  depends_on = [module.hub.transit_gateway_attachment_id]
}

# Rota das route tables privadas do Hub para os spokes via TGW
resource "aws_route" "hub_private_to_spokes" {
  for_each = {
    for pair in flatten([
      for i, rt_id in module.hub.private_route_table_ids : [
        for j, spoke in values(local.spokes) : {
          rt_id      = rt_id
          spoke_cidr = spoke.vpc_cidr
          key        = "${i}-${j}"
        }
      ]
    ]) : pair.key => pair
  }

  route_table_id         = each.value.rt_id
  destination_cidr_block = each.value.spoke_cidr
  transit_gateway_id     = module.hub.transit_gateway_id

  depends_on = [module.hub.transit_gateway_attachment_id]
}

# =============================================================================
# SPOKE VPCs ROUTING
# =============================================================================

# Rota das route tables privadas dos spokes para a internet via TGW
resource "aws_route" "spokes_to_internet" {
  for_each = local.spokes

  route_table_id         = module.spokes[each.key].private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.hub.transit_gateway_id

  depends_on = [module.hub.transit_gateway_attachment_id]
}

# Rota das route tables privadas dos spokes para o Hub via TGW
resource "aws_route" "spokes_to_hub" {
  for_each = local.spokes

  route_table_id         = module.spokes[each.key].private_route_table_id
  destination_cidr_block = module.hub.vpc_cidr
  transit_gateway_id     = module.hub.transit_gateway_id

  depends_on = [module.hub.transit_gateway_attachment_id]
}

# =============================================================================
# MODULE: FLOW LOGS
# =============================================================================

module "hub_flow_logs" {
  source = "./modules/vpc-flow-logs"

  vpc_id         = module.hub.vpc_id
  log_group_name = "/aws/vpc-flow-logs/${local.project}-hub"
  common_tags    = local.common_tags
}

module "spokes_flow_logs" {
  source   = "./modules/vpc-flow-logs"
  for_each = local.spokes

  vpc_id         = module.spokes[each.key].vpc_id
  log_group_name = "/aws/vpc-flow-logs/${local.project}-${each.key}"
  common_tags    = local.common_tags
} # Trigger pipeline
