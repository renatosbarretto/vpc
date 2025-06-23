# =============================================================================
# VARIABLES - SPOKE MODULE
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the Spoke VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "spoke_name" {
  description = "Name of the spoke (e.g., dev, staging, prod, app1, app2)"
  type        = string
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

variable "transit_gateway_id" {
  description = "ID of the Transit Gateway to attach to"
  type        = string
}

variable "transit_gateway_attachment_dependencies" {
  description = "Dependencies for Transit Gateway attachment (used for depends_on)"
  type        = any
  default     = []
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

variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
} 