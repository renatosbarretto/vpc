# =============================================================================
# EC2 INSTANCES FOR TESTING
# =============================================================================

module "ec2_hub" {
  source = "./modules/ec2-instance"

  instance_name      = "hub-test-instance"
  vpc_id             = module.hub.vpc_id
  subnet_id          = module.hub.private_subnet_ids[0]
  allowed_icmp_cidrs = [module.hub.vpc_cidr, module.spokes["dev"].vpc_cidr]
  common_tags        = local.common_tags
}

module "ec2_spoke_dev" {
  source = "./modules/ec2-instance"

  instance_name      = "dev-test-instance"
  vpc_id             = module.spokes["dev"].vpc_id
  subnet_id          = module.spokes["dev"].private_subnet_ids[0]
  allowed_icmp_cidrs = [module.hub.vpc_cidr, module.spokes["dev"].vpc_cidr]
  common_tags        = local.common_tags
} 