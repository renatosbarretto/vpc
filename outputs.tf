# =============================================================================
# OUTPUTS - MAIN CONFIGURATION
# =============================================================================

# =============================================================================
# HUB OUTPUTS
# =============================================================================

output "hub_vpc_id" {
  description = "ID of the Hub VPC"
  value       = module.hub.vpc_id
}

output "hub_vpc_cidr" {
  description = "CIDR block of the Hub VPC"
  value       = module.hub.vpc_cidr
}

output "hub_public_subnet_ids" {
  description = "IDs of the public subnets in the Hub VPC"
  value       = module.hub.public_subnet_ids
}

output "hub_private_subnet_ids" {
  description = "IDs of the private subnets in the Hub VPC"
  value       = module.hub.private_subnet_ids
}

output "hub_public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets in the Hub VPC"
  value       = module.hub.public_subnet_cidrs
}

output "hub_private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets in the Hub VPC"
  value       = module.hub.private_subnet_cidrs
}

output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = module.hub.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = module.hub.transit_gateway_arn
}

output "hub_transit_gateway_attachment_id" {
  description = "ID of the Transit Gateway VPC attachment for the Hub"
  value       = module.hub.transit_gateway_attachment_id
}

output "hub_internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.hub.internet_gateway_id
}

output "hub_nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.hub.nat_gateway_ids
}

output "hub_nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = module.hub.nat_gateway_public_ips
}

# =============================================================================
# SPOKES OUTPUTS
# =============================================================================

output "spokes" {
  description = "Information about all created spokes"
  value = {
    for k, v in module.spokes : k => {
      vpc_id                           = v.vpc_id
      vpc_cidr                         = v.vpc_cidr
      private_subnet_ids               = v.private_subnet_ids
      private_subnet_cidrs             = v.private_subnet_cidrs
      transit_gateway_attachment_id    = v.transit_gateway_attachment_id
      private_route_table_id           = v.private_route_table_id
      availability_zones               = v.availability_zones
    }
  }
}

output "spoke_vpc_ids" {
  description = "IDs of all Spoke VPCs"
  value = {
    for k, v in module.spokes : k => v.vpc_id
  }
}

output "spoke_transit_gateway_attachment_ids" {
  description = "IDs of all Transit Gateway VPC attachments for Spokes"
  value = {
    for k, v in module.spokes : k => v.transit_gateway_attachment_id
  }
}

# =============================================================================
# NETWORKING SUMMARY
# =============================================================================

output "network_summary" {
  description = "Summary of the entire network architecture"
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
    }
    transit_gateway = {
      id  = module.hub.transit_gateway_id
      attachments = length(module.spokes) + 1 # +1 for hub attachment
    }
  }
}

# =============================================================================
# EC2 INSTANCE OUTPUTS
# =============================================================================

output "hub_instance_private_ip" {
  description = "Private IP of the Hub test instance"
  value       = module.ec2_hub.private_ip
}

output "spoke_dev_instance_private_ip" {
  description = "Private IP of the Spoke Dev test instance"
  value       = module.ec2_spoke_dev.private_ip
} 