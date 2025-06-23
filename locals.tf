# =============================================================================
# LOCALS
# =============================================================================

locals {
  environment = "dev"
  project     = "vpc-hub-spoke"
  
  # Tags padrão para todos os recursos
  common_tags = merge(var.common_tags, {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
  })

  # Configuração dos spokes
  spokes = {
    dev = {
      vpc_cidr = "10.1.0.0/16"
      name     = "dev"
    }
    # Adicione mais spokes conforme necessário
    # staging = {
    #   vpc_cidr = "10.2.0.0/16"
    #   name     = "staging"
    # }
    # prod = {
    #   vpc_cidr = "10.3.0.0/16"
    #   name     = "prod"
    # }
  }
} 