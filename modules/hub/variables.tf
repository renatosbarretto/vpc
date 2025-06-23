# =============================================================================
# VARIABLES - HUB MODULE
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the Hub VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "vpc-hub-spoke"
}

variable "number_of_azs" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2
  validation {
    condition     = var.number_of_azs >= 1 && var.number_of_azs <= 4
    error_message = "Number of AZs must be between 1 and 4."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
} 